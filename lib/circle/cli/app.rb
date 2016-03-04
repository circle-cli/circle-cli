require 'launchy'
require 'circle/cli/repo'
require 'circle/cli/project'

module Circle
  module CLI
    class App < Thor
      CIRCLE_URL = 'https://circleci.com/account/api'

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
        display_status
      end

      desc 'watch', 'watch your build'
      method_option :branch, desc: 'branch name'
      method_option :poll, default: 5, desc: 'polling frequency', type: :numeric
      def watch
        validate_repo!
        validate_latest!
        watching -> { project.latest.preload } do
          display_status
        end
      end

      desc 'overview', 'list recent builds and their statuses for all branches'
      method_option :watch, desc: 'watch the list of builds'
      method_option :poll, default: 5, desc: 'polling frequency', type: :numeric
      def overview
        validate_repo!
        abort! 'No recent builds.' if project.recent_builds.empty?
        show_overview = -> { display_builds(project.recent_builds) }

        if options[:watch]
          watching(-> { project.recent_builds  }, &show_overview)
        else
          show_overview
        end
      end

      desc 'open', 'open CircleCI build'
      method_option :branch, desc: 'branch name'
      def open
        validate_repo!
        validate_latest!
        Launchy.open latest[:build_url]
      end

      desc 'build', 'trigger a build on circle ci'
      method_option :branch, desc: 'branch name'
      def build
        validate_repo!
        project.build!
        say "A build has been triggered.\n\n", :green
        invoke :watch
      end

      desc 'cancel', 'cancel most recent build'
      method_option :branch, desc: 'branch name'
      def cancel
        validate_repo!
        validate_latest!
        latest.cancel! unless latest.finished?
        invoke :status
        say "\nThe build has been cancelled.", :red unless latest.finished?
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

      def project
        @project ||= Project.new(repo)
      end

      def latest
        project.latest
      end

      def validate_repo!
        abort! "Unsupported repo url format #{repo.uri}" unless repo.uri.github?
        abort! NO_TOKEN_MESSAGE unless repo.circle_token
      end

      def validate_latest!
        abort! 'No CircleCI builds found.' unless project.latest
      end

      def abort!(message)
        abort set_color(message, :red)
      end

      def watching(preloader)
        loop do
          yield
          sleep options[:poll]
          project.clear_cache!
          preloader.call
          system('clear') || system('cls')
        end
      rescue Interrupt
        exit 0
      end

      def display(description, value, color)
        status = set_color description.ljust(15), :bold
        result = set_color value.to_s, color
        say "#{status} #{result}"
      end

      def display_status
        say "#{latest[:subject]}\n\n", :cyan if latest[:subject]
        display 'Build status', latest.status, latest.color
        display 'Started at', latest.formatted_start_time, latest.color
        display 'Finished at', latest.formatted_stop_time, latest.color
        display 'Compare', latest[:compare], latest.color if latest[:compare]
        display_steps latest.steps unless latest.steps.empty?
        display_failures latest.failing_tests unless latest.failing_tests.empty?
        exit 1 if latest.failed?
        exit 0 if latest.finished?
      end

      def display_steps(steps)
        say "\nSteps:", :bold

        print_table steps.map { |step|
          [set_color(step[:name], step.color), step.duration]
        }
      end

      def display_failures(failures)
        say "\nFailing specs:", :bold

        print_table failures.map { |spec|
          [set_color(spec['file'], :red), spec['name']]
        }
      end

      def display_builds(builds)
        print_table builds.map { |build|
          branch = set_color(build[:branch], :bold)
          status = set_color(build.status, build.color)
          started = build.formatted_start_time
          [branch, status, build.subject, started]
        }
      end
    end
  end
end
