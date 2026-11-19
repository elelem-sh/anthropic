# frozen_string_literal: true

module Elelem
  module Anthropic
    class Provider
      THINKING = {
        "adaptive" => { type: "adaptive" },
        "summarized" => { type: "adaptive", display: "summarized" }
      }.freeze

      # thinking and effort are sent only when set: models before 4.6 reject
      # adaptive thinking, and the API picks a default effort per model.
      EFFORTS = %w[low medium high xhigh max].freeze

      # Each step of a turn resends the whole conversation. The marker on the
      # system prompt caches it and the tools for every turn; the top-level
      # marker caches the conversation so far, so each step pays only for
      # what is new.
      CACHE = { type: "ephemeral" }.freeze

      # An empty variable counts as unset.
      def self.options_from(env)
        value = ->(name) { env[name].to_s.strip.then { |v| v.empty? ? nil : v } }
        thinking = choose("ANTHROPIC_THINKING", value.call("ANTHROPIC_THINKING"), THINKING.keys)
        effort = choose("ANTHROPIC_EFFORT", value.call("ANTHROPIC_EFFORT"), EFFORTS)

        { max_tokens: Integer(value.call("ANTHROPIC_MAX_TOKENS") || "64000"), thinking: THINKING[thinking], effort: }
      end

      def self.choose(name, given, allowed)
        return given if given.nil? || allowed.include?(given)

        raise "#{name} must be #{allowed.join(", ")}; not #{given.inspect}"
      end

      def initialize(endpoint:, headers:, model:, version: nil, read_timeout: 3600, open_timeout: 10, http: nil,
                     max_tokens: 64_000, thinking: nil, effort: nil)
        @max_tokens = max_tokens
        @thinking = thinking
        @effort = effort
        @uri = URI.parse(endpoint)
        @headers_source = headers
        @model = model
        @version = version
        @read_timeout = read_timeout
        @open_timeout = open_timeout
        @http = http
      end

      def fetch(messages, tools = [], &)
        system_prompt, normalized_messages = extract_system(messages)
        tool_calls = []

        stream(normalized_messages, system_prompt, tools) do |event|
          handle_event(event, tool_calls, &)
        end

        finalize_tool_calls(tool_calls, &)
      end

      private

      def headers
        @headers_source.respond_to?(:call) ? @headers_source.call : @headers_source
      end

      def handle_event(event, tool_calls, &)
        case event["type"]
        when "content_block_start"
          handle_content_block_start(event, tool_calls)
        when "content_block_delta"
          handle_content_block_delta(event, tool_calls, &)
        when "message_start"
          log_usage(event.dig("message", "usage"))
        when "message_delta"
          log_usage(event["usage"])
          stopped(event.dig("delta", "stop_reason"))
        when "error"
          # e.g. overloaded_error mid-stream. Without this the reply is silently empty.
          raise "#{event.dig("error", "type")}: #{event.dig("error", "message")}"
        end
      end

      # Raises before a cut-off tool call is parsed.
      def stopped(reason)
        case reason
        when "max_tokens" then raise "the reply hit max_tokens (#{@max_tokens}); raise ANTHROPIC_MAX_TOKENS"
        when "refusal" then raise "the model declined to answer"
        end
      end

      # cache_read_input_tokens shows whether prompt caching works.
      def log_usage(usage)
        Elelem.logger.debug("anthropic: usage #{JSON.generate(usage)}") if usage
      end

      def handle_content_block_start(event, tool_calls)
        content_block = event["content_block"]
        return unless content_block["type"] == "tool_use"

        tool_calls << {
          id: content_block["id"],
          name: content_block["name"],
          args: String.new
        }
      end

      def handle_content_block_delta(event, tool_calls, &block)
        delta = event["delta"]

        case delta["type"]
        when "text_delta"
          block.call(type: "saying", text: delta["text"])
        when "thinking_delta"
          block.call(type: "thinking", text: delta["thinking"])
        when "input_json_delta"
          tool_calls.last[:args] << delta["partial_json"].to_s if tool_calls.any?
        end
      end

      def finalize_tool_calls(tool_calls, &block)
        tool_calls.each do |tool_call|
          args = tool_call.delete(:args)
          tool_call[:arguments] = args.empty? ? {} : JSON.parse(args)
          block.call(type: "doing", id: tool_call[:id], name: tool_call[:name], arguments: tool_call[:arguments])
        end
        tool_calls
      end

      def stream(messages, system_prompt, tools)
        body = build_request_body(messages, system_prompt, tools)

        http.post(@uri, headers:, body:) do |response|
          Elelem::HTTP.events(response) { |data| yield JSON.parse(data) }
        end
      end

      def http
        @http ||= Elelem::HTTP.new(read_timeout: @read_timeout, open_timeout: @open_timeout)
      end

      def build_request_body(messages, system_prompt, tools)
        body = { max_tokens: @max_tokens, messages:, stream: true, cache_control: CACHE }
        body[:thinking] = @thinking if @thinking
        body[:output_config] = { effort: @effort } if @effort
        body[:model] = @model unless @version
        body[:anthropic_version] = @version if @version
        body[:system] = [{ type: "text", text: system_prompt, cache_control: CACHE }] if system_prompt
        body[:tools] = unwrap_tools(tools) unless tools.empty?
        body
      end

      def extract_system(messages)
        system_messages, other_messages = messages.partition { |message| message[:role] == "system" }
        system_content = system_messages.first&.dig(:content)
        [system_content, normalize(other_messages)]
      end

      def normalize(messages)
        messages.map { |message| normalize_message(message) }
      end

      def normalize_message(message)
        case message[:role]
        when "tool"
          tool_result_message(message)
        when "assistant"
          message[:tool_calls]&.any? ? assistant_with_tools_message(message) : message
        else
          message
        end
      end

      def tool_result_message(message)
        {
          role: "user",
          content: [{
            type: "tool_result",
            tool_use_id: message[:tool_call_id],
            content: message[:content]
          }]
        }
      end

      def assistant_with_tools_message(message)
        text_content = build_text_content(message[:content])
        tool_content = build_tool_content(message[:tool_calls])

        { role: "assistant", content: text_content + tool_content }
      end

      def build_text_content(content)
        return [] if content.to_s.empty?

        [{ type: "text", text: content }]
      end

      def build_tool_content(tool_calls)
        tool_calls.map do |tool_call|
          {
            type: "tool_use",
            id: tool_call[:id],
            name: tool_call[:name],
            input: tool_call[:arguments]
          }
        end
      end

      def unwrap_tools(tools)
        tools.map do |tool|
          {
            name: tool.dig(:function, :name),
            description: tool.dig(:function, :description),
            input_schema: tool.dig(:function, :parameters)
          }
        end
      end
    end
  end
end
