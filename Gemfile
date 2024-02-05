source "https://rubygems.org"
ruby File.read("#{__dir__}/.ruby-version")

gemspec

# TODO: move this to .gemspec
gem "foobara", git: "foobara", branch: "main"
gem "foobara-util", github: "foobara/util"
# If uncommenting the following for local development, you need to run: bundle config set local.foobara-util ../util
# gem "foobara-util", git: "foobara-util"

# Development dependencies go here
gem "foobara-dotenv-loader", github: "foobara/dotenv-loader"
# gem "foobara-dotenv-loader", path: "../dotenv-loader"
gem "foobara-resque-connector", github: "foobara/resque-connector"
# gem "foobara-resque-connector", path: "../resque-connector"
gem "foobara-rubocop-rules", github: "foobara/rubocop-rules"
gem "foobara-spec-helpers", github: "foobara/spec-helpers"
gem "guard-rspec"
gem "pry"
gem "pry-byebug"
gem "rack-test"
gem "rackup"
gem "rake"
gem "rspec"
gem "rspec-its"
gem "rubocop-rake"
gem "rubocop-rspec"
gem "simplecov"
