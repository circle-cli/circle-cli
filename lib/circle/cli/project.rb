require 'circleci'
require 'circle/cli/build'

module Circle
  module CLI
    class Project
      attr_reader :repo

      def initialize(repo)
        @repo = repo
        configure
      end

      def build!
        request CircleCi::Project, :build_branch, repo.branch_name
      end

      def builds
        @builds ||= request_builds(CircleCi::Project, :recent_builds_branch, repo.branch_name)
      end

      def recent_builds
        @recent_builds ||= request_builds(CircleCi::Project, :recent_builds)
      end

      def latest
        builds.first
      end

      def clear_cache!
        @builds = nil
        @recent_builds = nil
      end

      def request(klass, action, *args)
        response = klass.send(action, repo.user_name, repo.project, *args)

        if response.success?
          response.body
        else
          abort "The following error occurred: #{response.body['message']}"
        end
      end

      private

      def configure
        CircleCi.configure do |config|
          config.token = repo.circle_token
        end
      end

      def request_builds(*args)
        request(*args).to_a.map { |build| Build.new(self, build) }
      end
    end
  end
end
