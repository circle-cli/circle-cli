require 'circle/cli/version'
require 'uri'
require 'rugged'
require 'octokit'
require 'circleci'

module Circle
  class CLI

    class << self

      def run(*args)
        new.dispatch!(*args)
      end

    end

    def initialize
      @options = {}
      @parser ||= OptionParser.new do |opts|
        # future options will go here
      end
    end

    def dispatch!(argv)
      @parser.parse!
      command, *args = argv

      method = "run_#{command.gsub('-', '_')}"
      if respond_to?(method)
        send(method, *args)
      else
        abort!("Unknown command: #{command}")
      end
    end

    def run_status
      unless last_status
        puts 'unknown'
        exit(1)
      end

      puts last_status.state
      exit(0)
    end

    def run_open
      unless last_status
        puts 'No CI run found'
      end
      open(last_status.rels[:target].href)
    end

    def run_token(token=nil)
      if token
        repository.config['circleci.token'] = token
      else
        puts circle_token
      end
    end

    def run_github_token(token=nil)
      if token
        repository.config['github.token'] = token
      else
        puts github_token
      end
    end

    private

    def open(url)
      `open '#{url}'`
    end

    def last_status
      unless defined?(@last_status)
        @last_status = github_client.statuses(github_repo, head).first
      end
      @last_status
    end

    def github_repo
      if origin.url =~ %r{git@github.com:(\w+/\w+)\.git}
        $1
      else
        raise "Unsupported repo url format #{origin.url.inpect}" # TODO: support other formats, mainly https
      end
    end

    def origin
      @origin ||= repository.remotes.find { |r| r.name == 'origin' }
    end

    def head
      repository.head.target
    end

    def repository
      @repository ||= Rugged::Repository.new('.') # TODO: allow to be called from a subdirectory
    end

    def github_client
      @github_client ||= Octokit::Client.new(access_token: github_token)
    end

    def configure_circle_ci_client
      CircleCi.configure do |config|
        config.token = circle_token
      end
    end

    def github_token # TODO: github-token should probably be in a global config
      repository.config['github.token'] || abort!(%{Missing GitHub token.
You can create one here: https://github.com/settings/tokens/new
And add it with the following command: $ circle github-token YOUR_TOKEN})
    end

    def circle_token
      repository.config['circleci.token'] || abort!(%{Missing CircleCI token.
You can create one here: https://circleci.com/account/api
And add it with the following command: $ circle token YOUR_TOKEN})
    end

    def abort!(message, code=1)
      STDERR.puts(message)
      exit(code)
    end

  end
end
