module Circle
  module CLI
    # Raised when a CircleCI API v2 request fails. Formats the CircleCI error
    # payload into a human-readable message and guarantees the auth token is
    # never echoed back through an exception.
    class ApiError < StandardError
      REDACTION = '[REDACTED]'.freeze

      attr_reader :status, :response_body

      def initialize(message, status: nil, response_body: nil, token: nil)
        @status = status
        @response_body = response_body
        text = status ? "CircleCI API error (HTTP #{status}): #{message}" : message.to_s
        super(redact(text, token))
      end

      private

      def redact(text, token)
        return text if token.nil? || token.empty?
        text.gsub(token, REDACTION)
      end
    end
  end
end
