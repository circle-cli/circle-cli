require 'spec_helper'
require 'circle/cli/app'

module Circle::CLI
  RSpec.describe App do
    let(:options) { {} }
    let(:app)     { described_class.new([], options) }
    let(:repo) do
      instance_double Repo, circle_token: 'tok', project_slug: 'gh/o/r'
    end
    let(:base) { 'https://circleci.com/api/v2' }

    before { allow(app).to receive(:repo).and_return(repo) }

    describe '#me' do
      it 'prints the current user from the v2 API' do
        stub_request(:get, "#{base}/me")
          .with(headers: { 'Circle-Token' => 'tok' })
          .to_return(status: 200, body: { 'name' => 'Derek', 'id' => '42' }.to_json)
        expect { app.me }.to output(/Derek/).to_stdout
      end

      it 'aborts with a friendly message when no token is configured' do
        allow(repo).to receive(:circle_token).and_return(nil)
        expect { app.me }.to raise_error(SystemExit)
      end

      it 'aborts on an API error without leaking the token' do
        stub_request(:get, "#{base}/me")
          .to_return(status: 401, body: { 'message' => 'Unauthorized' }.to_json)
        expect { app.me }.to raise_error(SystemExit)
      end
    end

    describe '#pipelines' do
      it 'lists recent pipelines for the resolved project slug' do
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .to_return(
            status: 200,
            body: {
              'items' => [
                { 'number' => 7, 'vcs' => { 'branch' => 'master' },
                  'trigger' => { 'actor' => { 'login' => 'derek' } } }
              ],
              'next_page_token' => nil
            }.to_json
          )
        expect { app.pipelines }.to output(/master/).to_stdout
      end

      it 'aborts when there are no pipelines' do
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .to_return(status: 200, body: { 'items' => [], 'next_page_token' => nil }.to_json)
        expect { app.pipelines }.to raise_error(SystemExit)
      end
    end
  end
end
