require 'circle/cli/tui/sample_data'

module Circle
  module CLI
    module TUI
      # Raised when live dashboard data is requested but the CircleCI v2
      # pipeline/workflow integration has not been wired up yet.
      class PendingIntegration < StandardError; end

      # Adapter seam that decides where the dashboard's data comes from.
      #
      # Today the only fully-working source is the bundled sample fixture
      # (`--sample`). The live path is stubbed behind LiveDataSource so the TUI
      # and its command can ship now; swapping in a real CircleCI v2 client is
      # a localized change that does not touch the renderer.
      module DataSource
        def self.for(sample: false, project: nil)
          if sample
            SampleDataSource.new
          else
            LiveDataSource.new(project)
          end
        end
      end

      class SampleDataSource
        def dashboard
          SampleData.dashboard
        end
      end

      class LiveDataSource
        def initialize(project)
          @project = project
        end

        # TODO: integrate the CircleCI v2 API (GET /project/.../pipeline,
        # /pipeline/:id/workflow, /workflow/:id/job) and map the responses into
        # the { project:, branch:, pipelines: [...] } shape the renderer
        # consumes. The v1 client used elsewhere in this gem only exposes
        # "builds", not the pipeline/workflow/job hierarchy.
        def dashboard
          raise PendingIntegration,
                'Live pipeline/workflow data needs the CircleCI v2 API, which ' \
                'is not wired up yet. Run `circle dashboard --sample` to preview ' \
                'the dashboard with bundled data.'
        end
      end
    end
  end
end
