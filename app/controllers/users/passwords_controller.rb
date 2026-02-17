module Users
  class PasswordsController < Devise::PasswordsController
    # 送信後に「送ったよ」ページへ行く
    def after_sending_reset_password_instructions_path_for(_resource_name)
      new_user_session_path
    end

    # 再設定完了後の遷移
    def after_resetting_password_path_for(_resource)
      new_user_session_path
    end
  end
end
