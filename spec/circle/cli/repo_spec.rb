require 'spec_helper'
require 'circle/cli/repo'

module Circle::CLI
  RSpec.describe Repo do
    let(:options) { {} }
    let(:repo) { Repo.new(options) }
    let(:uri) { 'git@github.com:organization/repo.git' }
    let(:origin) { instance_double Git::Remote, url: uri }
    let(:git) { instance_double Git::Base, current_branch: 'bug/jawn' }
    let(:repo_config) { { 'circleci.token' => '123' } }

    before do
      allow(git).to receive(:config) do |name, value|
        repo_config[name] = value if value
        repo_config[name]
      end

      allow(git).to receive(:remote).and_return(origin)
      allow(repo).to receive(:repo).and_return(git)
    end

    # Token env vars take precedence over git config, so clear them for every
    # example and let individual specs set them explicitly.
    around do |example|
      saved = ENV.values_at('CIRCLE_TOKEN', 'CIRCLE_CLI_TOKEN')
      ENV.delete('CIRCLE_TOKEN')
      ENV.delete('CIRCLE_CLI_TOKEN')
      example.run
    ensure
      ENV['CIRCLE_TOKEN'], ENV['CIRCLE_CLI_TOKEN'] = saved
    end

    describe '#uri' do
      subject { repo.uri }
      specify { is_expected.to be_github }
    end

    describe '#user_name' do
      subject { repo.user_name }
      specify { is_expected.to eq('organization') }
    end

    describe '#project' do
      subject { repo.project }
      specify { is_expected.to eq('repo') }
    end

    describe '#branch_name' do
      subject { repo.branch_name }

      context 'when :branch is provided' do
        let(:options) { { 'branch' => 'option' } }
        specify { is_expected.to eq('option') }
      end

      context 'when :branch isnt provided' do
        specify { is_expected.to eq('bug/jawn') }
      end
    end

    describe '#circle_token' do
      subject { repo.circle_token }
      specify { is_expected.to eq('123') }

      context 'when git config has no token' do
        before do
          allow(git).to receive(:config).with('circleci.token').and_raise(Git::FailedError.allocate)
        end

        specify { is_expected.to be_nil }
      end

      context 'precedence' do
        before do
          ENV['CIRCLE_TOKEN'] = 'env-primary'
          ENV['CIRCLE_CLI_TOKEN'] = 'env-secondary'
        end

        specify 'CIRCLE_TOKEN wins over everything' do
          is_expected.to eq('env-primary')
        end

        context 'when CIRCLE_TOKEN is absent' do
          before { ENV.delete('CIRCLE_TOKEN') }
          specify 'CIRCLE_CLI_TOKEN wins over git config' do
            is_expected.to eq('env-secondary')
          end
        end
      end
    end

    describe '#circle_token_source' do
      subject { repo.circle_token_source }

      specify 'names the git config source' do
        is_expected.to match(/git config/)
      end

      context 'when the token comes from CIRCLE_TOKEN' do
        before { ENV['CIRCLE_TOKEN'] = 'env-primary' }
        specify { is_expected.to match(/CIRCLE_TOKEN/) }
      end

      context 'when no token is configured' do
        let(:repo_config) { {} }
        specify { is_expected.to be_nil }
      end
    end

    describe '#circle_token=' do
      subject { repo.circle_token }
      before { repo.circle_token = '456' }
      specify { is_expected.to eq('456') }
    end

    describe '#project_slug' do
      subject { repo.project_slug }

      around do |example|
        original = ENV['CIRCLE_CLI_PROJECT_SLUG']
        ENV.delete('CIRCLE_CLI_PROJECT_SLUG')
        example.run
        ENV['CIRCLE_CLI_PROJECT_SLUG'] = original
      end

      context 'with the CIRCLE_CLI_PROJECT_SLUG env override' do
        before { ENV['CIRCLE_CLI_PROJECT_SLUG'] = 'gh/env-org/env-repo' }
        specify { is_expected.to eq('gh/env-org/env-repo') }
      end

      context 'with a configured circleci.project-slug' do
        let(:repo_config) { { 'circleci.project-slug' => 'gh/cfg-org/cfg-repo' } }
        specify { is_expected.to eq('gh/cfg-org/cfg-repo') }
      end

      context 'falling back to inference from a github remote' do
        specify { is_expected.to eq('gh/organization/repo') }
      end

      context 'when git config has no project slug' do
        before do
          allow(git).to receive(:config).with('circleci.project-slug').and_raise(Git::FailedError.allocate)
        end

        specify { is_expected.to eq('gh/organization/repo') }
      end

      context 'falling back to inference from a bitbucket remote' do
        let(:uri) { 'git@bitbucket.org:organization/repo.git' }
        specify { is_expected.to eq('bb/organization/repo') }
      end
    end
  end
end
