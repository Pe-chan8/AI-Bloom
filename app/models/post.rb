class Post < ApplicationRecord
  belongs_to :user

  # 気分：nil 許可なら enum だけ定義（DB に default: 0 を入れていなければ nil もOK）
  enum :mood, { positive: 0, neutral: 1, negative: 2 }, prefix: true

  # 公開範囲：private / public
  # ※値は「private / public」のままでOK（prefix が visibility_ を付けてくれる）
  enum :visibility, { private: 0, public: 1 }, prefix: true
end
