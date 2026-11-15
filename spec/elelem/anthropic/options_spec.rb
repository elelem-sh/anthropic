# frozen_string_literal: true

RSpec.describe Elelem::Anthropic::Provider, ".options_from" do
  it "sends neither thinking nor effort by default" do
    expect(described_class.options_from({})).to eq(max_tokens: 64_000, thinking: nil, effort: nil)
  end

  it "reads ANTHROPIC_MAX_TOKENS, ANTHROPIC_THINKING and ANTHROPIC_EFFORT" do
    env = { "ANTHROPIC_MAX_TOKENS" => "8000", "ANTHROPIC_THINKING" => "summarized", "ANTHROPIC_EFFORT" => "high" }

    expect(described_class.options_from(env))
      .to eq(max_tokens: 8000, thinking: { type: "adaptive", display: "summarized" }, effort: "high")
  end

  it "refuses an unknown thinking value" do
    expect { described_class.options_from("ANTHROPIC_THINKING" => "on") }
      .to raise_error(/must be adaptive, summarized/)
  end

  it "treats empty values as unset" do
    env = { "ANTHROPIC_MAX_TOKENS" => "", "ANTHROPIC_THINKING" => "", "ANTHROPIC_EFFORT" => " " }

    expect(described_class.options_from(env)).to eq(max_tokens: 64_000, thinking: nil, effort: nil)
  end

  it "refuses an unknown effort" do
    expect { described_class.options_from("ANTHROPIC_EFFORT" => "extreme") }.to raise_error(/must be low, medium/)
  end
end
