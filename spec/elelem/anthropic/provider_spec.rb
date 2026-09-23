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

      expect(body).to eq(max_tokens: 64_000, messages:, stream: true, model: "claude-opus-4-5-20250514")
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

      expect(body[:system]).to eq("be terse")
      expect(body[:messages]).to eq(messages)
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
