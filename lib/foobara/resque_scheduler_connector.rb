require "foobara/all"
require "foobara/resque_connector"
require "resque-scheduler"

module Foobara
  module ResqueSchedulerConnector
    class << self
      def reset_all
        # TODO: protect against this in production
        ResqueConnector.reset_all
      end
    end
  end
end

Foobara::Util.require_directory("#{__dir__}/../../src")
