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

    describe '#workflows' do
      it 'lists workflow name, status, id, and created time' do
        stub_request(:get, "#{base}/pipeline/p1/workflow")
          .to_return(
            status: 200,
            body: {
              'items' => [
                { 'id' => 'w1', 'name' => 'build-test', 'status' => 'success',
                  'created_at' => '2026-06-14T18:00:00Z' }
              ],
              'next_page_token' => nil
            }.to_json
          )
        expect { app.workflows('p1') }.to output(/build-test.*success.*w1/m).to_stdout
      end

      it 'aborts when there are no workflows' do
        stub_request(:get, "#{base}/pipeline/p1/workflow")
          .to_return(status: 200, body: { 'items' => [], 'next_page_token' => nil }.to_json)
        expect { app.workflows('p1') }.to raise_error(SystemExit)
      end
    end

    describe '#jobs' do
      it 'lists job name, status, number, id, and duration' do
        stub_request(:get, "#{base}/workflow/w1/job")
          .to_return(
            status: 200,
            body: {
              'items' => [
                { 'id' => 'j1', 'name' => 'rspec', 'status' => 'success', 'job_number' => 9,
                  'started_at' => '2026-06-14T18:00:00Z', 'stopped_at' => '2026-06-14T18:00:45Z' }
              ],
              'next_page_token' => nil
            }.to_json
          )
        expect { app.jobs('w1') }.to output(/rspec.*success.*45s/m).to_stdout
      end

      it 'shows a dash when a job has no duration yet' do
        stub_request(:get, "#{base}/workflow/w1/job")
          .to_return(
            status: 200,
            body: {
              'items' => [
                { 'id' => 'j1', 'name' => 'deploy', 'status' => 'running', 'job_number' => 10,
                  'started_at' => '2026-06-14T18:00:00Z' }
              ],
              'next_page_token' => nil
            }.to_json
          )
        expect { app.jobs('w1') }.to output(/deploy.*running/m).to_stdout
      end

      it 'aborts when there are no jobs' do
        stub_request(:get, "#{base}/workflow/w1/job")
          .to_return(status: 200, body: { 'items' => [], 'next_page_token' => nil }.to_json)
        expect { app.jobs('w1') }.to raise_error(SystemExit)
      end
    end
  end
end
