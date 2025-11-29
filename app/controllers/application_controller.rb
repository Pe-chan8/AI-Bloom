class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_default_nav_type

  helper_method :current_buddy, :bottom_nav_key

  private

  # ▼ デフォルトのナビ種別をセット
  def set_default_nav_type
    @nav_type = :main
  end

  # ▼ 現在のバディを取得
  def current_buddy
    return @current_buddy if defined?(@current_buddy)

    @current_buddy =
      if current_user&.buddy
        current_user.buddy
      else
        Buddy.find_by(code: "normal")
      end
  end

  # ▼ 画面ごとに読み込むボトムナビを切り替えるキー
  def bottom_nav_key
    case controller_name
    when "diagnoses"
      # 診断フロー中は「ホーム＋診断」の2ボタン
      "diagnosis"
    when "buddies"
      # バディ選択画面：ホーム＋診断＋バディ
      "buddies"
    when "posts"
      # 投稿一覧：ホーム＋投稿＋深掘り＋自己分析
      "posts"
    when "others"
      # その他画面：ホーム＋その他 の2ボタン
      "others"
    when "top"
      # マイルーム（トップ画面）はメインの5ボタンナビ
      "main"
    else
      # それ以外の画面もひとまずメインナビに寄せる
      "main"
    end
  end
end
