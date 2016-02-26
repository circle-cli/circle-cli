require 'thor'
require 'circle/cli/version'
require 'circle/cli/app'

module Circle
  module CLI
    def self.run(*args)
      App.start(*args)
    end
  end
end
