require 'launchy'
require 'circle/cli/repo'
require 'circle/cli/report'

module Circle
  module CLI
    class App < Thor
      STATUS_COLORS = {
        green: %w(fixed success),
        yellow: %w(running retried not_run queued scheduled not_running no_tests),
        red: %w(canceled infrastructure_fail timedout failed)
      }

      default_task :status

      desc 'status', 'show CircleCI build result'
      method_option :repo, default: '.', desc: 'path to repo'
      method_option :branch, desc: 'branch name'
      def status
        validate!
        say "#{report['subject']}\n\n", :cyan
        color = color_for_status report['status']
        say_report 'Build status', report['status'].to_s.capitalize, color
        say_report 'Started at', report['start_time'], color
        say_report 'Finished at', (report['stop_time'] || 'Still running...'), color
        say_report 'Compare', report['compare'], color
        display_failures report.latest_test_results.failing
      end

      desc 'open', 'open CircleCI build'
      method_option :repo, default: '.', desc: 'path to repo'
      method_option :branch, desc: 'branch name'
      def open
        validate!
        Launchy.open report['build_url']
      end

      desc 'token', 'view or edit CircleCI token'
      method_option :repo, default: '.', desc: 'path to repo'
      def token(value = nil)
        if value
          repo.circle_token = value
        elsif value = repo.circle_token
          say value
        else
          say repo.no_token_message, :yellow
        end
      end

      private

      def repo
        @repo ||= Repo.new(options)
      end

      def report
        @report ||= Report.new(repo)
      end

      def validate!
        abort! repo.errors.first unless repo.valid?
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
    end
  end
end
