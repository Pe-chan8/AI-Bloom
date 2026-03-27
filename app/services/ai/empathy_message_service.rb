# frozen_string_literal: true

module Ai
  class EmpathyMessageService
    RECENT_TURNS  = ENV.fetch("AI_RECENT_TURNS", 1).to_i
    MAX_LOG_CHARS = ENV.fetch("AI_MAX_LOG_CHARS", 500).to_i

    MODEL       = ENV.fetch("AI_MODEL", "gpt-4o-mini")
    TEMPERATURE = ENV.fetch("AI_TEMPERATURE", 0.65).to_f
    MAX_TOKENS  = ENV.fetch("AI_REPLY_MAX_TOKENS", 350).to_i

    def initialize(client: OpenAI::Client.new)
      @client = client
    end

    def generate_for(post:, user:, buddy: nil)
      buddy ||= user.buddy

      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      recent_log = build_recent_log(post)
      t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      messages = Ai::PromptBuilder.build_buddy_reply(
        user: user,
        buddy: buddy,
        post: post,
        recent_log: recent_log
      )

      system_msg = messages.find { |m| m[:role].to_s == "system" } || {}
      system_txt = system_msg[:content].to_s

      Rails.logger.warn(
        "[AI_DEBUG] post=#{post.id} buddy_id=#{buddy&.id} buddy_code=#{buddy&.code} " \
        "system_len=#{system_txt.length} " \
        "system_head=#{system_txt.first(240).inspect} " \
        "system_tail=#{system_txt.last(240).inspect}"
      )

      t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response = @client.chat(
        parameters: {
          model: MODEL,
          messages: messages,
          temperature: TEMPERATURE,
          max_tokens: MAX_TOKENS
        }
      )
      t3 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      raw     = response.dig("choices", 0, "message", "content").to_s
      cleaned = raw.strip

      ai_message = AiMessage.create!(
        user: user,
        buddy: buddy,
        post: post,
        kind: :reply,
        content: cleaned
      )
      t4 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      AiLog.create!(
        user: user,
        post: post,
        ai_message: ai_message,
        provider: "openai",
        model: MODEL,
        prompt_tokens: response.dig("usage", "prompt_tokens"),
        completion_tokens: response.dig("usage", "completion_tokens"),
        total_tokens: response.dig("usage", "total_tokens"),
        latency_ms: ((t3 - t2) * 1000).round,
        status: :success,
        requested_at: Time.current,
        responded_at: Time.current
      )
      t5 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      Rails.logger.info(
        "[AI-SPEED] " \
        "A(log)=#{((t1 - t0) * 1000).round}ms " \
        "B(prompt)=#{((t2 - t1) * 1000).round}ms " \
        "C(openai)=#{((t3 - t2) * 1000).round}ms " \
        "D(save)=#{((t4 - t3) * 1000).round}ms " \
        "E(ailog)=#{((t5 - t4) * 1000).round}ms " \
        "TOTAL=#{((t5 - t0) * 1000).round}ms"
      )

      cleaned
    rescue => e
      Rails.logger.error("[AI ERROR] #{e.class} #{e.message}")
      fallback_message
    end

    private

    # UIと同じ：BuddyMessageだけから会話ログを作る
    def build_recent_log(post)
      limit = RECENT_TURNS * 2

      rows =
        BuddyMessage.where(post: post)
                  .order(created_at: :asc)
                  .last(limit)
                  .map do |m|
                     prefix = (m.role.to_s == "ai") ? "AI:" : "USER:"
                     "#{prefix} #{m.content}"
                   end

      text = rows.join("\n")
      text = text.last(MAX_LOG_CHARS) if text.length > MAX_LOG_CHARS
      text
    end

    def fallback_message
      "いま少し混み合っています…少し時間をおいてみてね🙏"
    end
  end
end
