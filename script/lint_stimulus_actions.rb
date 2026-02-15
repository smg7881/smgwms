#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

ROOT = Pathname.new(__dir__).join("..").expand_path

Rule = Struct.new(:file, :required_patterns, :description, keyword_init: true)

RULES = [
  Rule.new(
    file: "app/views/shared/search_form/_form.html.erb",
    required_patterns: [
      /submit->search-form#search/
    ],
    description: "Search form actions"
  ),
  Rule.new(
    file: "app/views/shared/search_form/_buttons.html.erb",
    required_patterns: [
      /search-form#reset/,
      /search-form#toggleCollapse/
    ],
    description: "Search form button actions"
  ),
  Rule.new(
    file: "app/views/shared/resource_form/_form.html.erb",
    required_patterns: [
      /submit->resource-form#submit/
    ],
    description: "Resource form submit action"
  ),
  Rule.new(
    file: "app/views/shared/_tab_bar.html.erb",
    required_patterns: [
      /click->tabs#activateTab/,
      /click->tabs#closeTab:stop/
    ],
    description: "Tab bar actions"
  ),
  Rule.new(
    file: "app/views/shared/_sidebar.html.erb",
    required_patterns: [
      /click->sidebar#toggleTree/
    ],
    description: "Sidebar tree toggle action"
  ),
  Rule.new(
    file: "app/helpers/sidebar_helper.rb",
    required_patterns: [
      /click->tabs#openTab/
    ],
    description: "Sidebar menu open tab action"
  )
].freeze

errors = []

RULES.each do |rule|
  path = ROOT.join(rule.file)
  unless path.exist?
    errors << "[MISSING FILE] #{rule.file} (#{rule.description})"
    next
  end

  content = path.read
  rule.required_patterns.each do |pattern|
    next if content.match?(pattern)

    errors << "[MISSING ACTION] #{rule.file}: #{pattern.inspect} (#{rule.description})"
  end
end

# Generic scan: every template that declares search-form/resource-form controller
# should have at least one matching action in that same file.
generic_targets = {
  /data-controller="[^"]*\bsearch-form\b[^"]*"/ => /search-form#/,
  /data-controller="[^"]*\bresource-form\b[^"]*"/ => /resource-form#/
}.freeze

Dir.glob(ROOT.join("app/views/**/*.erb")).sort.each do |file|
  content = File.read(file)
  generic_targets.each do |controller_pattern, action_pattern|
    next unless content.match?(controller_pattern)
    next if content.match?(action_pattern)

    errors << "[MISSING ACTION] #{Pathname.new(file).relative_path_from(ROOT)}: expected #{action_pattern.inspect} when controller is present"
  end
end

if errors.empty?
  puts "Stimulus action lint passed."
  exit 0
end

puts "Stimulus action lint failed:"
errors.each { |error| puts " - #{error}" }
exit 1
