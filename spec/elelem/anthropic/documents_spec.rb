# frozen_string_literal: true

require "rexml/document"

RSpec.describe Elelem::Anthropic::Documents do
  around { |example| Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } } }

  def parse(paths) = REXML::Document.new(described_class.new(paths).to_s)

  it "keeps a file that contains ]]> intact" do
    File.write("a.txt", "x]]>y")

    expect(parse(["a.txt\n"]).elements["//document_content"].cdatas.map(&:value).join).to eq("x]]>y")
  end

  it "escapes the path" do
    File.write("a&b<c.txt", "1")

    expect(parse(["a&b<c.txt"]).elements["//source"].text).to eq("a&b<c.txt")
  end

  it "numbers only the files it found" do
    File.write("a.txt", "1")
    indexes = parse(["missing.txt", "", ".", "a.txt"]).get_elements("//document").map { |d| d.attributes["index"] }

    expect(indexes).to eq(["1"])
  end
end
