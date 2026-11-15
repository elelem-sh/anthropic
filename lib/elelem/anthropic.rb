# frozen_string_literal: true

require "elelem"
require "json"
require "net/http"
require "uri"

require_relative "anthropic/provider"
require_relative "anthropic/version"

Elelem.configure do |config|
  config.provider(:anthropic) do |model: nil, **|
    api_key = ENV.fetch("ANTHROPIC_API_KEY")
    Elelem::Anthropic::Provider.new(
      endpoint: "https://api.anthropic.com/v1/messages",
      headers: { "x-api-key" => api_key, "anthropic-version" => "2023-06-01" },
      model: model || ENV.fetch("ANTHROPIC_MODEL", "claude-sonnet-5-5")
    )
  end

  config.provider(:vertex) do |model: nil, **|
    model ||= ENV.fetch("VERTEX_MODEL", "claude-sonnet-5-5")
    project = ENV.fetch("GOOGLE_CLOUD_PROJECT")
    region = ENV.fetch("GOOGLE_CLOUD_REGION", "us-east5")
    Elelem::Anthropic::Provider.new(
      endpoint: "https://#{region}-aiplatform.googleapis.com/v1/projects/#{project}/locations/#{region}/publishers/anthropic/models/#{model}:rawPredict",
      headers: -> { { "Authorization" => "Bearer #{`gcloud auth application-default print-access-token`.strip}" } },
      model: model,
      version: "vertex-2023-10-16"
    )
  end
end
