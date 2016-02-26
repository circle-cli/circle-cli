module Circle
  module CLI
    class Token < Thor
      desc 'ci [TOKEN]', 'set or display CircleCI token'
      def ci(token = nil)
        manage_token :circle, token
      end

      desc 'github [TOKEN]', 'set or display Github token'
      def github(token = nil)
        manage_token :github, token
      end

      private

      def manage_token(name, token = nil)
        repo = Repo.new

        if token
          repo.send "#{name}_token=", token
        elsif token = repo.send("#{name}_token")
          say token
        else
          say repo.send("no_#{name}_token_message"), :yellow
        end
      end
    end
  end
end
