module Ai
  class PromptRepository
    CONFIG_PATH = Rails.root.join("config", "prompts.yml")

    # メモリにキャッシュしておく
    def self.config
      @config ||= YAML.load_file(CONFIG_PATH, aliases: true).deep_symbolize_keys
    end

    def self.for(type)
      type_key = type.to_s.downcase.to_sym
      config.fetch(type_key) { config.fetch(:default) }
    end
  end
end
