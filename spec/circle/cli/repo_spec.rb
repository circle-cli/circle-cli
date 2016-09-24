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
    end

    describe '#circle_token=' do
      subject { repo.circle_token }
      before { repo.circle_token = '456' }
      specify { is_expected.to eq('456') }
    end
  end
end
