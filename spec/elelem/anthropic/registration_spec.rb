# frozen_string_literal: true

RSpec.describe "the anthropic providers" do
  around do |example|
    saved = ENV.to_h.slice("ANTHROPIC_API_KEY", "ANTHROPIC_MODEL", "VERTEX_MODEL", "GOOGLE_CLOUD_PROJECT")
    ENV["ANTHROPIC_MODEL"] = nil
    ENV.update("ANTHROPIC_API_KEY" => "sk-test", "GOOGLE_CLOUD_PROJECT" => "p")
    ENV.delete("ANTHROPIC_MODEL")
    ENV.delete("VERTEX_MODEL")
    example.run
  ensure
    %w[ANTHROPIC_API_KEY ANTHROPIC_MODEL VERTEX_MODEL GOOGLE_CLOUD_PROJECT].each { |k| ENV.delete(k) }
    ENV.update(saved)
  end

  def built(name, **)
    Elelem::Config.build_provider(name, **)
  end

  it "defaults to claude-sonnet-5-5" do
    expect(built("anthropic").instance_variable_get(:@model)).to eq("claude-sonnet-5-5")
    expect(built("vertex").instance_variable_get(:@uri).path).to include("/models/claude-sonnet-5-5:")
  end

  it "treats an empty model as unset, and an empty key as missing" do
    ENV["ANTHROPIC_MODEL"] = ""
    expect(built("anthropic").instance_variable_get(:@model)).to eq("claude-sonnet-5-5")

    ENV["ANTHROPIC_API_KEY"] = " "
    expect { built("anthropic") }.to raise_error(KeyError, /ANTHROPIC_API_KEY/)
  end

  it "uses --model when given" do
    expect(built("anthropic", model: "claude-opus-5-5").instance_variable_get(:@model)).to eq("claude-opus-5-5")
  end

  it "streams from Vertex on streamRawPredict" do
    expect(built("vertex").instance_variable_get(:@uri).path).to end_with(":streamRawPredict")
  end

  # -p NAME requires "elelem/NAME", so elelem/vertex has to exist on the load path.
  it "can be required as elelem/vertex" do
    expect($LOAD_PATH.resolve_feature_path("elelem/vertex")&.last).to end_with("lib/elelem/vertex.rb")
  end
end
