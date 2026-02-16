Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions: "users/sessions"
  }

  get "up" => "rails/health#show", as: :rails_health_check

  # -------------------------------------------------------
  # オンボーディング
  # -------------------------------------------------------
  get "onboardings/welcome", to: "onboardings#welcome", as: :onboardings_welcome
  get "onboardings/about",   to: "onboardings#about",   as: :onboardings_about

  get  "/onboarding",          to: "onboardings#welcome",  as: :onboarding
  get  "/onboarding/about",    to: "onboardings#about",    as: :onboarding_about
  post "/onboarding/complete", to: "onboardings#complete", as: :complete_onboarding

  # -------------------------------------------------------
  # アプリのトップ
  # -------------------------------------------------------
  get "top/index"
  root "top#index"

  get "/others", to: "others#index", as: :others

  # -------------------------------------------------------
  # ソーシャルタイプ診断
  # -------------------------------------------------------
  get  "/diagnosis",              to: "diagnoses#top",         as: :diagnosis_top
  get  "/diagnosis/questions",    to: "diagnoses#questions",   as: :diagnosis_questions
  post "/diagnosis/result",       to: "diagnoses#result",      as: :diagnosis_result
  get  "/diagnosis/result/:type", to: "diagnoses#result_page", as: :diagnosis_result_page
  get  "/diagnosis/share/:type",  to: "diagnoses#share",       as: :diagnosis_share

  # -------------------------------------------------------
  # 応対評価
  # -------------------------------------------------------
  post "ai_messages/:ai_message_id/feedback",
       to: "ai_message_feedbacks#create",
       as: :ai_message_feedback

  # -------------------------------------------------------
  # 投稿
  # -------------------------------------------------------
  resources :posts, only: [ :index, :edit, :update, :destroy ] do
    post :preview_ai, on: :member
    resource :favorite, only: %i[create destroy]
  end

  # -------------------------------------------------------
  # バディと話す（新規 & トピック別）
  # -------------------------------------------------------
  get  "/buddy_talk",       to: "buddy_talks#show",  as: :buddy_talk
  post "/buddy_talk/start", to: "buddy_talks#start", as: :start_buddy_talk

  get "/buddy_talks/new", to: "buddy_talks#show", as: :new_buddy_talk

  get  "/buddy_talks/:id",                 to: "buddy_talks#topic",          as: :buddy_talk_topic
  post "/buddy_talks/:id/reply",           to: "buddy_talks#reply",          as: :reply_buddy_talk
  post "/buddy_talks/:id/deep_dive",       to: "buddy_talks#deep_dive",      as: :deep_dive_buddy_talk
  post "/buddy_talks/:id/summary",         to: "buddy_talks#summary",        as: :summary_buddy_talk
  post "/buddy_talks/:id/praise_summary",  to: "buddy_talks#praise_summary", as: :praise_summary_buddy_talk

  post "/buddy_talks/:id/restart", to: "buddy_talks#restart", as: :restart_buddy_talk
  post "/buddy_talks/:id/close",   to: "buddy_talks#close",   as: :close_buddy_talk

  # -------------------------------------------------------
  # バディ
  # -------------------------------------------------------
  resources :buddies, only: [ :index ] do
    post :select, on: :member
  end

  # -------------------------------------------------------
  # 分析
  # -------------------------------------------------------
  resource :analytics, only: [ :show ] do
    post :generate_feedback
  end

  # -------------------------------------------------------
  # 利用規約/プライバシーポリシー
  # -------------------------------------------------------
  get "/terms",   to: "static_pages#terms",   as: :terms
  get "/privacy", to: "static_pages#privacy", as: :privacy

  # -------------------------------------------------------
  # あなたの頑張りの証（バッジ機能）
  # -------------------------------------------------------
  resources :badges, only: %i[index show]

  # -------------------------------------------------------
  # ユーザー設定
  # -------------------------------------------------------
  resource :account_setting, only: %i[show]

  # -------------------------------------------------------
  # お問い合わせフォーム
  # -------------------------------------------------------
  resource :contact, only: %i[new create], path: "contact", path_names: { new: "" }
end
