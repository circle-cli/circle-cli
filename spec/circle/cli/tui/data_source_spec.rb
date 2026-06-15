require 'spec_helper'
require 'circle/cli/tui/data_source'

module Circle::CLI
  module TUI
    RSpec.describe DataSource do
      describe '.for' do
        it 'returns a sample source when sample: true' do
          source = described_class.for(sample: true)
          data = source.dashboard
          expect(data[:pipelines]).not_to be_empty
        end

        it 'returns a live source otherwise' do
          source = described_class.for(sample: false, api: double, project_slug: 'gh/o/r')
          expect(source).to be_a(LiveDataSource)
        end
      end

      describe LiveDataSource do
        let(:api) { instance_double('Circle::CLI::ApiClient') }
        let(:source) do
          described_class.new(api: api, project_slug: 'gh/o/r', branch: 'main')
        end

        it 'maps pipelines -> workflows -> jobs into the renderer shape' do
          allow(api).to receive(:project_pipelines)
            .with('gh/o/r', { branch: 'main' }, max_pages: 1)
            .and_return([
              {
                'id' => 'p1', 'number' => 42, 'created_at' => '2026-06-14T18:00:00Z',
                'vcs' => { 'revision' => 'abc123', 'commit' => { 'subject' => 'Add feature' } },
                'trigger' => { 'actor' => { 'login' => 'derek', 'name' => 'Derek Keith' } }
              }
            ])
          allow(api).to receive(:pipeline_workflows).with('p1')
            .and_return([{ 'id' => 'w1', 'name' => 'build-test', 'status' => 'success' }])
          allow(api).to receive(:workflow_jobs).with('w1')
            .and_return([
              {
                'name' => 'rspec', 'status' => 'success', 'job_number' => 9,
                'started_at' => '2026-06-14T18:00:00Z', 'stopped_at' => '2026-06-14T18:00:45Z'
              }
            ])

          data = source.dashboard
          expect(data[:project]).to eq('gh/o/r')
          expect(data[:branch]).to eq('main')
          pipeline = data[:pipelines].first
          expect(pipeline[:number]).to eq(42)
          expect(pipeline[:vcs][:subject]).to eq('Add feature')
          expect(pipeline[:vcs][:author]).to eq('Derek Keith')
          workflow = pipeline[:workflows].first
          expect(workflow[:name]).to eq('build-test')
          job = workflow[:jobs].first
          expect(job[:name]).to eq('rspec')
          expect(job[:duration_ms]).to eq(45_000)
        end

        it 'leaves job duration nil when timestamps are incomplete' do
          allow(api).to receive(:project_pipelines).and_return([{ 'id' => 'p1' }])
          allow(api).to receive(:pipeline_workflows)
            .and_return([{ 'id' => 'w1', 'name' => 'w', 'status' => 'running' }])
          allow(api).to receive(:workflow_jobs)
            .and_return([{ 'name' => 'build', 'status' => 'running', 'started_at' => '2026-06-14T18:00:00Z' }])

          job = source.dashboard[:pipelines].first[:workflows].first[:jobs].first
          expect(job[:duration_ms]).to be_nil
        end

        it 'reports a fallback notice when there are no pipelines' do
          allow(api).to receive(:project_pipelines).and_return([])
          data = source.dashboard
          expect(data[:pipelines]).to be_empty
          expect(data[:notice]).to match(/no recent pipelines/i)
        end

        it 'reports a fallback notice when pipelines have no workflows' do
          allow(api).to receive(:project_pipelines).and_return([{ 'id' => 'p1' }])
          allow(api).to receive(:pipeline_workflows).and_return([])
          expect(source.dashboard[:notice]).to match(/no workflows/i)
        end

        it 'reports a fallback notice when workflows have no jobs' do
          allow(api).to receive(:project_pipelines).and_return([{ 'id' => 'p1' }])
          allow(api).to receive(:pipeline_workflows)
            .and_return([{ 'id' => 'w1', 'name' => 'w', 'status' => 'running' }])
          allow(api).to receive(:workflow_jobs).and_return([])
          expect(source.dashboard[:notice]).to match(/no jobs/i)
        end
      end
    end
  end
end
