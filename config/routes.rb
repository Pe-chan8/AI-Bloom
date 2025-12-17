Rails.application.routes.draw do
  # 認証
  devise_for :users, controllers: { sessions: "users/sessions" }

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # -------------------------------------------------------
  # オンボーディング
  # -------------------------------------------------------

  # CI/テスト互換（onboardings_welcome_url / onboardings_about_url を復活）
  get "onboardings/welcome", to: "onboardings#welcome", as: :onboardings_welcome
  get "onboardings/about",   to: "onboardings#about",   as: :onboardings_about

  # アプリ内で使うルート（あなたの現状維持）
  get  "/onboarding",          to: "onboardings#welcome",  as: :onboarding
  get  "/onboarding/about",    to: "onboardings#about",    as: :onboarding_about
  post "/onboarding/complete", to: "onboardings#complete", as: :complete_onboarding

  # -------------------------------------------------------
  # アプリのトップ
  # -------------------------------------------------------
  get "top/index"
  root "top#index"

  # その他
  get "/others", to: "others#index", as: :others

  # ソーシャルタイプ診断
  get  "/diagnosis",            to: "diagnoses#top",       as: :diagnosis_top
  get  "/diagnosis/questions",  to: "diagnoses#questions", as: :diagnosis_questions
  post "/diagnosis/result",     to: "diagnoses#result",    as: :diagnosis_result

  # 応対評価
  post "ai_messages/:ai_message_id/feedback",
       to: "ai_message_feedbacks#create",
       as: :ai_message_feedback

  # 投稿関連
  resources :posts, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    post :preview_ai, on: :member
  end

  # バディ関連
  resources :buddies, only: [:index] do
    post :select, on: :member
  end
end
