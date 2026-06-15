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
          source = described_class.for(sample: false, project: double)
          expect(source).to be_a(LiveDataSource)
        end
      end

      describe LiveDataSource do
        it 'raises a clear pending-integration error until v2 is wired up' do
          source = described_class.new(double('project'))
          expect { source.dashboard }.to raise_error(PendingIntegration, /v2|sample/i)
        end
      end
    end
  end
end
