require 'gitable'
require 'rugged'

module Circle
  module CLI
    class Repo
      attr_reader :repo, :origin, :uri, :errors

      def initialize
        @repo = Rugged::Repository.new('.')
        @origin = repo.remotes.find { |r| r.name == 'origin' }
        @uri = Gitable::URI.parse(@origin.url)
        @errors = []
      end

      def valid?
        errors.clear
        errors << "Unsupported repo url format #{uri}" unless uri.github?
        errors << no_github_token_message unless github_token

        # The following validation is temporarily disabled
        # errors << no_circle_token_message unless circle_token

        errors.empty?
      end

      def github
        uri.path.gsub(/\.git$/, '') if uri.github?
      end

      def head
        repo.head.target_id
      end

      def github_token
        repo.config['github.token']
      end

      def github_token=(token)
        repo.config['github.token'] = token
      end

      def circle_token
        repo.config['circleci.token']
      end

      def circle_token=(token)
        repo.config['circleci.token'] = token
      end

      private

      def no_github_token_message
        no_token_message 'Github', 'https://github.com/settings/tokens/new', 'github-token'
      end

      def no_circle_token_message
        no_token_message 'CircleCI', 'https://circleci.com/account/api', 'token'
      end

      def no_token_message(provider, url, command)
        <<-EOMSG
Missing #{provider} token. You can create one here: #{url}

Once you have a token, add it with the following command:

  $ circle #{command} YOUR_TOKEN
        EOMSG
      end
    end
  end
end
