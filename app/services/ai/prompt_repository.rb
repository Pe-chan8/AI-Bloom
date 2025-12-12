module Ai
  class PromptRepository
    CONFIG_PATH = Rails.root.join("config", "prompts.yml")

    def self.config
      @config ||= YAML.load_file(CONFIG_PATH, aliases: true).deep_symbolize_keys
    end

    def self.for(type, user_nickname: nil)
      type_key = type.to_s.downcase.to_sym
      prompt = config.fetch(type_key) { config.fetch(:default) }

      base_system = config.dig(:base, :system).to_s
      type_system = prompt[:system].to_s

      nickname = user_nickname.presence || "あなた"
      system = "#{base_system}\n\n#{type_system}".gsub("{user_nickname}", nickname)

      { system: system }
    end
  end
end
