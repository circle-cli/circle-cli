require 'circleci'

module Circle
  module CLI
    class Project
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
        @test_results = {}
        @details = {}
        configure
      end

      def [](key)
        latest[key]
      end

      def build!
        request CircleCi::Project, :build_branch, repo.branch_name
      end

      def cancel!
        request CircleCi::Build, :cancel, latest['build_num']
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

      def latest_details
        details_for latest
      end

      def details_for(build)
        @details[build['build_num']] ||= details_for!(build)
      end

      def test_results_for(build)
        @test_results[build['build_num']] ||= test_results_for!(build)
      end

      def clear_cache!
        @details.clear
        @test_results.clear
        @recent_builds = nil
        @builds = nil
      end

      def rebuild_latest_cache
        clear_cache!
        latest_test_results
        latest_details
      end

      private

      def details_for!(build)
        request CircleCi::Build, :get, build['build_num']
      end

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
