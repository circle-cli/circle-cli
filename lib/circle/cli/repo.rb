require 'gitable'
require 'rugged'

module Circle
  module CLI
    class Repo
      attr_reader :repo, :origin, :uri, :errors, :options

      def initialize(options = {})
        @options = options
        @errors = []
      end

      def uri
        Gitable::URI.parse(origin.url)
      end

      def valid?
        errors.clear
        errors << "Unsupported repo url format #{uri}" unless uri.github?
        errors << no_token_message unless circle_token
        errors.empty?
      end

      def user_name
        uri.path.split('/').first
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
        repo.config['circleci.token']
      end

      def circle_token=(token)
        repo.config['circleci.token'] = token
      end

      private

      def repo
        @repo ||= Rugged::Repository.new(options[:repo])
      end

      def origin
        @origin ||= repo.remotes.find { |r| r.name == 'origin' }
      end
    end
  end
end
