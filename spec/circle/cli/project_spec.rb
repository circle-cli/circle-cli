require 'spec_helper'
require 'circle/cli/project'
require 'circle/cli/repo'

module Circle::CLI
  RSpec.describe Project do
    let(:repo) {
      instance_double Repo, {
        project: 'circleci',
        user_name: 'mtchavez',
        branch_name: 'master',
        circle_token: '123'
      }
    }

    let(:project) {
      Project.new(repo)
    }

    describe '#builds', vcr: { cassette_name: 'recent_builds_branch' } do
      subject { project.builds }
      specify { is_expected.not_to be_empty }
    end

    describe '#recent_builds', vcr: { cassette_name: 'recent_builds' } do
      subject { project.recent_builds }
      specify { is_expected.not_to be_empty }
    end

    describe '#latest', vcr: { cassette_name: 'recent_builds_branch' } do
      subject { project.latest['status'] }
      specify { is_expected.to eq('success') }
    end
  end
end
