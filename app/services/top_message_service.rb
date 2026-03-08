# frozen_string_literal: true

class TopMessageService
  MESSAGE_PATTERNS = {
    "normal" => {
      no_posts: [
        "今日はどんな1日だった？よかったら少しだけ聞かせてね。",
        "まだ何も書いてなくても大丈夫。今の気持ちから少しずつでいいよ。"
      ],
      negative_trend: [
        "ちょっと疲れがたまってない？今日は無理しすぎないでね。",
        "最近しんどい日が続いてるかも。ここでは気を張らなくて大丈夫だよ。"
      ],
      positive_trend: [
        "最近いい流れが続いてるね。その調子でいこう。",
        "いいことが少しずつ増えてきたみたいで嬉しいね。"
      ],
      neutral_trend: [
        "最近の調子はどうかな？今日の気持ちも聞かせてね。",
        "大きな変化がなくても大丈夫。今の気分をそのまま残してみよう。"
      ]
    },
    "analytical" => {
      no_posts: [
        "まずは1件、今の状態を残してみましょう。小さな記録でも十分意味があります。",
        "まだデータがない状態ですね。今日の気分から、ひとつ記録してみませんか。"
      ],
      negative_trend: [
        "直近の気分を見ると、少し負荷が続いているようです。無理はしすぎないでくださいね。",
        "最近はやや低下傾向かもしれません。まずは休めるポイントを探してみましょう。"
      ],
      positive_trend: [
        "直近の記録を見ると、気分は上向きですね。よい変化が積み上がっていそうです。",
        "最近は比較的よい状態が続いていますね。この流れを大切にしたいですね。"
      ],
      neutral_trend: [
        "最近の状態は比較的安定していそうです。今日の気分も記録してみましょう。",
        "大きな波はなさそうですね。こういう時期の記録も後で役立ちますよ。"
      ]
    },
    "amiable" => {
      no_posts: [
        "まだ書けてなくても大丈夫だよ。今の気持ちを少しだけ置いていこうね。",
        "今日はまだ記録がないみたい。無理のない範囲で聞かせてくれたら嬉しいな。"
      ],
      negative_trend: [
        "ちょっと頑張りすぎてないかな？ここでは肩の力を抜いて大丈夫だよ。",
        "最近はしんどさが続いてるかもね。まずはちゃんと休めていますように。"
      ],
      positive_trend: [
        "最近いいこと続きみたいで、なんだかこっちまで嬉しいな。",
        "少しずつ調子がよさそうで安心したよ。この感じを大事にしたいね。"
      ],
      neutral_trend: [
        "最近の調子はどうかな？よければ今日のこともゆっくり聞かせてね。",
        "大きく変わらない日も大切だよ。今日の気持ちをそのまま残してみよう。"
      ]
    },
    "driving" => {
      no_posts: [
        "まずは1件いこう。短くてもいいから、今日のことを残してみよう。",
        "まだ投稿なしだね。今の気分をひとことでも書けば前進だよ。"
      ],
      negative_trend: [
        "最近ちょっと消耗してない？無理を続ける前に、いったん整えよう。",
        "しんどい流れが続いてるかも。今日は立て直し優先でいこう。"
      ],
      positive_trend: [
        "最近かなりいい感じだね。この調子で進んでいこう。",
        "いい流れが来てるね。今のうちに気持ちも整理しておこう。"
      ],
      neutral_trend: [
        "最近の調子はどう？今の状態を確認して次につなげよう。",
        "大きな波はなさそうだね。今日のことも記録して整えていこう。"
      ]
    },
    "expressive" => {
      no_posts: [
        "まだ何も書いてないね！今日の気持ち、ひとことだけでも聞かせて〜！",
        "最初の1件、気楽にいこう！今の気分をそのまま置いてみてね。"
      ],
      negative_trend: [
        "最近ちょっとおつかれムードかも？今日は自分にやさしくしていこうね。",
        "しんどい日が続いてる感じかな。ここでは無理せず、ありのままで大丈夫！"
      ],
      positive_trend: [
        "最近いいこと続きじゃない？すごくいい感じだね！",
        "お、最近の調子かなりよさそう！この波、いいね〜！"
      ],
      neutral_trend: [
        "最近の調子はどうかな？今日の気分も気軽に残してみてね！",
        "ふつうの日も大事だよ〜。今の気持ち、ちょっとだけ見せて！"
      ]
    },
    "kansai_friend" => {
      no_posts: [
        "まだ書いてへんのやね。ひとことからでもええし、今の気分聞かせてや〜。",
        "今日はまだ投稿なしやな。気楽にひとつ、残してみよか。"
      ],
      negative_trend: [
        "最近ちょっと疲れ気味ちゃう？無理しすぎんといてな。",
        "しんどい日が続いとるかもやし、今日はちょい休憩モードでいこな。"
      ],
      positive_trend: [
        "最近ええこと続きやん！なんかこっちまでうれしなるわ〜。",
        "調子ようなってきてる感じするで。このままええ流れ乗ってこな。"
      ],
      neutral_trend: [
        "最近の調子どうなん？今日の気分も気楽に聞かせてや。",
        "まあまあ普通な日も大事やで。今の気持ち、そのまま置いてき〜。"
      ]
    }
  }.freeze

  def initialize(user:, buddy:)
    @user = user
    @buddy = buddy
  end

  def call
    pattern = detect_pattern
    messages = MESSAGE_PATTERNS.fetch(buddy_code, MESSAGE_PATTERNS["normal"])
    candidates = messages.fetch(pattern)

    pick_message(candidates, pattern)
  end

  private

  attr_reader :user, :buddy

  def buddy_code
    buddy&.code.presence || "normal"
  end

  def detect_pattern
    return :no_posts if recent_posts.empty?

    average = recent_moods.sum.to_f / recent_moods.size

    if average <= 1.4
      :negative_trend
    elsif average >= 2.8
      :positive_trend
    else
      :neutral_trend
    end
  end

  def recent_posts
    @recent_posts ||= user.posts.where.not(mood: nil).order(posted_at: :desc, created_at: :desc).limit(3)
  end

  def recent_moods
    recent_posts.map(&:mood_before_type_cast)
  end

  def pick_message(candidates, pattern)
    return candidates.first if candidates.size == 1

    index = message_index(pattern, candidates.size)
    candidates[index]
  end

  def message_index(pattern, size)
    seed = [
      user.id,
      buddy_code,
      pattern,
      Date.current.to_s
    ].join("-")

    Zlib.crc32(seed) % size
  end
end
