require 'gitable'
require 'git'

module Circle
  module CLI
    class Repo
      # Maps a remote host to the CircleCI v2 VCS slug prefix.
      VCS_PREFIXES = {
        'github.com'    => 'gh',
        'bitbucket.org' => 'bb'
      }.freeze

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
        options.fetch('branch') { repo.current_branch }
      end

      # Active CircleCI token, or nil. Resolution precedence (the value itself
      # is never logged): 1. CIRCLE_TOKEN env, 2. CIRCLE_CLI_TOKEN env,
      # 3. git config circleci.token.
      def circle_token
        resolved_token&.fetch(:value)
      end

      # Human-readable description of where the active token came from, or nil
      # when no token is configured. Never contains the token value itself.
      def circle_token_source
        resolved_token&.fetch(:source)
      end

      # Persists the token to git config. Storage location is unchanged for
      # backwards compatibility with existing setups.
      def circle_token=(token)
        repo.config('circleci.token', token)
      end

      # CircleCI API v2 project slug ("vcs/org/project"). Resolution order:
      # CIRCLE_CLI_PROJECT_SLUG env, then git config circleci.project-slug,
      # then inference from the origin remote.
      def project_slug
        env = ENV['CIRCLE_CLI_PROJECT_SLUG']
        return env if env && !env.empty?
        configured_slug || inferred_slug
      end

      private

      # Returns { source:, value: } for the first configured token in
      # precedence order, or nil. Keeps source and value together so callers
      # can report provenance without re-resolving.
      def resolved_token
        token_candidates.each do |source, value|
          return { source: source, value: value } if value && !value.empty?
        end
        nil
      end

      def token_candidates
        [
          ['CIRCLE_TOKEN environment variable',     ENV['CIRCLE_TOKEN']],
          ['CIRCLE_CLI_TOKEN environment variable', ENV['CIRCLE_CLI_TOKEN']],
          ['git config (circleci.token)',           config_value('circleci.token')]
        ]
      end

      def configured_slug
        slug = config_value('circleci.project-slug')
        slug if slug && !slug.empty?
      end

      def config_value(name)
        repo.config(name)
      rescue Git::FailedError
        nil
      end

      def inferred_slug
        prefix = VCS_PREFIXES[uri.host] || 'gh'
        "#{prefix}/#{user_name}/#{project}"
      end

      def repo
        @repo ||= Git.open(options[:repo])
      rescue ArgumentError
        full_path = File.expand_path(options[:repo])
        abort "#{full_path} is not a git repository."
      end

      def origin
        @origin ||= repo.remote('origin')
      end
    end
  end
end
