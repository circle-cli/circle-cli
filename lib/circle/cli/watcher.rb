module Circle
  module CLI
    class Watcher
      attr_reader :displayer, :preloader

      def initialize(&displayer)
        @displayer = displayer
        @preloader = -> {}
      end

      def to_preload(&preloader)
        @preloader = preloader
      end

      def preload
        preloader.call
      end

      def display
        displayer.call
      end

      def poll(polling_frequency)
        loop do
          display
          sleep polling_frequency
          preload
          clear
        end
      rescue Interrupt
        exit 0
      end

      private

      def clear
        system('clear') || system('cls')
      end
    end
  end
end
