require 'spec_helper'
require 'circle/cli/app'

module Circle::CLI
  RSpec.describe App, 'dashboard command' do
    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end

    it 'renders the bundled sample data without needing a repo or token' do
      out = capture_stdout { App.start(%w(dashboard --sample --no-color)) }
      expect(out).to include('circle-cli')
      expect(out).to include('Pipeline')
      expect(out).not_to match(/\e\[[0-9;]*m/) # --no-color stays script-safe
    end

    it 'is reachable through the `tui` alias' do
      out = capture_stdout { App.start(%w(tui --sample --no-color)) }
      expect(out).to include('circle-cli')
    end

    it 'exits with friendly guidance when live data is requested but unavailable' do
      allow_any_instance_of(App).to receive(:repo).and_raise(StandardError, 'no repo here')
      expect {
        capture_stdout { App.start(%w(dashboard)) }
      }.to raise_error(SystemExit)
    end

    describe 'live data source' do
      let(:base) { 'https://circleci.com/api/v2' }
      let(:app)  { App.new([], {}) }
      let(:repo) { instance_double(Repo, circle_token: 'tok', project_slug: 'gh/o/r') }

      before do
        allow(app).to receive(:repo).and_return(repo)
        allow(app).to receive(:options).and_return(color: false, unicode: false, width: 80)
      end

      it 'renders pipelines pulled from the v2 API' do
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .to_return(status: 200, body: {
            'items' => [{ 'id' => 'p1', 'number' => 5,
                          'vcs' => { 'revision' => 'abc', 'commit' => { 'subject' => 'Wire dashboard' } } }],
            'next_page_token' => nil
          }.to_json)
        stub_request(:get, "#{base}/pipeline/p1/workflow")
          .to_return(status: 200, body: {
            'items' => [{ 'id' => 'w1', 'name' => 'build-test', 'status' => 'success' }],
            'next_page_token' => nil
          }.to_json)
        stub_request(:get, "#{base}/workflow/w1/job")
          .to_return(status: 200, body: {
            'items' => [{ 'name' => 'rspec', 'status' => 'success' }],
            'next_page_token' => nil
          }.to_json)

        expect { app.dashboard }.to output(/Pipeline #5.*build-test.*rspec/m).to_stdout
      end

      it 'shows a fallback message when the project has no pipelines' do
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .to_return(status: 200, body: { 'items' => [], 'next_page_token' => nil }.to_json)
        expect { app.dashboard }.to output(/no recent pipelines/i).to_stdout
      end
    end
  end
end
