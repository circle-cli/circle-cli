require 'spec_helper'
require 'circle/cli/step'

module Circle::CLI
  RSpec.describe Step do
    let(:step) { Step.new(attrs) }

    describe '#color' do
      let(:attrs) {
        { 'actions' => [{ 'status' => 'failed' }] }
      }

      specify { expect(step.color).to eq(:red) }
    end

    describe '#duration' do
      subject     { step.duration }
      let(:attrs) { { 'run_time_millis' => millis } }

      context 'hours' do
        let(:millis) { 10_000_000 }
        specify { is_expected.to eq('2h 46m 40s') }
      end

      context 'minutes' do
        let(:millis) { 1_000_000 }
        specify { is_expected.to eq('16m 40s') }
      end

      context 'seconds' do
        let(:millis) { 2_000 }
        specify { is_expected.to eq('2s') }
      end

      context 'milliseconds' do
        let(:millis) { 200 }
        specify { is_expected.to eq('200ms') }
      end
    end
  end
end
