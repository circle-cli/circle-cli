require 'gitable'
require 'rugged'

module Circle
  module CLI
    class Repo
      attr_reader :errors, :options

      def initialize(options = {})
        @options = options
      end

      def uri
        Gitable::URI.parse(origin.url)
      end

      def user_name
        uri.path[/^(\/?)(.+)\//, 2]
      end

      def project
        uri.project_name
      end

      def branch_name
        options.fetch 'branch' do
          repo.head.name.sub(/^refs\/heads\//, '')
        end
      end

      def circle_token
        repo.config['circleci.token'] || ENV['CIRCLE_CLI_TOKEN']
      end

      def circle_token=(token)
        repo.config['circleci.token'] = token
      end

      private

      def repo
        @repo ||= Rugged::Repository.new(options[:repo])
      rescue Rugged::RepositoryError
        full_path = File.expand_path(options[:repo])
        abort "#{full_path} is not a git repository."
      end

      def origin
        @origin ||= repo.remotes.find { |r| r.name == 'origin' }
      end
    end
  end
end
