# frozen_string_literal: true

module Elelem
  module Anthropic
    # An access token from gcloud, kept for a few minutes because asking
    # gcloud takes about a second. gcloud renews a token well before it
    # expires, so one kept for 3 minutes stays valid.
    class GcloudToken
      COMMAND = %w[gcloud auth application-default print-access-token].freeze
      KEEP = 180

      def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
        @clock = clock
      end

      def call
        refresh if @token.nil? || @clock.call >= @expires
        @token
      end

      private

      def refresh
        output, status = Open3.capture2(*COMMAND)
        raise "#{COMMAND.join(" ")} failed; run gcloud auth application-default login" unless status.success?

        @token = output.strip
        @expires = @clock.call + KEEP
      end
    end
  end
end
