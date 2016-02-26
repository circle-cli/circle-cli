require 'circle/cli/report'

module Circle::CLI
  RSpec.describe Report do
    let(:repo) {
      instance_double('Repo', {
        project: 'rb-array-sorting',
        user_name: 'mtchavez',
        branch_name: 'master',
        circle_token: '123'
      })
    }

    let(:report) {
      Report.new(repo)
    }

    describe '#[]', vcr: { cassette_name: 'recent_builds_branch' } do
      subject { report['status'] }
      specify { is_expected.to eq('no_tests') }
    end

    describe '#builds', vcr: { cassette_name: 'recent_builds_branch' } do
      subject { report.builds }
      specify { is_expected.not_to be_empty }
    end

    describe '#recent_builds', vcr: { cassette_name: 'recent_builds' } do
      subject { report.recent_builds }
      specify { is_expected.not_to be_empty }
    end

    describe '#latest', vcr: { cassette_name: 'recent_builds_branch' } do
      subject { report.latest['status'] }
      specify { is_expected.to eq('no_tests') }
    end

    describe '#test_results_for', vcr: { cassette_name: 'tests' } do
      it 'returns a tests object' do
        results = report.test_results_for('build_num' => 5)
        expect(results).to be_a(Report::Tests)
      end

      it 'caches the test results' do
        expect(Report::Tests).to receive(:new).once.and_call_original
        report.test_results_for('build_num' => 5)
        report.test_results_for('build_num' => 5)
        report.test_results_for('build_num' => 5)
      end
    end

    describe Report::Tests do
      let(:failing) { { 'result' => 'failure' } }
      let(:passing) { { 'result' => 'success' } }
      let(:tests) { Report::Tests.new([failing, passing]) }

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
