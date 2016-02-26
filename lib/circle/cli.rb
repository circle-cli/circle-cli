require 'circle/cli/version'
require 'circle/cli/app'
require 'circle/cli/repo'

module Circle
  module CLI
    def self.run(*args)
      App.new.dispatch!(*args)
    end
  end
end
