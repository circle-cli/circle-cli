require 'spec_helper'
require 'circle/cli/app'

module Circle::CLI
  RSpec.describe App, 'dashboard command' do
    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end

    it 'renders the bundled sample data without needing a repo or token' do
      out = capture_stdout { App.start(%w(dashboard --sample --no-color)) }
      expect(out).to include('circle-cli')
      expect(out).to include('Pipeline')
      expect(out).not_to match(/\e\[[0-9;]*m/) # --no-color stays script-safe
    end

    it 'is reachable through the `tui` alias' do
      out = capture_stdout { App.start(%w(tui --sample --no-color)) }
      expect(out).to include('circle-cli')
    end

    it 'exits with friendly guidance when live data is requested but unavailable' do
      allow_any_instance_of(App).to receive(:repo).and_raise(StandardError, 'no repo here')
      expect {
        capture_stdout { App.start(%w(dashboard)) }
      }.to raise_error(SystemExit)
    end
  end
end
