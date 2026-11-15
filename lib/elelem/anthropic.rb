# frozen_string_literal: true

require "elelem"
require "json"
require "net/http"
require "uri"

require_relative "anthropic/provider"
require_relative "anthropic/version"

module Elelem
  module Anthropic
    # An environment variable that is set but empty counts as unset.
    def self.env(name, default = nil)
      value = ENV[name].to_s.strip
      return value unless value.empty?
      return default unless default.nil?

      raise KeyError, "#{name} is not set"
    end
  end
end

Elelem.configure do |config|
  config.provider(:anthropic) do |model: nil, **|
    api_key = Elelem::Anthropic.env("ANTHROPIC_API_KEY")
    Elelem::Anthropic::Provider.new(
      endpoint: "https://api.anthropic.com/v1/messages",
      headers: { "x-api-key" => api_key, "anthropic-version" => "2023-06-01" },
      model: model || Elelem::Anthropic.env("ANTHROPIC_MODEL", "claude-sonnet-5-5"),
      **Elelem::Anthropic::Provider.options_from(ENV)
    )
  end

  config.provider(:vertex) do |model: nil, **|
    model ||= Elelem::Anthropic.env("VERTEX_MODEL", "claude-sonnet-5-5")
    project = Elelem::Anthropic.env("GOOGLE_CLOUD_PROJECT")
    region = Elelem::Anthropic.env("GOOGLE_CLOUD_REGION", "us-east5")
    Elelem::Anthropic::Provider.new(
      endpoint: "https://#{region}-aiplatform.googleapis.com/v1/projects/#{project}/locations/#{region}/publishers/anthropic/models/#{model}:streamRawPredict",
      headers: -> { { "Authorization" => "Bearer #{`gcloud auth application-default print-access-token`.strip}" } },
      model: model,
      version: "vertex-2023-10-16",
      **Elelem::Anthropic::Provider.options_from(ENV)
    )
  end
end
