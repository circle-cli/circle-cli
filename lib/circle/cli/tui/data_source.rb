require 'time'
require 'circle/cli/tui/sample_data'

module Circle
  module CLI
    module TUI
      # Adapter seam that decides where the dashboard's data comes from.
      #
      # `--sample` renders the bundled fixture with no network access. The live
      # path drives the CircleCI v2 API (project pipelines -> workflows ->
      # workflow jobs) and maps the responses into the
      # { project:, branch:, pipelines: [...] } shape the renderer consumes.
      module DataSource
        def self.for(sample: false, api: nil, project_slug: nil, branch: nil,
                     pipeline_limit: LiveDataSource::PIPELINE_LIMIT)
          if sample
            SampleDataSource.new
          else
            LiveDataSource.new(
              api: api,
              project_slug: project_slug,
              branch: branch,
              pipeline_limit: pipeline_limit
            )
          end
        end
      end

      class SampleDataSource
        def dashboard
          SampleData.dashboard
        end
      end

      # Loads live dashboard data from the CircleCI v2 API and maps it into the
      # plain hash the renderer expects. The mapping is defensive: missing
      # branches of the pipeline/workflow/job tree degrade to empty lists and a
      # human-readable notice rather than raising.
      class LiveDataSource
        PIPELINE_LIMIT = 5

        def initialize(api:, project_slug:, branch: nil, pipeline_limit: PIPELINE_LIMIT)
          @api = api
          @project_slug = project_slug
          @branch = branch
          @pipeline_limit = pipeline_limit
        end

        def dashboard
          pipelines = load_pipelines
          {
            project: @project_slug,
            branch: @branch,
            pipelines: pipelines,
            notice: notice_for(pipelines)
          }
        end

        private

        def load_pipelines
          query = {}
          query[:branch] = @branch if @branch && !@branch.to_s.empty?
          raw = @api.project_pipelines(@project_slug, query, max_pages: 1)
          raw.first(@pipeline_limit).map { |pipeline| build_pipeline(pipeline) }
        end

        def build_pipeline(pipeline)
          vcs = pipeline['vcs'] || {}
          commit = vcs['commit'] || {}
          actor = (pipeline['trigger'] || {})['actor'] || {}
          {
            number: pipeline['number'],
            created_at: pipeline['created_at'],
            vcs: {
              revision: vcs['revision'],
              subject: commit['subject'] || vcs['subject'],
              author: actor['name'] || actor['login']
            },
            workflows: load_workflows(pipeline['id'])
          }
        end

        def load_workflows(pipeline_id)
          return [] unless pipeline_id
          @api.pipeline_workflows(pipeline_id).map do |workflow|
            {
              name: workflow['name'],
              status: workflow['status'],
              jobs: load_jobs(workflow['id'])
            }
          end
        end

        def load_jobs(workflow_id)
          return [] unless workflow_id
          @api.workflow_jobs(workflow_id).map do |job|
            {
              name: job['name'],
              status: job['status'],
              duration_ms: duration_ms(job['started_at'], job['stopped_at'])
            }
          end
        end

        def duration_ms(started_at, stopped_at)
          return nil unless started_at && stopped_at
          ((Time.parse(stopped_at) - Time.parse(started_at)) * 1000).to_i
        rescue ArgumentError, TypeError
          nil
        end

        # Surfaces a safe fallback message when a level of the hierarchy comes
        # back empty so the dashboard never renders a silent blank.
        def notice_for(pipelines)
          return 'No recent pipelines found for this project.' if pipelines.empty?
          if pipelines.all? { |p| (p[:workflows] || []).empty? }
            return 'No workflows found for the recent pipelines.'
          end
          if pipelines.all? { |p| (p[:workflows] || []).all? { |w| (w[:jobs] || []).empty? } }
            return 'No jobs found for the recent workflows.'
          end
          nil
        end
      end
    end
  end
end
