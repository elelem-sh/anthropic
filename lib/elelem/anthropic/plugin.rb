# frozen_string_literal: true

require "elelem"
require_relative "../anthropic"

Elelem::Providers.register(:anthropic) do
  api_key = ENV.fetch("ANTHROPIC_API_KEY")
  Elelem::Anthropic::Client.new(
    endpoint: "https://api.anthropic.com/v1/messages",
    headers: { "x-api-key" => api_key, "anthropic-version" => "2023-06-01" },
    model: ENV.fetch("ANTHROPIC_MODEL", "claude-opus-4-5-20250514")
  )
end
