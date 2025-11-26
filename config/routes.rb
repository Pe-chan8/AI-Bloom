Rails.application.routes.draw do
  get "buddies/index"
  get "buddies/select"
  # 認証
  devise_for :users

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # アプリのトップ
  get "top/index"
  root "top#index"

  # ソーシャルタイプ診断
  get  "/diagnosis",            to: "diagnoses#top",       as: :diagnosis_top
  get  "/diagnosis/questions",  to: "diagnoses#questions", as: :diagnosis_questions
  post "/diagnosis/result",     to: "diagnoses#result",    as: :diagnosis_result

  # PWA 関連（使うときにコメントアウトを外す）
  # get "manifest"       => "rails/pwa#manifest",        as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker",  as: :pwa_service_worker

  # 投稿関連
  resources :posts, only: %i[index new create edit update destroy]

    # バディ関連
    resources :buddies, only: [ :index ] do
    post :select, on: :member
  end
end
