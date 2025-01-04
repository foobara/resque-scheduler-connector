require_relative "version"

local_ruby_version = File.read("#{__dir__}/.ruby-version").chomp
local_ruby_version_minor = local_ruby_version[/\A(\d+\.\d+)\.\d+\z/, 1]
minimum_ruby_version = "#{local_ruby_version_minor}.0"

Gem::Specification.new do |spec|
  spec.name = "foobara-resque-scheduler-connector"
  spec.version = Foobara::ResqueSchedulerConnector::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "Connects Foobara commands to resque-scheduler"
  spec.homepage = "https://github.com/foobara/resque-scheduler-connector"
  spec.license = "MPL-2.0"
  spec.required_ruby_version = ">= #{minimum_ruby_version}"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "src/**/*",
    "LICENSE*.txt",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.add_dependency "foobara"
  spec.add_dependency "resque-scheduler"

  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
