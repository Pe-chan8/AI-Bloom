# frozen_string_literal: true

require "yaml"

path = Rails.root.join("config", "ai", "diagnosis_questions.yml")
data = YAML.load_file(path).deep_symbolize_keys

questions = data.dig(:ja, :questions) || []
raise "diagnosis_questions.yml is empty" if questions.empty?

valid_categories = %w[expressive driving amiable analytical].freeze

# YAML順で position を 1..n で自動採番
rows =
  questions.each_with_index.map do |q, idx|
    category = q[:category].to_s
    content  = q[:content].to_s.strip

    raise "category missing at index=#{idx}" if category.blank?
    raise "invalid category: #{category} at index=#{idx}" unless valid_categories.include?(category)
    raise "content missing at index=#{idx}" if content.blank?

    {
      position: idx + 1,
      category: category,
      content:  content,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

DiagnosisQuestion.delete_all
DiagnosisQuestion.insert_all!(rows)

puts "Seeded diagnosis questions: #{DiagnosisQuestion.count} (from #{path})"
