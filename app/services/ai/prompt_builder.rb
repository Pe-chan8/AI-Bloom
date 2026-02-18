# frozen_string_literal: true

module Ai
  class PromptBuilder
    DEFAULT_LOCALE = :ja

    def self.build_buddy_reply(user:, buddy:, post:, recent_log:, locale: DEFAULT_LOCALE)
      type = prompt_type_for(user: user, buddy: buddy)

      system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

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

      system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

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

      system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

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

      system = Ai::PromptRepository.system_for(
        type: type,
        user_nickname: user.nickname,
        buddy: buddy,
        locale: locale
      ).fetch(:system)

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
