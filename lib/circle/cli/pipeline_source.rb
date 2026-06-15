require 'time'
require 'circle/cli/api_error'
require 'circle/cli/web_url'
require 'circle/cli/pipeline_build'

module Circle
  module CLI
    # v2-backed replacement for the read-only slice of the legacy Project. It
    # drives the CircleCI API v2 (project pipelines -> workflows -> jobs) and
    # maps the responses onto PipelineBuild objects so `status`, `overview`,
    # and `open` keep their existing display contract without the v1 gem.
    #
    # `latest` is branch-scoped (the newest pipeline on the resolved branch);
    # `recent_builds` spans all branches, matching the legacy commands.
    class PipelineSource
      # Caps the per-pipeline workflow lookups `recent_builds` performs so an
      # overview never fans out into an unbounded number of API calls.
      RECENT_LIMIT = 20

      FAILED_JOB_STATUSES = %w(failed error).freeze

      def initialize(api:, project_slug:, branch: nil)
        @api = api
        @project_slug = project_slug
        @branch = branch
      end

      # Newest pipeline on the resolved branch as a PipelineBuild, or nil when
      # the branch has none. Memoized (including the nil result).
      def latest
        return @latest if defined?(@latest)
        @latest = load_latest
      end

      # Recent pipelines across all branches as build-like rows for the
      # overview table. Status is rolled up from each pipeline's newest
      # workflow; jobs are not fetched since the overview never lists steps.
      def recent_builds
        @recent_builds ||= load_recent_builds
      end

      def clear_cache!
        remove_instance_variable(:@latest) if defined?(@latest)
        @recent_builds = nil
      end

      # Failing specs across the given jobs' failed runs, mapped into the
      # { 'file' =>, 'name' => } shape the status view expects. Any API hiccup
      # degrades to an empty list rather than aborting the status render.
      def failing_tests(jobs)
        Array(jobs)
          .select { |job| FAILED_JOB_STATUSES.include?(job['status']) && job['job_number'] }
          .flat_map { |job| job_test_failures(job['job_number']) }
      rescue ApiError
        []
      end

      private

      def load_latest
        query = {}
        query[:branch] = @branch if @branch && !@branch.to_s.empty?
        pipeline = @api.project_pipelines(@project_slug, query, max_pages: 1).first
        return nil unless pipeline

        workflows = workflows_for(pipeline)
        workflow = workflows.first
        jobs = workflow ? @api.workflow_jobs(workflow['id']) : []
        PipelineBuild.new(self, build_attributes(pipeline, workflow), jobs)
      rescue ApiError
        nil
      end

      def load_recent_builds
        @api.project_pipelines(@project_slug, {}, max_pages: 1)
            .first(RECENT_LIMIT)
            .map { |pipeline| overview_row(pipeline) }
      rescue ApiError
        []
      end

      # Lightweight build row: status comes from the newest workflow, but jobs
      # are deliberately not fetched (the overview lists no steps).
      def overview_row(pipeline)
        workflow = workflows_for(pipeline).first
        PipelineBuild.new(nil, build_attributes(pipeline, workflow), [])
      end

      def workflows_for(pipeline)
        id = pipeline['id']
        return [] unless id
        @api.pipeline_workflows(id)
      rescue ApiError
        []
      end

      def build_attributes(pipeline, workflow)
        vcs = pipeline['vcs'] || {}
        commit = vcs['commit'] || {}
        number = pipeline['number']
        {
          'subject'    => commit['subject'] || vcs['subject'],
          'branch'     => vcs['branch'],
          'status'     => workflow && workflow['status'],
          'start_time' => (workflow && workflow['created_at']) || pipeline['created_at'],
          'stop_time'  => workflow && workflow['stopped_at'],
          'compare'    => vcs['compare'],
          'build_url'  => web_url(number, workflow)
        }
      end

      def web_url(number, workflow)
        if workflow && workflow['id']
          WebUrl.workflow(@project_slug, number, workflow['id'])
        else
          WebUrl.pipeline(@project_slug, number)
        end
      end

      def job_test_failures(job_number)
        @api.job_tests(@project_slug, job_number)
            .select { |test| test['result'] == 'failure' }
            .map do |test|
              {
                'file' => test['file'] || test['classname'] || test['name'],
                'name' => test['name']
              }
            end
      rescue ApiError
        []
      end
    end
  end
end
