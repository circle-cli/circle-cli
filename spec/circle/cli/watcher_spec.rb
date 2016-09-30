require 'spec_helper'
require 'circle/cli/watcher'

module Circle::CLI
  RSpec.describe Watcher do
    describe '#display' do
      it 'invokes the block given in initialize' do
        displayer = -> {}
        watcher = described_class.new(&displayer)
        expect(displayer).to receive(:call).once
        watcher.display
      end
    end

    describe '#to_preload' do
      let(:watcher) { described_class.new {} }

      it 'assigns a preloader block' do
        preloader = -> {}
        watcher.to_preload(&preloader)
        expect(watcher.preloader).to eq(preloader)
      end
    end

    describe '#preload' do
      let(:watcher) { described_class.new {} }

      it 'invokes the preloader' do
        preloader = -> {}
        watcher.to_preload(&preloader)
        expect(preloader).to receive(:call)
        watcher.preload
      end
    end

    describe '#poll' do
      let(:watcher) { described_class.new {} }

      it 'displays, sleeps, preloads, then clears the screen and exits on Interrupt' do
        expect(watcher).to receive(:display).once.ordered
        expect(watcher).to receive(:sleep).with(42).once.ordered
        expect(watcher).to receive(:preload).once.ordered
        expect(watcher).to receive(:clear).and_raise(Interrupt).once.ordered
        expect { watcher.poll(42) }.to raise_error(SystemExit)
      end
    end
  end
end
