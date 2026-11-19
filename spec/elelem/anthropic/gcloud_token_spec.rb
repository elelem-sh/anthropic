# frozen_string_literal: true

RSpec.describe Elelem::Anthropic::GcloudToken do
  subject(:token) { described_class.new(clock: -> { clock.first }) }

  let(:clock) { [0] }
  let(:ok) { instance_double(Process::Status, success?: true) }

  before { allow(Open3).to receive(:capture2).and_return(["first\n", ok], ["second\n", ok]) }

  it "asks gcloud once for a few minutes of requests" do
    expect(Array.new(3) { token.call }).to eq(%w[first first first])
    expect(Open3).to have_received(:capture2).once
  end

  it "asks again once the kept token is three minutes old" do
    token.call
    clock[0] = 179
    expect(token.call).to eq("first")

    clock[0] = 180
    expect(token.call).to eq("second")
  end

  it "fails when gcloud does instead of sending an empty token" do
    allow(Open3).to receive(:capture2).and_return(["", instance_double(Process::Status, success?: false)])

    expect { token.call }.to raise_error(/gcloud auth application-default login/)
  end
end
