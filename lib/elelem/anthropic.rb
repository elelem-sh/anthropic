# frozen_string_literal: true

require "elelem"
require "json"
require "net/http"
require "uri"

require_relative "anthropic/provider"
require_relative "anthropic/version"

Elelem.configure do |config|
  config.provider(:anthropic) do
    api_key = ENV.fetch("ANTHROPIC_API_KEY")
    Elelem::Anthropic::Provider.new(
      endpoint: "https://api.anthropic.com/v1/messages",
      headers: { "x-api-key" => api_key, "anthropic-version" => "2023-06-01" },
      model: ENV.fetch("ANTHROPIC_MODEL", "claude-opus-4-5-20250514")
    )
  end
end
