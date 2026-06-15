require 'spec_helper'
require 'circle/cli/tui/sample_data'

module Circle::CLI
  module TUI
    RSpec.describe SampleData do
      subject(:data) { described_class.dashboard }

      it 'returns a project identifier and branch' do
        expect(data[:project]).to be_a(String)
        expect(data[:project]).not_to be_empty
        expect(data[:branch]).to be_a(String)
      end

      it 'returns a non-empty list of pipelines' do
        expect(data[:pipelines]).to be_an(Array)
        expect(data[:pipelines]).not_to be_empty
      end

      it 'nests workflows under pipelines and jobs under workflows' do
        pipeline = data[:pipelines].first
        expect(pipeline[:number]).to be_a(Integer)
        expect(pipeline[:vcs]).to include(:subject)

        workflow = pipeline[:workflows].first
        expect(workflow[:name]).to be_a(String)
        expect(workflow[:status]).to be_a(String)

        job = workflow[:jobs].first
        expect(job[:name]).to be_a(String)
        expect(job[:status]).to be_a(String)
      end

      it 'exercises a spread of statuses for visual coverage' do
        statuses = data[:pipelines]
                   .flat_map { |p| p[:workflows] }
                   .flat_map { |w| w[:jobs] }
                   .map { |j| j[:status] }
        expect(statuses).to include('success', 'running', 'failed')
      end

      it 'returns a deep copy so callers cannot mutate the fixture' do
        described_class.dashboard[:pipelines].clear
        expect(described_class.dashboard[:pipelines]).not_to be_empty
      end
    end
  end
end
