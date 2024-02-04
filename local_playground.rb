require "bundler/setup"

require "pry"
require "pry-byebug"

require "foobara/resque_scheduler_connector"

if ENV["REDIS_URL"]
  Resque.redis = Redis.new(url: ENV["REDIS_URL"])
  puts Resque.schedule = {}
else
  raise NoRedisUrlError,
        'Must set ENV["REDIS_URL"] if trying to initialize RedisCrudDriver with no arguments'
end
