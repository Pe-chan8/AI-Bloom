# frozen_string_literal: true

module Ai
  class PromptBuilder
    DEFAULT_LOCALE = :ja

    SHORT_OUTPUT_RULE = <<~RULE
      ・回答は最大200文字
      ・段落は最大2つまで
      ・導入のあいさつは不要
      ・同じ言い回しを繰り返さない
      ・最後の「今日のひとこと」は書かない
      ・簡潔でやさしい語り口にする
    RULE

    def self.build_buddy_reply(user:, buddy:, post:, recent_log:, locale: DEFAULT_LOCALE)
      type = prompt_type_for(user: user, buddy: buddy)

      base_system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

      system = apply_short_rule_if_needed(base_system)

      user_tpl = Ai::PromptRepository.user_template_for(key: :buddy_reply, locale: locale)

      user_prompt = format(
        user_tpl,
        user_nickname: (user.nickname.presence || "あなた"),
        buddy_name: (buddy&.name.presence || "バディ"),
        recent_log: recent_log.to_s,
        post_body: post.body.to_s
      )

      [
        { role: "system", content: system },
        { role: "user", content: user_prompt }
      ]
    end

    def self.build_deep_dive_questions(user:, buddy:, post:, locale: DEFAULT_LOCALE)
      type = prompt_type_for(user: user, buddy: buddy)

      base_system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

      system = apply_short_rule_if_needed(base_system)

      user_tpl = Ai::PromptRepository.user_template_for(key: :deep_dive_questions, locale: locale)

      user_prompt = format(
        user_tpl,
        user_nickname: (user.nickname.presence || "あなた"),
        buddy_name: (buddy&.name.presence || "バディ"),
        post_body: post.body.to_s
      )

      [
        { role: "system", content: system },
        { role: "user", content: user_prompt }
      ]
    end

    def self.build_praise_summary(user:, buddy:, post:, locale: DEFAULT_LOCALE)
      type = prompt_type_for(user: user, buddy: buddy)

      base_system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

      system = apply_short_rule_if_needed(base_system)

      user_tpl = Ai::PromptRepository.user_template_for(key: :praise_summary, locale: locale)

      user_prompt = format(
        user_tpl,
        user_nickname: (user.nickname.presence || "あなた"),
        buddy_name: (buddy&.name.presence || "バディ"),
        post_body: post.body.to_s
      )

      [
        { role: "system", content: system },
        { role: "user", content: user_prompt }
      ]
    end

    def self.build_analysis_feedback(user:, buddy:, post:, locale: DEFAULT_LOCALE)
      type = prompt_type_for(user: user, buddy: buddy)

      base_system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

      system = apply_short_rule_if_needed(base_system)

      user_tpl = Ai::PromptRepository.user_template_for(key: :analysis_feedback, locale: locale)

      user_prompt = format(
        user_tpl,
        user_nickname: (user.nickname.presence || "あなた"),
        buddy_name: (buddy&.name.presence || "バディ"),
        post_body: post.body.to_s
      )

      [
        { role: "system", content: system },
        { role: "user", content: user_prompt }
      ]
    end

    def self.apply_short_rule_if_needed(system_text)
      enabled = ENV.fetch("AI_SHORT_OUTPUT", "0") == "1"
      return system_text unless enabled

      "#{system_text}\n\n#{SHORT_OUTPUT_RULE}"
    end
    private_class_method :apply_short_rule_if_needed

    def self.prompt_type_for(user:, buddy:)
      return buddy.code if buddy&.respond_to?(:code) && buddy.code.present?

      if user.respond_to?(:profile) && user.profile&.social_type.present?
        return user.profile.social_type
      end

      :default
    end
    private_class_method :prompt_type_for
  end
end
