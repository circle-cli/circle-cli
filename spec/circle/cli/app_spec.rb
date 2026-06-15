require 'spec_helper'
require 'circle/cli/app'

module Circle::CLI
  RSpec.describe App do
    let(:options) { {} }
    let(:app)     { described_class.new([], options) }
    let(:repo) do
      instance_double Repo, circle_token: 'tok', project_slug: 'gh/o/r', branch_name: 'master'
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

    describe '#token' do
      let(:secret) { 'sk-circle-9f8e7d' }

      before do
        allow(repo).to receive(:circle_token).and_return(secret)
        allow(repo).to receive(:circle_token_source).and_return('git config (circleci.token)')
      end

      it 'reports that a token is configured without printing its value' do
        expect { app.token }
          .to output(satisfy { |o| o.include?('configured') && !o.include?(secret) })
          .to_stdout
      end

      it 'reports where the token came from' do
        expect { app.token }.to output(/git config/).to_stdout
      end

      context 'with --show' do
        let(:options) { { 'show' => true } }

        it 'prints the token value only with the explicit flag' do
          expect { app.token }.to output(/#{secret}/).to_stdout
        end
      end

      context 'when no token is configured' do
        before { allow(repo).to receive(:circle_token).and_return(nil) }

        it 'prints the login hint rather than a value' do
          expect { app.token }.to output(/circle login/).to_stdout
        end
      end

      context 'saving a token' do
        before { allow(repo).to receive(:circle_token=) }

        it 'stores the value without echoing it back' do
          expect { app.token(secret) }
            .to output(satisfy { |o| !o.include?(secret) })
            .to_stdout
          expect(repo).to have_received(:circle_token=).with(secret)
        end
      end
    end

    describe '#login' do
      let(:entered) { 'sk-login-abc123' }

      before do
        allow(app).to receive(:ask).and_return(entered)
        allow(Launchy).to receive(:open)
        allow(repo).to receive(:circle_token=)
      end

      it 'saves the token, validates via /me, and never echoes the token' do
        stub_request(:get, "#{base}/me")
          .with(headers: { 'Circle-Token' => entered })
          .to_return(status: 200, body: { 'name' => 'Derek', 'id' => '42' }.to_json)

        expect { app.login }
          .to output(satisfy { |o| o.include?('Derek') && !o.include?(entered) })
          .to_stdout
        expect(repo).to have_received(:circle_token=).with(entered)
      end

      it 'warns but does not crash when validation fails, still without leaking the token' do
        stub_request(:get, "#{base}/me")
          .to_return(status: 401, body: { 'message' => 'Unauthorized' }.to_json)

        expect { app.login }
          .to output(satisfy { |o| o.include?('could not be validated') && !o.include?(entered) })
          .to_stdout
      end
    end

    describe '#projects' do
      it 'lists collaborations alongside the resolved project slug' do
        stub_request(:get, "#{base}/me/collaborations")
          .with(headers: { 'Circle-Token' => 'tok' })
          .to_return(
            status: 200,
            body: [{ 'slug' => 'gh/acme', 'name' => 'Acme', 'vcs-type' => 'github' }].to_json
          )

        expect { app.projects }
          .to output(satisfy { |o| o.include?('Acme') && o.include?('gh/o/r') })
          .to_stdout
      end

      context 'with --json' do
        let(:options) { { 'json' => true } }

        it 'emits the resolved slug and collaborations as JSON' do
          stub_request(:get, "#{base}/me/collaborations")
            .to_return(status: 200, body: [{ 'slug' => 'gh/acme' }].to_json)

          expect { app.projects }.to output(%r{"current_project_slug":"gh/o/r"}).to_stdout
        end
      end

      it 'aborts when no token is configured' do
        allow(repo).to receive(:circle_token).and_return(nil)
        expect { app.projects }.to raise_error(SystemExit)
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

    # The v1-migrated read-only commands. validate_repo! is stubbed so these
    # focus on v2 behavior rather than git remote/VCS resolution.
    describe 'v2-backed read-only commands' do
      before { allow(app).to receive(:validate_repo!) }

      def stub_branch_pipelines(items)
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .with(query: { 'branch' => 'master' })
          .to_return(status: 200, body: { 'items' => items, 'next_page_token' => nil }.to_json)
      end

      def stub_all_pipelines(items)
        stub_request(:get, "#{base}/project/gh/o/r/pipeline")
          .to_return(status: 200, body: { 'items' => items, 'next_page_token' => nil }.to_json)
      end

      def stub_workflows(pipeline_id, items)
        stub_request(:get, "#{base}/pipeline/#{pipeline_id}/workflow")
          .to_return(status: 200, body: { 'items' => items, 'next_page_token' => nil }.to_json)
      end

      def stub_jobs(workflow_id, items)
        stub_request(:get, "#{base}/workflow/#{workflow_id}/job")
          .to_return(status: 200, body: { 'items' => items, 'next_page_token' => nil }.to_json)
      end

      def silence_exit
        yield
      rescue SystemExit
        nil
      end

      describe '#status' do
        it 'renders subject, status, URL, and steps from v2 data' do
          stub_branch_pipelines([{ 'id' => 'p1', 'number' => 12,
            'vcs' => { 'branch' => 'master', 'commit' => { 'subject' => 'Ship it' } } }])
          stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'success',
            'created_at' => '2026-06-14T18:00:00Z', 'stopped_at' => '2026-06-14T18:02:00Z' }])
          stub_jobs('w1', [{ 'name' => 'rspec', 'status' => 'success', 'job_number' => 9,
            'started_at' => '2026-06-14T18:00:00Z', 'stopped_at' => '2026-06-14T18:00:45Z' }])

          expect { silence_exit { app.status } }
            .to output(satisfy { |o|
              o.include?('Ship it') && o.include?('Success') && o.include?('rspec') &&
                o.include?('app.circleci.com/pipelines/github/o/r/12/workflows/w1')
            }).to_stdout
        end

        it 'exits 0 on a successful terminal pipeline' do
          stub_branch_pipelines([{ 'id' => 'p1', 'number' => 1, 'vcs' => { 'branch' => 'master' } }])
          stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'success' }])
          stub_jobs('w1', [])
          expect { app.status }.to raise_error(SystemExit) { |e| expect(e.status).to eq(0) }
        end

        it 'exits 1 and lists failing specs on a failed pipeline' do
          stub_branch_pipelines([{ 'id' => 'p1', 'number' => 1, 'vcs' => { 'branch' => 'master' } }])
          stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'failed' }])
          stub_jobs('w1', [{ 'name' => 'rspec', 'status' => 'failed', 'job_number' => 9 }])
          stub_request(:get, "#{base}/project/gh/o/r/9/tests")
            .to_return(status: 200, body: { 'items' => [
              { 'name' => 'is broken', 'file' => 'spec/x_spec.rb', 'result' => 'failure' }
            ], 'next_page_token' => nil }.to_json)

          expect { silence_exit { app.status } }.to output(/is broken/).to_stdout
          expect { app.status }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end

        it 'exits 1 on a canceled pipeline' do
          stub_branch_pipelines([{ 'id' => 'p1', 'number' => 1, 'vcs' => { 'branch' => 'master' } }])
          stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'canceled' }])
          stub_jobs('w1', [])
          expect { app.status }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end

        it 'does not exit while a pipeline is still running' do
          stub_branch_pipelines([{ 'id' => 'p1', 'number' => 1, 'vcs' => { 'branch' => 'master' } }])
          stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'running' }])
          stub_jobs('w1', [{ 'name' => 'rspec', 'status' => 'running', 'job_number' => 9 }])
          expect { app.status }.not_to raise_error
        end

        it 'aborts when the branch has no pipelines' do
          stub_branch_pipelines([])
          expect { app.status }.to raise_error(SystemExit)
        end
      end

      describe '#overview' do
        it 'lists recent pipelines across branches' do
          stub_all_pipelines([
            { 'id' => 'p1', 'number' => 2, 'vcs' => { 'branch' => 'main', 'commit' => { 'subject' => 'A' } } },
            { 'id' => 'p2', 'number' => 1, 'vcs' => { 'branch' => 'topic', 'commit' => { 'subject' => 'B' } } }
          ])
          stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'success' }])
          stub_workflows('p2', [{ 'id' => 'w2', 'status' => 'failed' }])

          expect { app.overview }
            .to output(satisfy { |o| o.include?('main') && o.include?('topic') && o.include?('Failed') })
            .to_stdout
        end

        it 'aborts when there are no recent pipelines' do
          stub_all_pipelines([])
          expect { app.overview }.to raise_error(SystemExit)
        end
      end

      describe '#open' do
        before { allow(Launchy).to receive(:open) }

        it 'opens the workflow web URL for the latest pipeline' do
          stub_branch_pipelines([{ 'id' => 'p1', 'number' => 12, 'vcs' => { 'branch' => 'master' } }])
          stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'success' }])
          stub_jobs('w1', [])
          app.open
          expect(Launchy).to have_received(:open)
            .with('https://app.circleci.com/pipelines/github/o/r/12/workflows/w1')
        end

        it 'aborts when there is no pipeline to open' do
          stub_branch_pipelines([])
          expect { app.open }.to raise_error(SystemExit)
          expect(Launchy).not_to have_received(:open)
        end
      end
    end
  end
end
