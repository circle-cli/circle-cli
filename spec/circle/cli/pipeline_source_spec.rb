require 'spec_helper'
require 'circle/cli/api_client'
require 'circle/cli/pipeline_source'

module Circle::CLI
  RSpec.describe PipelineSource do
    let(:base)   { 'https://circleci.com/api/v2' }
    let(:slug)   { 'gh/o/r' }
    let(:api)    { ApiClient.new(token: 'tok') }
    let(:source) { described_class.new(api: api, project_slug: slug, branch: 'master') }

    def stub_pipelines(items, query: {})
      stub = stub_request(:get, "#{base}/project/#{slug}/pipeline")
      stub = stub.with(query: query) unless query.empty?
      stub.to_return(status: 200, body: { 'items' => items, 'next_page_token' => nil }.to_json)
    end

    def stub_workflows(pipeline_id, items)
      stub_request(:get, "#{base}/pipeline/#{pipeline_id}/workflow")
        .to_return(status: 200, body: { 'items' => items, 'next_page_token' => nil }.to_json)
    end

    def stub_jobs(workflow_id, items)
      stub_request(:get, "#{base}/workflow/#{workflow_id}/job")
        .to_return(status: 200, body: { 'items' => items, 'next_page_token' => nil }.to_json)
    end

    describe '#latest' do
      it 'maps the newest branch pipeline + workflow into a build-like object' do
        stub_pipelines(
          [{ 'id' => 'p1', 'number' => 12,
             'vcs' => { 'branch' => 'master', 'commit' => { 'subject' => 'Fix things' } } }],
          query: { 'branch' => 'master' }
        )
        stub_workflows('p1', [{ 'id' => 'w1', 'name' => 'build', 'status' => 'success',
                                'created_at' => '2026-06-14T18:00:00Z',
                                'stopped_at' => '2026-06-14T18:02:00Z' }])
        stub_jobs('w1', [{ 'name' => 'rspec', 'status' => 'success', 'job_number' => 9,
                           'started_at' => '2026-06-14T18:00:00Z',
                           'stopped_at' => '2026-06-14T18:00:45Z' }])

        build = source.latest
        expect(build[:subject]).to eq('Fix things')
        expect(build.status).to eq('Success')
        expect(build).to be_finished
        expect(build).not_to be_failed
        expect(build[:build_url])
          .to eq('https://app.circleci.com/pipelines/github/o/r/12/workflows/w1')
        expect(build.steps.map { |s| s[:name] }).to eq(['rspec'])
        expect(build.steps.first.duration).to eq('45s')
      end

      it 'treats canceled workflows as failures' do
        stub_pipelines([{ 'id' => 'p1', 'number' => 1, 'vcs' => { 'branch' => 'master' } }],
                       query: { 'branch' => 'master' })
        stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'canceled' }])
        stub_jobs('w1', [])

        expect(source.latest).to be_failed
        expect(source.latest).to be_finished
      end

      it 'returns nil when the branch has no pipelines' do
        stub_pipelines([], query: { 'branch' => 'master' })
        expect(source.latest).to be_nil
      end

      it 'degrades to a pipeline URL when there are no workflows' do
        stub_pipelines([{ 'id' => 'p1', 'number' => 5, 'vcs' => { 'branch' => 'master' } }],
                       query: { 'branch' => 'master' })
        stub_workflows('p1', [])

        build = source.latest
        expect(build[:build_url]).to eq('https://app.circleci.com/pipelines/github/o/r/5')
        expect(build).not_to be_finished
        expect(build.steps).to be_empty
      end

      it 'caches the result, including a nil' do
        stub_pipelines([], query: { 'branch' => 'master' })
        source.latest
        source.latest
        expect(a_request(:get, "#{base}/project/#{slug}/pipeline")
          .with(query: { 'branch' => 'master' })).to have_been_made.once
      end
    end

    describe '#failing_tests' do
      it 'pulls failing specs from failed jobs only' do
        stub_request(:get, "#{base}/project/#{slug}/9/tests")
          .to_return(status: 200, body: {
            'items' => [
              { 'name' => 'is red', 'file' => 'spec/a_spec.rb', 'result' => 'failure' },
              { 'name' => 'is green', 'file' => 'spec/b_spec.rb', 'result' => 'success' }
            ], 'next_page_token' => nil
          }.to_json)

        jobs = [
          { 'status' => 'failed',  'job_number' => 9 },
          { 'status' => 'success', 'job_number' => 10 }
        ]
        failures = source.failing_tests(jobs)
        expect(failures).to eq([{ 'file' => 'spec/a_spec.rb', 'name' => 'is red' }])
      end

      it 'degrades to an empty list when the tests API errors' do
        stub_request(:get, "#{base}/project/#{slug}/9/tests")
          .to_return(status: 404, body: { 'message' => 'not found' }.to_json)
        expect(source.failing_tests([{ 'status' => 'failed', 'job_number' => 9 }])).to eq([])
      end
    end

    describe '#recent_builds' do
      it 'lists rows across branches with rolled-up status' do
        stub_pipelines([
          { 'id' => 'p1', 'number' => 2, 'vcs' => { 'branch' => 'main', 'commit' => { 'subject' => 'A' } } },
          { 'id' => 'p2', 'number' => 1, 'vcs' => { 'branch' => 'topic', 'commit' => { 'subject' => 'B' } } }
        ])
        stub_workflows('p1', [{ 'id' => 'w1', 'status' => 'success' }])
        stub_workflows('p2', [{ 'id' => 'w2', 'status' => 'failed' }])

        rows = source.recent_builds
        expect(rows.map { |r| r[:branch] }).to eq(%w(main topic))
        expect(rows.map(&:status)).to eq(%w(Success Failed))
      end
    end
  end
end
