require 'spec_helper'
require 'circle/cli/project'

module Circle::CLI
  RSpec.describe Project do
    let(:repo) {
      instance_double('Repo', {
        project: 'rb-array-sorting',
        user_name: 'mtchavez',
        branch_name: 'master',
        circle_token: '123'
      })
    }

    let(:project) {
      Project.new(repo)
    }

    describe '#[]', vcr: { cassette_name: 'recent_builds_branch' } do
      subject { project['status'] }
      specify { is_expected.to eq('no_tests') }
    end

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
      specify { is_expected.to eq('no_tests') }
    end

    describe '#test_results_for', vcr: { cassette_name: 'tests' } do
      it 'returns a tests object' do
        results = project.test_results_for('build_num' => 5)
        expect(results).to be_a(Project::Tests)
      end

      it 'caches the test results' do
        expect(project).to receive(:request).once.and_call_original
        project.test_results_for('build_num' => 5)
        project.test_results_for('build_num' => 5)
        project.test_results_for('build_num' => 5)
      end
    end

    describe '#details_for', vcr: { cassette_name: 'get' } do
      it 'caches the response' do
        expect(project).to receive(:request).once.and_call_original
        project.details_for('build_num' => 5)
        project.details_for('build_num' => 5)
        project.details_for('build_num' => 5)
      end
    end

    describe Project::Tests do
      let(:failing) { { 'result' => 'failure' } }
      let(:passing) { { 'result' => 'success' } }
      let(:tests) { Project::Tests.new([failing, passing]) }

      describe '#passing' do
        subject { tests.passing[0]['result'] }
        specify { is_expected.to eq('success') }
      end

      describe '#failing' do
        subject { tests.failing[0]['result'] }
        specify { is_expected.to eq('failure') }
      end
    end
  end
end
