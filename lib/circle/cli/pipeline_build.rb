require 'time'
require 'circle/cli/model'
require 'circle/cli/tui/status'

module Circle
  module CLI
    # A single job within a workflow, presented with the same interface the
    # status view expects from a v1 Step: a name, a status colour, and a
    # human-readable duration. Duration is derived from the job's start/stop
    # timestamps since v2 jobs do not carry a run_time field.
    class JobStep < Model
      def color
        TUI::Status.color_for(self[:status])
      end

      # Formatted run time (e.g. "1m 5s"), or nil when the job has not produced
      # both a start and a stop timestamp yet.
      def duration
        started = self[:started_at]
        stopped = self[:stopped_at]
        return unless started && stopped

        ms = ((Time.parse(stopped) - Time.parse(started)) * 1000).to_i
        return if ms.negative?

        format_duration(ms)
      rescue ArgumentError, TypeError
        nil
      end

      private

      def format_duration(ms)
        hours = (ms / (1000 * 60 * 60)) % 24
        minutes = (ms / (1000 * 60)) % 60
        seconds = (ms / 1000) % 60

        message = []
        message << "#{hours}h" unless hours.zero?
        message << "#{minutes}m" unless minutes.zero?
        message << "#{seconds}s" unless seconds.zero?
        message << "#{ms}ms" if message.empty?
        message.join(' ')
      end
    end

    # Build-like view over an API v2 pipeline and its representative workflow.
    # It exposes the same surface the legacy v1 Build did (status, colour,
    # timestamps, steps, failing tests, finished?/failed?) so the existing
    # status/overview display code keeps working against v2 data.
    #
    # Status semantics intentionally tighten relative to v1: canceled and
    # errored runs are treated as failures so `circle status` exits non-zero
    # for them, matching the migration brief.
    class PipelineBuild < Model
      FAILED_STATUSES = %w(failed error canceled unauthorized).freeze
      TERMINAL_STATUSES = (FAILED_STATUSES + %w(success not_run)).freeze

      # source: the PipelineSource (for lazy test lookups); may be nil for
      #   lightweight overview rows that never request failing tests.
      # attributes: normalized string-keyed hash consumed via Model#[].
      # jobs: raw v2 job hashes for the representative workflow.
      def initialize(source, attributes = {}, jobs = [])
        @source = source
        @jobs = jobs || []
        super(attributes)
      end

      def status
        TUI::Status.label_for(self[:status])
      end

      def color
        TUI::Status.color_for(self[:status])
      end

      def subject
        truncate self[:subject]
      end

      def finished?
        TERMINAL_STATUSES.include?(self[:status])
      end

      def failed?
        FAILED_STATUSES.include?(self[:status])
      end

      def formatted_start_time
        format_time(self[:start_time]) || 'Not started'
      end

      def formatted_stop_time
        format_time(self[:stop_time]) || 'Not finished'
      end

      def steps
        @steps ||= @jobs.map do |job|
          JobStep.new(
            'name'       => job['name'],
            'status'     => job['status'],
            'started_at' => job['started_at'],
            'stopped_at' => job['stopped_at']
          )
        end
      end

      # Failing specs across the workflow's failed jobs, in the
      # { 'file' =>, 'name' => } shape the status view renders. Degrades to an
      # empty list when no source is attached or the tests API is unavailable.
      def failing_tests
        @failing_tests ||= @source ? @source.failing_tests(@jobs) : []
      end

      # Eagerly resolves the data the status view needs so a --watch refresh
      # does not lazily fetch mid-render. Returns self to mirror v1 Build.
      def preload
        failing_tests
        self
      end
    end
  end
end
