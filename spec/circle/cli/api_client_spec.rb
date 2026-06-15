require 'spec_helper'
require 'circle/cli/api_client'
require 'circle/cli/api_error'

module Circle::CLI
  RSpec.describe ApiClient do
    let(:token)  { 'secret-token' }
    let(:client) { described_class.new(token: token) }
    let(:base)   { 'https://circleci.com/api/v2' }

    describe '#initialize' do
      it 'requires a non-empty token' do
        expect { described_class.new(token: nil) }.to raise_error(ArgumentError)
        expect { described_class.new(token: '') }.to raise_error(ArgumentError)
      end
    end

    describe '#get' do
      it 'sends the Circle-Token auth header' do
        stub = stub_request(:get, "#{base}/me")
               .with(headers: { 'Circle-Token' => token, 'Accept' => 'application/json' })
               .to_return(status: 200, body: '{}')
        client.get('/me')
        expect(stub).to have_been_requested
      end

      it 'parses and returns the JSON response body' do
        stub_request(:get, "#{base}/me")
          .to_return(status: 200, body: { 'login' => 'derek' }.to_json)
        expect(client.get('/me')).to eq('login' => 'derek')
      end

      it 'encodes query parameters' do
        stub = stub_request(:get, "#{base}/project/gh/o/r/pipeline")
               .with(query: { 'branch' => 'master' })
               .to_return(status: 200, body: '{}')
        client.get('/project/gh/o/r/pipeline', branch: 'master')
        expect(stub).to have_been_requested
      end
    end

    describe '#post' do
      it 'sends a JSON body with the correct content type' do
        stub = stub_request(:post, "#{base}/project/gh/o/r/pipeline")
               .with(
                 body: { 'branch' => 'master' }.to_json,
                 headers: { 'Content-Type' => 'application/json', 'Circle-Token' => token }
               )
               .to_return(status: 201, body: { 'id' => '123' }.to_json)
        expect(client.post('/project/gh/o/r/pipeline', branch: 'master')).to eq('id' => '123')
        expect(stub).to have_been_requested
      end
    end

    describe 'error handling' do
      it 'raises a formatted ApiError on a non-2xx response' do
        stub_request(:get, "#{base}/me")
          .to_return(status: 401, body: { 'message' => 'Unauthorized' }.to_json)
        expect { client.get('/me') }
          .to raise_error(ApiError, /HTTP 401.*Unauthorized/)
      end

      it 'never leaks the token in a raised error' do
        stub_request(:get, "#{base}/me")
          .to_return(status: 500, body: "boom #{token}")
        expect { client.get('/me') }
          .to raise_error(ApiError) { |e| expect(e.message).not_to include(token) }
      end
    end

    describe '#get_paged' do
      it 'follows next_page_token and aggregates the items arrays' do
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .to_return(status: 200, body: { 'items' => [{ 'id' => 1 }], 'next_page_token' => 'abc' }.to_json)
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .with(query: { 'page-token' => 'abc' })
          .to_return(status: 200, body: { 'items' => [{ 'id' => 2 }], 'next_page_token' => nil }.to_json)

        items = client.get_paged('/project/gh/o/r/pipeline')
        expect(items.map { |i| i['id'] }).to eq([1, 2])
      end

      it 'honors the max_pages cap' do
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .to_return(status: 200, body: { 'items' => [{ 'id' => 1 }], 'next_page_token' => 'abc' }.to_json)
        items = client.get_paged('/project/gh/o/r/pipeline', {}, max_pages: 1)
        expect(items.length).to eq(1)
      end
    end
  end
end
