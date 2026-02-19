# frozen_string_literal: true

module Ai
  class PromptRepository
    CONFIG_PATH = Rails.root.join("config", "ai", "prompts.yml")
    DEFAULT_LOCALE = :ja

    class << self
      def config
        @config ||= YAML.load_file(CONFIG_PATH, aliases: true).deep_symbolize_keys
      end

      def base_system(locale: DEFAULT_LOCALE)
        config.fetch(locale.to_sym).dig(:base, :system).to_s
      end

      def system_for(type:, user_nickname: nil, buddy: nil, locale: DEFAULT_LOCALE)
        cfg = config.fetch(locale.to_sym)

        base = cfg.dig(:base, :system).to_s

        nickname   = user_nickname.presence || "あなた"
        buddy_name = buddy&.respond_to?(:name) && buddy.name.present? ? buddy.name : "バディ"

        buddy_system =
          if buddy&.respond_to?(:persona_prompt) && buddy.persona_prompt.present?
            buddy.persona_prompt.to_s
          else
            ""
          end

        type_key = type.to_s.downcase.to_sym
        type_system =
          cfg.dig(type_key, :system).to_s.presence ||
          cfg.dig(:default, :system).to_s.presence ||
          ""

        merged =
          if buddy_system.present?
            "#{base}\n\n#{buddy_system}"
          elsif type_system.present?
            "#{base}\n\n#{type_system}"
          else
            base
          end

        system = format(
          merged,
          user_nickname: nickname,
          buddy_name: buddy_name
        )

        { system: system }
      rescue KeyError => e
        Rails.logger.warn("[PromptRepository] system_for failed: #{e.class} #{e.message}")
        { system: merged.to_s }
      rescue => e
        Rails.logger.error("[PromptRepository] system_for error: #{e.class} #{e.message}")
        { system: "" }
      end

      def for(type, user_nickname: nil, buddy: nil, locale: DEFAULT_LOCALE)
        system_for(type: type, user_nickname: user_nickname, buddy: buddy, locale: locale)
      end

      def user_template_for(key:, locale: DEFAULT_LOCALE)
        cfg = config.fetch(locale.to_sym)
        template = cfg.dig(key.to_sym, :user).to_s
        raise KeyError, "User prompt template not found: #{key}" if template.blank?
        template
      end
    end
  end
end
