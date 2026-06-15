module Circle
  module CLI
    module TUI
      # Central mapping from CircleCI status strings to a colour, a status
      # glyph (with an ASCII fallback for terminals/locales without unicode),
      # and a human-readable label. Kept dependency-free so it can be reused by
      # the renderer, the legacy v1 views, or future machine-readable output.
      module Status
        # status => [color, unicode icon, ascii icon]
        TABLE = {
          'success'             => [:green,  '✔', 'ok'],
          'fixed'               => [:green,  '✔', 'ok'],
          'passed'              => [:green,  '✔', 'ok'],
          'running'             => [:yellow, '▶', '>'],
          'queued'              => [:yellow, '◷', '~'],
          'scheduled'           => [:yellow, '◷', '~'],
          'not_running'         => [:yellow, '◷', '~'],
          'failed'              => [:red,    '✖', 'x'],
          'failing'             => [:red,    '✖', 'x'],
          'error'               => [:red,    '✖', 'x'],
          'timedout'            => [:red,    '✖', 'x'],
          'infrastructure_fail' => [:red,    '✖', 'x'],
          'canceled'            => [:red,    '⊘', '/'],
          'on_hold'             => [:blue,   '⏸', '='],
          'blocked'             => [:blue,   '⏸', '='],
          'not_run'             => [:blue,   '○', '-']
        }.freeze

        DEFAULT = [:blue, '•', '*'].freeze

        def self.entry(status)
          TABLE.fetch(normalize(status), DEFAULT)
        end

        def self.color_for(status)
          entry(status)[0]
        end

        def self.icon_for(status, unicode: true)
          entry(status)[unicode ? 1 : 2]
        end

        def self.label_for(status)
          return 'Unknown' if status.nil?
          normalize(status).tr('_', ' ').capitalize
        end

        def self.normalize(status)
          status.to_s
        end
        private_class_method :normalize
      end
    end
  end
end
