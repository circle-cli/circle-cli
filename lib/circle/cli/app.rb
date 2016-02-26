require 'octokit'
require 'launchy'
require 'circle/cli/token'

module Circle
  module CLI
    class App < Thor
      STATUS_COLORS = {
        'success' => :green,
        'error' => :red,
        'failure' => 'red',
        'pending' => 'yellow'
      }

      default_task :status

      desc 'token', 'manage API tokens'
      subcommand :token, Circle::CLI::Token

      desc 'status', 'display CircleCI status'
      method_option :repo, default: '.', desc: 'path to repo'
      method_option :branch, desc: 'branch name'
      def status
        validate!
        state = last_status.state
        say last_status.description, STATUS_COLORS[state]
        exit(state == 'success' ? 0 : 1)
      end

      desc 'open', 'open CircleCI build'
      method_option :repo, default: '.', desc: 'path to repo'
      method_option :branch, desc: 'branch name'
      def open
        validate!
        Launchy.open last_status.rels[:target].href
      end

      private

      def repo
        @repo ||= Repo.new(options)
      end

      def validate!
        abort! repo.errors.first unless repo.valid?
        abort! 'No CI run found' unless last_status
      end

      def last_status
        @last_status ||= begin
          all_statuses = github_client.statuses(repo.github, repo.target)
          all_statuses.find { |s| s.context == 'ci/circleci' }
        end
      end

      def github_client
        @github_client ||= Octokit::Client.new(access_token: repo.github_token)
      end

      def abort!(message)
        abort set_color(message, :red)
      end
    end
  end
end
