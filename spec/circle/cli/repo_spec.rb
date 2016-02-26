require 'spec_helper'
require 'circle/cli/repo'

module Circle::CLI
  RSpec.describe Repo do
    let(:options) { {} }
    let(:repo) { Repo.new(options) }
    let(:uri) { 'git@github.com:organization/repo.git' }

    let(:origin) {
      double('remote', name: 'origin', url: uri)
    }

    let(:git) {
      instance_double('Rugged::Repository', {
        config: {'circleci.token' => '123' },
        remotes: [origin]
      })
    }

    before do
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
        let(:head) { double('head', name: 'refs/heads/bug/jawn') }
        before { allow(git).to receive(:head).and_return(head) }
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
