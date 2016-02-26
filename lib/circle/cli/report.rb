require 'circleci'

module Circle
  module CLI
    class Report
      class Tests < Struct.new(:tests)
        def passing
          @passing ||= tests.reject(&failure_filter)
        end

        def failing
          @failing ||= tests.select(&failure_filter)
        end

        private

        def failure_filter
          lambda { |t| t['result'] == 'failure' }
        end
      end

      attr_reader :repo

      def initialize(repo)
        @repo = repo
        configure
      end

      def [](key)
        latest[key]
      end

      def builds
        @builds ||= request CircleCi::Project, :recent_builds_branch, repo.branch_name
      end

      def recent_builds
        @recent_builds ||= request CircleCi::Project, :recent_builds
      end

      def latest
        builds.first
      end

      def latest_test_results
        test_results_for latest
      end

      def test_results_for(build)
        (@test_results ||= {})[build['build_num']] ||= test_results_for!(build)
      end

      private

      def test_results_for!(build)
        Tests.new request(CircleCi::Build, :tests, build['build_num'])['tests']
      end

      def request(klass, action, *args)
        klass.send(action, repo.user_name, repo.project, *args).body
      end

      def configure
        CircleCi.configure do |config|
          config.token = repo.circle_token
        end
      end
    end
  end
end
