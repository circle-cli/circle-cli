require 'circle/cli/model'
require 'circle/cli/step'

module Circle
  module CLI
    class Build < Model
      attr_reader :project

      def initialize(project, build = {})
        @project = project
        super(build)
      end

      def preload
        tests
        details
        self
      end

      def build_num
        self[:build_num]
      end

      def finished?
        !self[:outcome].nil?
      end

      def failed?
        self[:outcome] == 'failed'
      end

      def status
        self[:status].tr('_', ' ').capitalize
      end

      def subject
        truncate self[:subject]
      end

      def color
        color_for self[:status]
      end

      def formatted_start_time
        format_time(self[:start_time]) || 'Not started'
      end

      def formatted_stop_time
        format_time(self[:start_time]) || 'Not finished'
      end

      def cancel!
        project.request CircleCi::Build, :cancel, build_num
      end

      def details
        @details ||= project.request CircleCi::Build, :get, build_num
      end

      def steps
        details['steps'].map { |step| Step.new(step) }
      end

      def tests
        @tests ||= project.request(CircleCi::Build, :tests, build_num)['tests']
      end

      def passing_tests
        tests.reject(&failure_filter)
      end

      def failing_tests
        tests.select(&failure_filter)
      end

      private

      def failure_filter
        lambda { |t| t['result'] == 'failure' }
      end
    end
  end
end
