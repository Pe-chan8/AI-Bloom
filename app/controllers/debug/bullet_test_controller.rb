class Debug::BulletTestController < ApplicationController
  def index
    msgs = AiMessage.limit(30) # includesしない
    msgs.each { |m| m.buddy&.id } # ここで N+1 が起きる
    render plain: "ok"
  end
end
