# frozen_string_literal: true

module Elelem
  module Anthropic
    class Documents
      def initialize(paths)
        @paths = paths.map(&:strip).select { |path| File.file?(path) }
      end

      def to_s
        ["<documents>", *@paths.each_with_index.map { |path, i| document(path, i + 1) }, "</documents>", ""].join("\n")
      end

      private

      def document(path, index)
        %(<document index="#{index}"><source>#{path.encode(xml: :text)}</source>) +
          %(<document_content>#{cdata(File.read(path))}</document_content></document>)
      end

      def cdata(text) = "<![CDATA[#{text.gsub("]]>", "]]]]><![CDATA[>")}]]>"
    end
  end
end
