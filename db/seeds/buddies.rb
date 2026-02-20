# frozen_string_literal: true

require "yaml"

path = Rails.root.join("config", "ai", "buddies.yml")
cfg  = YAML.load_file(path, aliases: true).deep_symbolize_keys
buddies = cfg.dig(:ja, :buddies) || {}

ActiveRecord::Base.transaction do
  buddies.each_value do |b|
    buddy = Buddy.find_or_initialize_by(code: b[:code])

    buddy.name         = b[:name]
    buddy.description  = b[:description]
    buddy.tone_hint    = b[:tone_hint]
    buddy.persona_prompt = b[:persona_prompt]

    buddy.save!
  end
end

puts "Buddies upserted: #{Buddy.count}"
