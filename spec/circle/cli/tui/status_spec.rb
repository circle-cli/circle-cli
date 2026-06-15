require 'spec_helper'
require 'circle/cli/tui/status'

module Circle::CLI
  module TUI
    RSpec.describe Status do
      describe '.color_for' do
        it 'maps success-like statuses to green' do
          %w(success fixed passed).each do |s|
            expect(described_class.color_for(s)).to eq(:green)
          end
        end

        it 'maps in-flight statuses to yellow' do
          %w(running queued scheduled not_running).each do |s|
            expect(described_class.color_for(s)).to eq(:yellow)
          end
        end

        it 'maps failure statuses to red' do
          %w(failed failing error timedout infrastructure_fail canceled).each do |s|
            expect(described_class.color_for(s)).to eq(:red)
          end
        end

        it 'maps held statuses to blue' do
          %w(on_hold blocked not_run).each do |s|
            expect(described_class.color_for(s)).to eq(:blue)
          end
        end

        it 'is symbol-key tolerant' do
          expect(described_class.color_for(:success)).to eq(:green)
        end

        it 'falls back to blue for unknown statuses' do
          expect(described_class.color_for('something_new')).to eq(:blue)
          expect(described_class.color_for(nil)).to eq(:blue)
        end
      end

      describe '.icon_for' do
        it 'returns a unicode glyph by default' do
          expect(described_class.icon_for('success')).to eq('✔')
          expect(described_class.icon_for('failed')).to eq('✖')
        end

        it 'returns an ascii glyph when unicode is disabled' do
          icon = described_class.icon_for('success', unicode: false)
          expect(icon).to eq('ok')
          expect(icon.bytesize).to eq(icon.length) # pure ascii
        end

        it 'falls back to a neutral glyph for unknown statuses' do
          expect(described_class.icon_for('mystery')).to eq('•')
          expect(described_class.icon_for('mystery', unicode: false)).to eq('*')
        end
      end

      describe '.label_for' do
        it 'humanizes the status' do
          expect(described_class.label_for('not_running')).to eq('Not running')
          expect(described_class.label_for('on_hold')).to eq('On hold')
        end

        it 'handles nil' do
          expect(described_class.label_for(nil)).to eq('Unknown')
        end
      end
    end
  end
end
