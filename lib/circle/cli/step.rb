require 'circle/cli/model'

module Circle
  module CLI
    class Step < Model
      def color
        color_for self[:actions].first['status']
      end

      def duration
        return unless ms = self[:run_time_millis]

        hours = (ms / (1000 * 60 * 60)) % 24
        minutes = (ms / (1000 * 60)) % 60
        seconds = (ms / 1000) % 60

        message = []
        message << "#{hours}h" unless hours.zero?
        message << "#{minutes}m" unless minutes.zero?
        message << "#{seconds}s" unless seconds.zero?
        message << "#{ms}ms" if message.empty?
        message.join(' ')
      end
    end
  end
end
