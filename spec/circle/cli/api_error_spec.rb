require 'spec_helper'
require 'circle/cli/api_error'

module Circle::CLI
  RSpec.describe ApiError do
    describe 'message formatting' do
      it 'prefixes the status code when given' do
        error = described_class.new('Unauthorized', status: 401)
        expect(error.message).to eq('CircleCI API error (HTTP 401): Unauthorized')
      end

      it 'uses the bare message when no status is given' do
        error = described_class.new('Request failed: timeout')
        expect(error.message).to eq('Request failed: timeout')
      end

      it 'exposes the status and parsed response body' do
        body = { 'message' => 'Not Found' }
        error = described_class.new('Not Found', status: 404, response_body: body)
        expect(error.status).to eq(404)
        expect(error.response_body).to eq(body)
      end
    end

    describe 'token redaction' do
      it 'redacts the token anywhere it appears in the message' do
        error = described_class.new(
          'Failed for token=super-secret-token while calling /me',
          token: 'super-secret-token'
        )
        expect(error.message).not_to include('super-secret-token')
        expect(error.message).to include('[REDACTED]')
      end

      it 'is a no-op when no token is provided' do
        error = described_class.new('boom')
        expect(error.message).to eq('boom')
      end
    end
  end
end
