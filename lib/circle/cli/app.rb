require 'optparse'
require 'octokit'
require 'circleci'

module Circle
  module CLI
    class App
      attr_reader :repo

      def initialize
        @options = {}
        @repo = Repo.new
        @parser ||= OptionParser.new do |opts|
          # future options will go here
        end
      end

      def dispatch!(argv)
        @parser.parse!
        command, *args = argv
        command = 'status' unless command

        method = "run_#{command.tr('-', '_')}"
        if respond_to?(method)
          send(method, *args)
        else
          abort("Unknown command: #{command}")
        end
      end

      def run_status
        validate_repo!

        if last_status && last_status.state == 'success'
          puts last_status.state
          exit(0)
        elsif last_status
          puts last_status.state
        else
          puts 'unknown'
        end

        exit(1)
      end

      def run_open
        validate_repo!

        if last_status
          open(last_status.rels[:target].href)
        else
          puts 'No CI run found'
        end
      end

      def run_token(token = nil)
        if token
          repo.circle_token = token
        else
          puts repo.circle_token
        end
      end

      def run_github_token(token = nil)
        if token
          repo.github_token = token
        else
          puts repo.github_token
        end
      end

      private

      def open(url)
        `open '#{url}'`
      end

      def last_status
        @last_status ||= github_client.statuses(repo.github, repo.head).first
      end

      def github_client
        @github_client ||= Octokit::Client.new(access_token: repo.github_token)
      end

      def configure_circle_ci_client
        CircleCi.configure do |config|
          config.token = circle_token
        end
      end

      def validate_repo!
        abort repo.errors.first unless repo.valid?
      end
    end
  end
end
