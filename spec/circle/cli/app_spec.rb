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
  end
end
