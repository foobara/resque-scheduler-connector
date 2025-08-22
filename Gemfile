require_relative "version"

source "https://rubygems.org"
ruby Foobara::ResqueSchedulerConnector::MINIMUM_RUBY_VERSION

gemspec

# gem "foobara", path: "../foobara"
# gem "foobara-resque-connector", path: "../resque-connector"

group :development do
  gem "foobara-rubocop-rules", ">= 1.0.0"
end

group :test do
  gem "foobara-spec-helpers", "< 2.0.0"
  gem "pry"
  gem "pry-byebug"
  gem "rspec"
  gem "rspec-its"
  gem "simplecov"
end

group :development, :test do
  gem "foobara-dotenv-loader", "< 2.0.0"
  gem "guard-rspec"
  gem "rake"
  gem "rubocop-rake"
  gem "rubocop-rspec"
end
