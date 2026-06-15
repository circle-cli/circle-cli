require 'time'
require 'pastel'
require 'circle/cli/tui/status'

module Circle
  module CLI
    module TUI
      # Renders the pipeline -> workflow -> job hierarchy into a string.
      #
      # The renderer is pure: it takes plain data and options and returns a
      # String, so it is trivial to test and never touches the network. Colour
      # is applied through Pastel (which no-ops when disabled, keeping output
      # script-safe), width is enforced per-line so narrow terminals degrade
      # gracefully, and every glyph has an ASCII fallback.
      class DashboardRenderer
        TIME_FORMAT = '%-b %-e, %-l:%M %p'.freeze
        BOX_MIN_WIDTH = 32 # below this we drop the header box for a plain line

        def initialize(data, options = nil, color: true, width: 80, unicode: true)
          if options
            color = options.fetch(:color, color)
            width = options.fetch(:width, width)
            unicode = options.fetch(:unicode, unicode)
          end

          @data = data || {}
          @color = color
          @unicode = unicode
          @width = width.to_i
          @width = 80 if @width <= 0
          @pastel = Pastel.new(enabled: color)
        end

        def render
          lines = header_lines
          pipelines = @data[:pipelines] || []
          if pipelines.empty?
            lines << compose([['No recent pipelines.', :bright_black]], indent: 2)
          else
            pipelines.each { |pipeline| lines.concat(pipeline_lines(pipeline)) }
          end
          lines.join("\n")
        end

        private

        # ----- sections -------------------------------------------------------

        def header_lines
          project = @data[:project].to_s
          branch  = @data[:branch].to_s

          if @width < BOX_MIN_WIDTH
            branch_width = [branch.length, @width / 3].min
            project_width = @width - branch_width - 2
            return [compose([
              [truncate_plain(project, project_width), [:bold, :cyan]],
              ['  '],
              [truncate_plain(branch, branch_width), :magenta]
            ])]
          end

          inner = @width - 4
          ptitle = truncate_plain(project, inner)
          pbranch = truncate_plain(branch, [inner - ptitle.length - 1, 0].max)
          gap = inner - ptitle.length - pbranch.length
          gap = 1 if gap < 1

          [
            box_chars[:tl] + (box_chars[:h] * (@width - 2)) + box_chars[:tr],
            box_chars[:v] + ' ' + paint(ptitle, [:bold, :cyan]) +
              (' ' * gap) + paint(pbranch, :magenta) + ' ' + box_chars[:v],
            box_chars[:bl] + (box_chars[:h] * (@width - 2)) + box_chars[:br]
          ]
        end

        def pipeline_lines(pipeline)
          vcs = pipeline[:vcs] || {}
          revision = vcs[:revision].to_s[0, 7]
          lines = ['']

          lines << compose([
            ["Pipeline ##{pipeline[:number]}", :bold],
            ['  '],
            [revision, :yellow],
            ['  '],
            [vcs[:subject].to_s, :white]
          ])

          meta = []
          meta << vcs[:author] if vcs[:author]
          meta << format_time(pipeline[:created_at]) if pipeline[:created_at]
          unless meta.empty?
            lines << compose([[meta.compact.join('  ·  '), :bright_black]], indent: 2)
          end

          (pipeline[:workflows] || []).each do |workflow|
            lines.concat(workflow_lines(workflow))
          end
          lines
        end

        def workflow_lines(workflow)
          status = workflow[:status]
          color  = Status.color_for(status)
          jobs   = workflow[:jobs] || []

          lines = [compose([
            [Status.icon_for(status, unicode: @unicode) + ' ', color],
            [workflow[:name].to_s, :bold],
            ['  '],
            [Status.label_for(status), color],
            ['  '],
            [job_summary(jobs), :bright_black]
          ], indent: 2)]

          jobs.each { |job| lines << job_line(job) }
          lines
        end

        def job_line(job)
          status = job[:status]
          color  = Status.color_for(status)
          duration = format_duration(job[:duration_ms])

          segments = [
            [Status.icon_for(status, unicode: @unicode) + ' ', color],
            [job[:name].to_s, nil],
            ['  '],
            [Status.label_for(status), color]
          ]
          segments += [['  '], [duration, :bright_black]] if duration
          compose(segments, indent: 6)
        end

        # ----- helpers --------------------------------------------------------

        def job_summary(jobs)
          done = jobs.count { |j| Status.color_for(j[:status]) == :green }
          "#{done}/#{jobs.size} jobs"
        end

        # Builds a single line from [text, style] segments, never exceeding the
        # configured width. Truncation happens on the plain text so colour codes
        # don't throw off the measurement.
        def compose(segments, indent: 0)
          budget = @width - indent
          return ' ' * @width if budget <= 0

          out = ''
          used = 0
          segments.each do |segment|
            text = segment[0].to_s
            style = segment[1]
            break if used >= budget

            remaining = budget - used
            if text.length > remaining
              text = truncate_plain(text, remaining)
              out << paint(text, style)
              break
            end
            out << paint(text, style)
            used += text.length
          end
          (' ' * indent) + out
        end

        def truncate_plain(str, max)
          str = str.to_s
          return '' if max <= 0
          return str if str.length <= max
          return ellipsis if max < 2
          str[0, max - 1] + ellipsis
        end

        def paint(text, style)
          return text if style.nil? || !@color
          @pastel.decorate(text, *Array(style))
        end

        def ellipsis
          @unicode ? '…' : '~'
        end

        def box_chars
          @box_chars ||= if @unicode
            { tl: '╭', tr: '╮', bl: '╰', br: '╯', h: '─', v: '│' }
          else
            { tl: '+', tr: '+', bl: '+', br: '+', h: '-', v: '|' }
          end
        end

        def format_time(value)
          Time.parse(value.to_s).strftime(TIME_FORMAT)
        rescue ArgumentError, TypeError
          nil
        end

        def format_duration(ms)
          return nil unless ms

          hours   = (ms / (1000 * 60 * 60)) % 24
          minutes = (ms / (1000 * 60)) % 60
          seconds = (ms / 1000) % 60

          parts = []
          parts << "#{hours}h" unless hours.zero?
          parts << "#{minutes}m" unless minutes.zero?
          parts << "#{seconds}s" unless seconds.zero?
          parts << "#{ms}ms" if parts.empty?
          parts.join(' ')
        end
      end
    end
  end
end
