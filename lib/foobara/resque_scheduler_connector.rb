require "foobara/all"
require "foobara/command_connectors"

module Foobara
  module ResqueSchedulerConnector
    class << self
      def reset_all
        # TODO: protect against this in production
        Resque.redis.flushdb
      end
    end
  end
end

Foobara::Util.require_directory("#{__dir__}/../../src")
