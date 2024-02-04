require "bundler/setup"

require "pry"
require "pry-byebug"

require "foobara/load_dotenv"

# TODO: setup boot pattern here
Foobara::LoadDotenv.run!

require "foobara/resque_scheduler_connector"

redis_url = ENV.fetch("REDIS_URL", nil)

unless ENV["REDIS_URL"]
  raise NoRedisUrlError,
        'Must set ENV["REDIS_URL"] if trying to initialize RedisCrudDriver with no arguments'
end

Resque.redis = Redis.new(url: ENV.fetch("REDIS_URL", nil))
