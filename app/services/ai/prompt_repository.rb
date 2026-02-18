# frozen_string_literal: true

module Ai
  class PromptRepository
    CONFIG_PATH = Rails.root.join("config", "ai", "prompts.yml")
    DEFAULT_LOCALE = :ja

    def self.config
      @config ||= YAML.load_file(CONFIG_PATH, aliases: true).deep_symbolize_keys
    end

    def self.base_system(locale: DEFAULT_LOCALE)
      config.fetch(locale.to_sym).dig(:base, :system).to_s
    end

    # systemプロンプトを返す（バディ人格統合の要）
    #
    # 優先順位：
    # 1) buddy.persona_prompt があればそれを採用
    # 2) なければ type に応じた system（将来用）
    # 3) それもなければ base のみ
    #
    # return: { system: "..." }
    def self.system_for(type:, user_nickname: nil, buddy: nil, locale: DEFAULT_LOCALE)
      cfg = config.fetch(locale.to_sym)

      base = cfg.dig(:base, :system).to_s

      nickname  = user_nickname.presence || "あなた"
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

      # prompts.yml の "%{...}" を埋め込む
      system = format(
        merged,
        user_nickname: nickname,
        buddy_name: buddy_name
      )

      { system: system }
    rescue KeyError => e
      # もし prompts.yml 側に想定外の %{xxx} が入ってても落ちないようにする保険
      Rails.logger.warn("[PromptRepository] format failed: #{e.message}")
      { system: merged }
    end

    # userプロンプトのテンプレ文字列を返す
    def self.user_template_for(key:, locale: DEFAULT_LOCALE)
      cfg = config.fetch(locale.to_sym)
      template = cfg.dig(key.to_sym, :user).to_s
      raise KeyError, "User prompt template not found: #{key}" if template.blank?
      template
    end
  end
end
