#!/usr/bin/env ruby
# frozen_string_literal: true

DOC_PATHS = [
  ".agents/skills/master-detail-screen-pattern/SKILL.md",
  ".agents/skills/master-detail-screen-pattern/references/master-detail-checklist.md",
  ".agents/skills/master-detail-screen-pattern/references/master-detail-scaffold.md"
].freeze

STANDARD_TERMS_HEADING = "## Standard Terms"
MANDATORY_GATE_HEADING = "## Mandatory Gate (Required)"

STANDARD_TERM_TOKENS = [
  "Contract Registry",
  "Contract Test",
  "PR Gate"
].freeze

MANDATORY_GATE_TOKENS = [
  "master_detail_screen_contracts.yml",
  "master_detail_pattern_contract_test.rb",
  "wm:contracts:master_detail",
  ".github/PULL_REQUEST_TEMPLATE.md",
  ".github/CODEOWNERS"
].freeze

errors = []

def extract_section(content, heading)
  lines = content.lines
  start_index = lines.find_index { |line| line.strip == heading }
  return nil if start_index.nil?

  section_lines = []
  lines[(start_index + 1)..].each do |line|
    break if line.start_with?("## ")

    section_lines << line
  end
  section_lines.join
end

DOC_PATHS.each do |path|
  if !File.exist?(path)
    errors << "문서 파일이 없습니다: #{path}"
    next
  end

  content = File.read(path, encoding: "UTF-8")

  standard_section = extract_section(content, STANDARD_TERMS_HEADING)
  if standard_section.nil?
    errors << "#{path}: '#{STANDARD_TERMS_HEADING}' 섹션이 없습니다."
  else
    STANDARD_TERM_TOKENS.each do |token|
      if !standard_section.include?(token)
        errors << "#{path}: Standard Terms 섹션에 '#{token}'이 없습니다."
      end
    end
  end

  mandatory_section = extract_section(content, MANDATORY_GATE_HEADING)
  if mandatory_section.nil?
    errors << "#{path}: '#{MANDATORY_GATE_HEADING}' 섹션이 없습니다."
  else
    MANDATORY_GATE_TOKENS.each do |token|
      if !mandatory_section.include?(token)
        errors << "#{path}: Mandatory Gate 섹션에 '#{token}'이 없습니다."
      end
    end
  end
end

if errors.any?
  puts "[FAIL] master-detail skill 문서 동기화 검사 실패"
  errors.each do |error|
    puts "- #{error}"
  end
  exit 1
else
  puts "[PASS] master-detail skill 문서 동기화 검사 통과"
end
