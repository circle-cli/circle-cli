require 'spec_helper'
require 'circle/cli/build'
require 'circle/cli/project'

module Circle::CLI
  RSpec.describe Build do
    let(:repo) {
      instance_double('Repo', {
        project: 'rb-array-sorting',
        user_name: 'mtchavez',
        branch_name: 'master',
        circle_token: '123'
      })
    }

    let(:project)   { Project.new(repo) }
    subject(:build) { Build.new(project, attrs) }
    let(:attrs)     { {} }

    describe '#finished?' do
      specify { is_expected.not_to be_finished }

      context 'when finished' do
        let(:attrs) { { 'outcome' => 'failed' }}
        specify { is_expected.to be_finished }
      end
    end

    describe '#failed?' do
      specify { is_expected.not_to be_failed }

      context 'when failed' do
        let(:attrs) { { 'outcome' => 'failed' } }
        specify { is_expected.to be_failed }
      end
    end

    describe '#status' do
      let(:attrs) { { 'status' => 'not_running' } }
      specify { expect(build.status).to eq('Not running') }
    end

    describe '#subject' do
      let(:attrs) { { 'subject' => ('s' * 52) }}
      specify { expect(build.subject.length).to eq(50) }
    end

    describe '#color' do
      let(:attrs) { { 'status' => 'failed' } }
      specify { expect(build.color).to eq(:red) }
    end

    describe '#formatted_start_time' do
      context 'when blank' do
        specify { expect(build.formatted_start_time).to eq('Not started') }
      end
    end

    describe '#formatted_stop_time' do
      context 'when blank' do
        specify { expect(build.formatted_stop_time).to eq('Not finished') }
      end
    end

    describe '#tests', vcr: { cassette_name: 'tests' } do
      let(:build) { Build.new(project, 'build_num' => 5) }

      it 'returns a list of tests' do
        expect(build.tests.length).to eq(39)
      end

      it 'caches the test results' do
        expect(project).to receive(:request).once.and_call_original
        build.tests
        build.tests
      end
    end

    describe '#passing_tests', vcr: { cassette_name: 'tests' } do
      let(:build) { Build.new(project, 'build_num' => 5) }

      it 'returns only passing specs' do
        expect(build.passing_tests.length).to eq(39)
      end
    end

    describe '#failing_tests', vcr: { cassette_name: 'tests' } do
      let(:build) { Build.new(project, 'build_num' => 5) }

      it 'returns only failing specs' do
        expect(build.failing_tests.length).to eq(0)
      end
    end

    describe '#details', vcr: { cassette_name: 'get' } do
      let(:build) { Build.new(project, 'build_num' => 5) }

      it 'caches the response' do
        expect(project).to receive(:request).once.and_call_original
        build.details
        build.details
      end
    end
  end
end
