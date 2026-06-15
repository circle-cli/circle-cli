require 'spec_helper'
require 'circle/cli/tui/dashboard_renderer'

module Circle::CLI
  module TUI
    RSpec.describe DashboardRenderer do
      ANSI = /\e\[[0-9;]*m/

      let(:data) do
        {
          project: 'circle-cli/circle-cli',
          branch: 'main',
          pipelines: [
            {
              number: 128,
              vcs: {
                revision: 'a1b2c3d4e5',
                subject: 'Add modern TUI dashboard',
                author: 'Derek Keith'
              },
              created_at: '2026-06-14T18:00:00Z',
              workflows: [
                {
                  name: 'ci-pipeline',
                  status: 'running',
                  jobs: [
                    { name: 'build',  status: 'success', duration_ms: 45_000 },
                    { name: 'test',   status: 'running', duration_ms: 12_000 },
                    { name: 'deploy', status: 'blocked', duration_ms: nil }
                  ]
                }
              ]
            }
          ]
        }
      end

      def strip(str)
        str.gsub(ANSI, '')
      end

      def render(opts = {})
        described_class.new(data, { color: false, width: 80, unicode: true }.merge(opts)).render
      end

      describe 'content hierarchy' do
        it 'renders the project and branch' do
          out = strip(render)
          expect(out).to include('circle-cli/circle-cli')
          expect(out).to include('main')
        end

        it 'renders the pipeline number and commit subject' do
          out = strip(render)
          expect(out).to include('128')
          expect(out).to include('Add modern TUI dashboard')
        end

        it 'renders workflow and job names' do
          out = strip(render)
          expect(out).to include('ci-pipeline')
          expect(out).to include('build')
          expect(out).to include('test')
          expect(out).to include('deploy')
        end

        it 'renders job durations in human form' do
          out = strip(render)
          expect(out).to include('45s')
        end

        it 'indents jobs under their workflow' do
          lines = strip(render).split("\n")
          job_line = lines.find { |l| l.include?('deploy') }
          workflow_line = lines.find { |l| l.include?('ci-pipeline') }
          job_indent = job_line[/\A */].length
          workflow_indent = workflow_line[/\A */].length
          expect(job_indent).to be > workflow_indent
        end
      end

      describe 'status icons' do
        it 'shows a success glyph for passing jobs' do
          expect(render).to include('✔')
        end

        it 'shows a failure glyph when a job failed' do
          data[:pipelines][0][:workflows][0][:jobs][0][:status] = 'failed'
          expect(render).to include('✖')
        end

        it 'uses ascii glyphs when unicode is disabled' do
          out = render(unicode: false)
          expect(out).not_to include('✔')
          expect(out).to include('ok')
        end
      end

      describe 'color handling' do
        it 'emits no ANSI escapes when color is disabled (script-safe)' do
          expect(render(color: false)).not_to match(ANSI)
        end

        it 'emits ANSI escapes when color is enabled' do
          expect(render(color: true)).to match(ANSI)
        end
      end

      describe 'narrow terminals' do
        it 'never emits a visible line wider than the requested width' do
          out = render(color: false, width: 30)
          widest = out.split("\n").map(&:length).max
          expect(widest).to be <= 30
        end

        it 'still renders the project and at least one job when narrow' do
          out = strip(render(width: 24))
          expect(out).to include('circle-cli')
          expect(out).to include('build')
        end

        it 'drops the header box on very narrow widths but keeps content' do
          out = strip(render(width: 20))
          expect(out).not_to include('╭')
          expect(out).to include('main')
        end
      end

      describe 'empty state' do
        let(:data) { { project: 'acme/widgets', branch: 'main', pipelines: [] } }

        it 'renders a friendly empty message instead of crashing' do
          out = strip(render)
          expect(out).to include('acme/widgets')
          expect(out).to match(/no .*pipelines/i)
        end
      end

      describe 'resilience' do
        it 'tolerates missing optional fields' do
          data[:pipelines][0][:vcs] = {}
          data[:pipelines][0][:workflows][0][:jobs][0].delete(:duration_ms)
          expect { render }.not_to raise_error
        end
      end
    end
  end
end
