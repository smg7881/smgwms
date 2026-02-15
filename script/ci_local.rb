#!/usr/bin/env ruby
# frozen_string_literal: true

require "rbconfig"

ruby = RbConfig.ruby
root = File.expand_path("..", __dir__)
Dir.chdir(root)

options = {
  fast: false,
  no_system: false
}

ARGV.each do |arg|
  case arg
  when "--fast"
    options[:fast] = true
    options[:no_system] = true
  when "--no-system"
    options[:no_system] = true
  when "--help", "-h"
    puts <<~HELP
      Usage: ruby bin/ci-local [--fast] [--no-system]

      Options:
        --fast       Run quick checks only (skip system test)
        --no-system  Skip system test only
    HELP
    exit 0
  else
    warn "Unknown option: #{arg}"
    exit 1
  end
end

steps = []

if options[:fast]
  steps << [ "Stimulus action lint", [ ruby, "bin/lint-stimulus-actions" ] ]
  steps << [ "RuboCop", [ ruby, "bin/rubocop", "-f", "github" ] ]
  steps << [ "Rails test", [ ruby, "bin/rails", "db:test:prepare", "test" ] ]
else
  steps << [ "Brakeman", [ ruby, "bin/brakeman", "--no-pager" ] ]
  steps << [ "Bundler Audit", [ ruby, "bin/bundler-audit" ] ]
  steps << [ "Importmap Audit", [ ruby, "bin/importmap", "audit" ] ]
  steps << [ "RuboCop", [ ruby, "bin/rubocop", "-f", "github" ] ]
  steps << [ "Stimulus action lint", [ ruby, "bin/lint-stimulus-actions" ] ]
  steps << [ "Rails test", [ ruby, "bin/rails", "db:test:prepare", "test" ] ]
end

unless options[:no_system]
  steps << [ "Rails system test", [ ruby, "bin/rails", "db:test:prepare", "test:system" ] ]
end

puts "Running local CI checks..."

steps.each_with_index do |(name, command), index|
  puts "\n[#{index + 1}/#{steps.size}] #{name}"
  puts ">> #{command.join(' ')}"

  ok = system(*command)
  unless ok
    puts "\nFAILED: #{name}"
    exit($CHILD_STATUS&.exitstatus || 1)
  end

  puts "OK: #{name}"
end

puts "\nAll local CI checks passed."
