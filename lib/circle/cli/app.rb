require 'io/console'
require 'json'
require 'time'
require 'launchy'
require 'thor'
require 'circle/cli/repo'
require 'circle/cli/project'
require 'circle/cli/watcher'
require 'circle/cli/api_client'
require 'circle/cli/api_error'
require 'circle/cli/tui/dashboard_renderer'
require 'circle/cli/tui/data_source'

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
      method_option :watch, desc: 'watch the build', type: :boolean, default: false
      method_option :poll, default: 5, desc: 'polling frequency', type: :numeric
      def status
        validate_repo!
        validate_latest!

        watcher = Watcher.new do
          display_status
        end

        watcher.to_preload do
          project.clear_cache!
          project.latest.preload
        end

        if options[:watch]
          watcher.poll(options[:poll])
        else
          watcher.display
        end
      end

      desc 'watch', 'an alias for `circle --watch`', hide: true
      def watch
        invoke :status, [], watch: true
      end

      desc 'overview', 'list recent builds and their statuses for all branches'
      method_option :watch, desc: 'watch the list of builds', type: :boolean, default: false
      method_option :poll, default: 5, desc: 'polling frequency', type: :numeric
      def overview
        validate_repo!
        abort! 'No recent builds.' if project.recent_builds.empty?

        watcher = Watcher.new do
          display_builds(project.recent_builds)
        end

        watcher.to_preload do
          project.clear_cache!
          project.recent_builds
        end

        if options[:watch]
          watcher.poll(options[:poll])
        else
          watcher.display
        end
      end

      desc 'open', 'open CircleCI build'
      method_option :branch, desc: 'branch name'
      def open
        validate_repo!
        validate_latest!
        Launchy.open latest[:build_url]
      end

      desc 'build', 'trigger a build on CircleCI'
      method_option :branch, desc: 'branch name'
      def build
        validate_repo!
        project.build!
        say "A build has been triggered.\n\n", :green
        invoke :status, [], watch: true
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

      desc 'dashboard', 'show a modern CircleCI pipeline dashboard'
      method_option :sample, type: :boolean, default: false,
                             desc: 'render bundled sample data without repo or token access'
      method_option :color, type: :boolean, default: true,
                            desc: 'enable ANSI color output'
      method_option :unicode, type: :boolean, default: true,
                              desc: 'enable unicode icons and box drawing'
      method_option :width, type: :numeric,
                            desc: 'override terminal width for rendering'
      method_option :branch, desc: 'limit live pipelines to a branch'
      def dashboard
        source =
          if options[:sample]
            TUI::DataSource.for(sample: true)
          else
            validate_token!
            TUI::DataSource.for(
              sample: false,
              api: api,
              project_slug: repo.project_slug,
              branch: options[:branch]
            )
          end

        say TUI::DashboardRenderer.new(
          source.dashboard,
          color: options[:color],
          unicode: options[:unicode],
          width: dashboard_width
        ).render
      rescue ApiError => e
        abort! e.message
      rescue StandardError => e
        abort! "Unable to load dashboard data: #{e.message}"
      end

      desc 'tui', 'an alias for `circle dashboard`', hide: true
      method_option :sample, type: :boolean, default: false
      method_option :color, type: :boolean, default: true
      method_option :unicode, type: :boolean, default: true
      method_option :width, type: :numeric
      method_option :branch, desc: 'limit live pipelines to a branch'
      def tui
        invoke :dashboard, [], options
      end

      desc 'token [VALUE]', 'save a CircleCI token, or report token status'
      method_option :show, type: :boolean, default: false,
                           desc: 'print the configured token value (handle with care)'
      def token(value = nil)
        if value
          repo.circle_token = value
          say 'Your CircleCI token has been saved.', :green
        elsif options[:show]
          print_token_value
        elsif repo.circle_token
          say "A CircleCI token is configured (source: #{repo.circle_token_source}).", :green
        else
          say NO_TOKEN_MESSAGE, :yellow
        end
      end

      desc 'me', 'show the current CircleCI user (API v2)'
      def me
        validate_token!
        user = api.get('/me')
        say "#{user['name'] || user['login']} (#{user['id']})"
      rescue ApiError => e
        abort! e.message
      end

      desc 'pipelines', 'list recent pipelines for this project (API v2)'
      method_option :branch, desc: 'branch name'
      def pipelines
        validate_token!
        query = {}
        query[:branch] = options[:branch] if options[:branch]
        items = api.get_paged("/project/#{repo.project_slug}/pipeline", query, max_pages: 1)
        abort! 'No pipelines found.' if items.empty?

        print_table items.map { |pipeline|
          number = pipeline['number'].to_s
          branch = pipeline.fetch('vcs', {})['branch'].to_s
          actor  = pipeline.fetch('trigger', {}).fetch('actor', {})['login'].to_s
          [number, branch, actor]
        }
      rescue ApiError => e
        abort! e.message
      end

      desc 'projects', 'discover the current project slug and your collaborations (API v2)'
      method_option :json, type: :boolean, default: false,
                           desc: 'emit JSON instead of a human-readable table'
      def projects
        validate_token!
        slug = repo.project_slug
        collaborations = Array(api.get('/me/collaborations'))

        if options[:json]
          say JSON.generate(current_project_slug: slug, collaborations: collaborations)
          return
        end

        say "Current repo project slug: #{slug}", :cyan
        if collaborations.empty?
          say "\nNo collaborations found for this token."
        else
          say "\nCollaborations:", :bold
          print_table collaborations.map { |collab|
            [collab['name'].to_s, collab['vcs-type'].to_s, collab['slug'].to_s]
          }
        end
      rescue ApiError => e
        abort! e.message
      end

      desc 'workflows PIPELINE_ID', 'list workflows for a pipeline (API v2)'
      def workflows(pipeline_id)
        validate_token!
        items = api.pipeline_workflows(pipeline_id)
        abort! 'No workflows found.' if items.empty?

        print_table items.map { |workflow|
          [
            workflow['name'].to_s,
            workflow['status'].to_s,
            workflow['id'].to_s,
            workflow['created_at'].to_s
          ]
        }
      rescue ApiError => e
        abort! e.message
      end

      desc 'jobs WORKFLOW_ID', 'list jobs for a workflow (API v2)'
      def jobs(workflow_id)
        validate_token!
        items = api.workflow_jobs(workflow_id)
        abort! 'No jobs found.' if items.empty?

        print_table items.map { |job|
          [
            job['name'].to_s,
            job['status'].to_s,
            job['job_number'].to_s,
            job['id'].to_s,
            job_duration(job)
          ]
        }
      rescue ApiError => e
        abort! e.message
      end

      desc 'login', 'login to CircleCI'
      def login
        say LOGIN_HELP, :yellow
        ask set_color("\nPress [enter] to open CircleCI", :blue)
        Launchy.open(CIRCLE_URL)
        value = ask set_color('Enter your token:', :blue), echo: false
        abort! 'No token was entered.' if value.nil? || value.strip.empty?
        repo.circle_token = value
        say "\nYour CircleCI token has been saved.", :green
        announce_identity(value)
      end

      private

      def repo
        @repo ||= Repo.new(options)
      end

      def project
        @project ||= Project.new(repo)
      end

      def api
        @api ||= ApiClient.new(token: repo.circle_token)
      end

      def validate_token!
        abort! NO_TOKEN_MESSAGE unless repo.circle_token
      end

      def print_token_value
        if (value = repo.circle_token)
          say value
        else
          say NO_TOKEN_MESSAGE, :yellow
        end
      end

      # Confirms a freshly saved token against /me and prints the user identity.
      # Never echoes the token; a validation failure is a soft warning since the
      # token is already stored.
      def announce_identity(token)
        user = ApiClient.new(token: token).get('/me')
        say "Logged in as #{user['name'] || user['login']}.", :green
      rescue ApiError => e
        say "Token saved, but it could not be validated: #{e.message}", :yellow
      end

      def latest
        project.latest
      end

      # Human-readable run time for a v2 job, derived from its start/stop
      # timestamps. Returns '-' when the job has not produced both yet.
      def job_duration(job)
        started = job['started_at']
        stopped = job['stopped_at']
        return '-' unless started && stopped

        seconds = (Time.parse(stopped) - Time.parse(started)).to_i
        return '-' if seconds.negative?

        minutes, secs = seconds.divmod(60)
        hours, minutes = minutes.divmod(60)
        parts = []
        parts << "#{hours}h" unless hours.zero?
        parts << "#{minutes}m" unless minutes.zero?
        parts << "#{secs}s" if parts.empty? || !secs.zero?
        parts.join(' ')
      rescue ArgumentError, TypeError
        '-'
      end

      def dashboard_width
        options[:width] || (IO.console && IO.console.winsize[1]) || 80
      rescue SystemCallError
        80
      end

      def validate_repo!
        abort! "Unsupported repo url format #{repo.uri}" unless repo.uri.github?
        validate_token!
      end

      def validate_latest!
        abort! 'No CircleCI builds found.' unless project.latest
      end

      def abort!(message)
        abort set_color(message, :red)
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
