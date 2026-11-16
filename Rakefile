require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

namespace :lint do
  desc "Check README.md line lengths"
  task :readme do
    maximum_line_length = 120
    standalone_markdown_link = /\A\[[^\]]+\]\(\S+\)[.!?]?\z/

    violations = File.foreach("README.md", chomp: true).with_index(1).filter_map do |line, line_number|
      next if line.length <= maximum_line_length
      next if line.match?(standalone_markdown_link)

      [line_number, line.length]
    end

    next if violations.empty?

    violations.each do |line_number, line_length|
      warn "README.md:#{line_number}: line is #{line_length} characters (maximum is #{maximum_line_length})"
    end

    abort "README.md line length check failed"
  end
end

task default: [:spec, :rubocop, "lint:readme"]
