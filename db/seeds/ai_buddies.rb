# frozen_string_literal: true

yaml_path = Rails.root.join("config", "ai", "buddies.yml")
cfg = YAML.load_file(yaml_path, aliases: true).deep_symbolize_keys

buddies = cfg.dig(:ja, :buddies) || {}
raise "buddies.yml is empty" if buddies.empty?

buddies.each do |code, attrs|
  buddy = Buddy.find_or_initialize_by(code: code.to_s)

  buddy.name = attrs[:name].to_s if buddy.name.blank? && attrs[:name].present?

  buddy.persona_prompt = attrs[:persona_prompt].to_s

  buddy.save!
end

puts "Seeded buddies persona_prompt from #{yaml_path}"
