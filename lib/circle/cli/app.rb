require 'launchy'
require 'circle/cli/repo'
require 'circle/cli/report'

module Circle
  module CLI
    class App < Thor
      CIRCLE_URL = 'https://circleci.com/account/api'

      STATUS_COLORS = {
        green: %w(fixed success),
        yellow: %w(running retried not_run queued scheduled not_running no_tests),
        red: %w(canceled infrastructure_fail timedout failed)
      }

      LOGIN_HELP = <<-EOMSG
1. Press [enter], and you'll be taken CircleCI.
2. Enter a name for your new token.
3. Click 'Create new token'.
4. Come back to your prompt and paste in your new token.
5. Press enter to complete the process.
      EOMSG

      NO_TOKEN_MESSAGE = <<-EOMSG
CircleCI token hasn't been configured. Run the following command to login:

  $ circle login
      EOMSG

      default_task :status
      class_option :repo, default: '.', desc: 'path to repo'

      desc 'status', 'show CircleCI build result'
      method_option :branch, desc: 'branch name'
      def status
        validate_repo!
        validate_latest!
        stop_time = pretty_date(report['stop_time']) || 'Still running...'
        start_time = pretty_date(report['start_time']) || 'Not run'

        say "#{report['subject']}\n\n", :cyan
        color = color_for_status report['status']
        say_report 'Build status', report['status'].capitalize, color
        say_report 'Started at', start_time, color
        say_report 'Finished at', stop_time, color
        say_report 'Compare', report['compare'], color
        display_failures report.latest_test_results.failing
      end

      desc 'overview', 'list recent builds and their statuses for all branches'
      def overview
        validate_repo!
        abort! 'No recent builds.' if report.recent_builds.empty?
        print_table builds_to_rows(report.recent_builds)
      end

      desc 'open', 'open CircleCI build'
      method_option :branch, desc: 'branch name'
      def open
        validate_repo!
        validate_latest!
        Launchy.open report['build_url']
      end

      desc 'token', 'view or edit CircleCI token'
      def token(value = nil)
        if value
          repo.circle_token = value
        elsif value = repo.circle_token
          say value
        else
          say NO_TOKEN_MESSAGE, :yellow
        end
      end

      desc 'login', 'login to Circle CI'
      def login
        say LOGIN_HELP, :yellow
        ask set_color("\nPress [enter] to open CircleCI", :blue)
        Launchy.open(CIRCLE_URL)
        value = ask set_color('Enter your token:', :blue)
        repo.circle_token = value
        say "\nYour token has been set to '#{value}'.", :green
      end

      private

      def repo
        @repo ||= Repo.new(options)
      end

      def report
        @report ||= Report.new(repo)
      end

      def validate_repo!
        abort! "Unsupported repo url format #{repo.uri}" unless repo.uri.github?
        abort! NO_TOKEN_MESSAGE unless repo.circle_token
      end

      def validate_latest!
        abort! 'No CircleCI builds found.' unless report.latest
      end

      def abort!(message)
        abort set_color(message, :red)
      end

      def color_for_status(status)
        case status
        when *STATUS_COLORS[:green] then :green
        when *STATUS_COLORS[:yellow] then :yellow
        when *STATUS_COLORS[:red] then :red
        else :blue
        end
      end

      def builds_to_rows(builds)
        builds.map do |build|
          branch = set_color(build['branch'], :bold)
          status_color = color_for_status(build['status'])
          status = build['status'].tr('_', ' ').capitalize
          status = set_color(status, status_color)
          subject = truncate build['subject']
          started = pretty_date(build['start_time'])
          [branch, status, subject, started]
        end
      end

      def say_report(description, value, color)
        status = set_color description.ljust(15), :bold
        result = set_color value.to_s, color
        say "#{status} #{result}"
      end

      def display_failures(failures)
        return if failures.empty?
        say "\nFailing specs:", :bold

        print_table failures.map { |spec|
          [set_color(spec['file'], :red), spec['name']]
        }
      end

      def truncate(str, length = 50)
        return str if str.length <= length
        "#{str[0..50]}..."
      end

      def pretty_date(str)
        Time.parse(str).strftime('%b %e, %-l:%M %p') if str
      rescue ArgumentError
      end
    end
  end
end
