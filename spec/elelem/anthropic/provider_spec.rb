# frozen_string_literal: true

RSpec.describe Elelem::Anthropic::Provider do
  subject(:provider) do
    described_class.new(
      endpoint: "https://api.anthropic.com/v1/messages", headers: {}, model: "claude-opus-4-5-20250514", http:, **params
    )
  end

  let(:params) { {} }
  let(:messages) { [{ role: "user", content: "hi" }] }
  let(:body) { http.body }

  let(:response) do
    Net::HTTPOK.new("1.1", "200", "OK").tap do |res|
      allow(res).to receive(:read_body).and_yield(sse(events))
    end
  end

  let(:events) { [{ "type" => "message_stop" }] }

  let(:http) do
    Class.new do
      attr_reader :body

      def initialize(response)
        @response = response
      end

      def post(_uri, body:, **)
        @body = body
        yield @response
      end
    end.new(response)
  end

  def sse(events)
    events.map { |event| "data: #{JSON.generate(event)}\n\n" }.join
  end

  describe "#fetch" do
    it "sends model and messages by default" do
      provider.fetch(messages, [])

      expect(body).to eq(max_tokens: 64_000, messages:, stream: true, cache_control: { type: "ephemeral" },
                         model: "claude-opus-4-5-20250514")
    end

    it "omits tools when empty" do
      provider.fetch(messages, [])

      expect(body).not_to have_key(:tools)
    end

    it "sends tools when present" do
      tools = [{ type: "function",
                 function: { name: "read", description: "reads a file", parameters: { type: "object" } } }]

      provider.fetch(messages, tools)

      expect(body[:tools]).to eq([{ name: "read", description: "reads a file", input_schema: { type: "object" } }])
    end

    it "extracts a system message out of messages" do
      provider.fetch([{ role: "system", content: "be terse" }, *messages], [])

      expect(body[:system]).to eq([{ type: "text", text: "be terse", cache_control: { type: "ephemeral" } }])
      expect(body[:messages]).to eq(messages)
    end

    it "leaves out an empty system prompt" do
      provider.fetch([{ role: "system", content: "" }, *messages], [])

      expect(body).not_to have_key(:system)
    end

    it "caches the system prompt and tools, and the conversation so far" do
      provider.fetch([{ role: "system", content: "be terse" }, *messages], [])

      expect(body[:cache_control]).to eq(type: "ephemeral")
      expect(body.dig(:system, 0, :cache_control)).to eq(type: "ephemeral")
    end

    it "reads events split by CRLF" do
      allow(response).to receive(:read_body)
        .and_yield(%(data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"hi"}}\r\n\r\n))
      seen = []

      provider.fetch(messages, []) { |event| seen << event }

      expect(seen).to eq([{ type: "saying", text: "hi" }])
    end

    context "with thinking, effort and max_tokens set" do
      let(:params) { { max_tokens: 8000, thinking: { type: "adaptive", display: "summarized" }, effort: "low" } }

      it "sends them" do
        provider.fetch(messages, [])

        expect(body).to include(max_tokens: 8000, thinking: { type: "adaptive", display: "summarized" },
                                output_config: { effort: "low" })
      end
    end

    context "with an error event mid-stream" do
      let(:events) do
        [{ "type" => "message_start" },
         { "type" => "error", "error" => { "type" => "overloaded_error", "message" => "Overloaded" } }]
      end

      it "raises instead of returning an empty reply" do
        expect { provider.fetch(messages, []) {} }.to raise_error("overloaded_error: Overloaded")
      end
    end

    context "with a tool call cut off at max_tokens" do
      let(:params) { { max_tokens: 100 } }
      let(:events) do
        [
          { "type" => "content_block_start",
            "content_block" => { "type" => "tool_use", "id" => "1", "name" => "write" } },
          { "type" => "content_block_delta",
            "delta" => { "type" => "input_json_delta", "partial_json" => '{"path":"a.rb","con' } },
          { "type" => "message_delta", "delta" => { "stop_reason" => "max_tokens" } }
        ]
      end

      it "says so instead of failing to parse half the arguments" do
        expect { provider.fetch(messages, []) {} }
          .to raise_error("the reply hit max_tokens (100); raise ANTHROPIC_MAX_TOKENS")
      end
    end

    context "with a conversation too long for the model" do
      let(:events) { [{ "type" => "message_delta", "delta" => { "stop_reason" => "model_context_window_exceeded" } }] }

      it "raises" do
        expect { provider.fetch(messages, []) {} }.to raise_error(/no longer fits the model's context window/)
      end
    end

    context "with a refusal" do
      let(:events) { [{ "type" => "message_delta", "delta" => { "stop_reason" => "refusal" } }] }

      it "raises" do
        expect { provider.fetch(messages, []) {} }.to raise_error("the model declined to answer")
      end
    end

    context "with usage" do
      let(:events) do
        [{ "type" => "message_start", "message" => { "usage" => { "cache_read_input_tokens" => 900 } } },
         { "type" => "message_delta", "delta" => { "stop_reason" => "end_turn" }, "usage" => { "output_tokens" => 5 } }]
      end

      it "logs it, to show whether the cache is read" do
        allow(Elelem.logger).to receive(:debug)

        provider.fetch(messages, []) {}

        expect(Elelem.logger).to have_received(:debug).with('anthropic: usage {"cache_read_input_tokens":900}')
        expect(Elelem.logger).to have_received(:debug).with('anthropic: usage {"output_tokens":5}')
      end
    end

    context "with text and thinking deltas" do
      let(:events) do
        [
          { "type" => "content_block_delta", "delta" => { "type" => "text_delta", "text" => "hi" } },
          { "type" => "content_block_delta", "delta" => { "type" => "thinking_delta", "thinking" => "hmm" } }
        ]
      end

      it "yields saying and thinking blocks" do
        seen = []

        provider.fetch(messages, []) { |event| seen << event }

        expect(seen).to eq([{ type: "saying", text: "hi" }, { type: "thinking", text: "hmm" }])
      end
    end

    context "with a streamed tool call" do
      let(:events) do
        [
          { "type" => "content_block_start",
            "content_block" => { "type" => "tool_use", "id" => "1", "name" => "read" } },
          { "type" => "content_block_delta",
            "delta" => { "type" => "input_json_delta", "partial_json" => '{"path":' } },
          { "type" => "content_block_delta", "delta" => { "type" => "input_json_delta", "partial_json" => '"a.rb"}' } }
        ]
      end

      it "accumulates partial json into parsed arguments" do
        result = provider.fetch(messages, []) {}

        expect(result).to eq([{ id: "1", name: "read", arguments: { "path" => "a.rb" } }])
      end

      it "yields a doing event once finalized" do
        seen = []

        provider.fetch(messages, []) { |event| seen << event }

        expect(seen).to eq([{ type: "doing", id: "1", name: "read", arguments: { "path" => "a.rb" } }])
      end
    end
  end
end
