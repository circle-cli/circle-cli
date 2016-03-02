module Circle
  module CLI
    class Model
      TIME_FORMAT = '%-b %-e, %-l:%M %p'

      STATUS_COLORS = {
        green: %w(fixed success),
        yellow: %w(running retried not_run queued scheduled not_running no_tests),
        red: %w(canceled infrastructure_fail timedout failed)
      }

      attr_reader :attributes

      def initialize(attributes = {})
        @attributes = attributes
      end

      def [](key)
        @attributes[key.to_s]
      end

      private

      def format_time(value)
        Time.parse(value).strftime(TIME_FORMAT) if value
      rescue ArgumentError
      end

      def color_for(value)
        case value
        when *STATUS_COLORS[:green] then :green
        when *STATUS_COLORS[:yellow] then :yellow
        when *STATUS_COLORS[:red] then :red
        else :blue
        end
      end

      def truncate(str, len = 50)
        str && str.length > len ? "#{str[0..(len - 4)]}..." : str
      end
    end
  end
end
