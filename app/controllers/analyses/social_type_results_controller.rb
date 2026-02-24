class Analyses::SocialTypeResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bottom_nav

  def index
    @results = current_user.social_type_results.order(diagnosed_at: :desc)
  end

  def show
    @result = current_user.social_type_results.find(params[:id])
    setup_type_data!(@result.dominant_type)
  end

  private

  def set_bottom_nav
    @bottom_nav_key = "analytics"
  end

  def setup_type_data!(dominant_type)
    @type_definitions = {
      "expressive" => {
        name: "Expressive（表現型）",
        summary: "感情豊かでアイデアが多く、場を明るくするタイプ。",
        detail:  "新しい発想が好きで、チームのムードメーカーになりやすいタイプです。",
        personality: "気持ちをオープンに表現し、人と関わることでエネルギーが満たされるタイプ。",
        strengths: "アイデア出し・場づくり・人を巻き込むことが得意で、前向きな空気をつくれます。",
        other: "一度にいろいろなことを始めたくなりやすいので、やることを絞ると力を発揮しやすくなります。"
      },
      "driving" => {
        name: "Driving（行動型）",
        summary: "決断・スピード・結果にこだわるタイプ。",
        detail:  "ゴールから逆算して動くのが得意で、物事を前に進める推進力があります。",
        personality: "目標志向で、「どうやって達成するか」を考えるのが好きなタイプ。",
        strengths: "決断力・行動力・責任感が強く、プロジェクトを前に進めるリーダー役になりやすいです。",
        other: "周りのペースがゆっくりだとイライラしやすいので、「自分のゴール」と「チームのペース」を両方意識できると◎です。"
      },
      "amiable" => {
        name: "Amiable（協調型）",
        summary: "やさしさ・調和を大切にし、支えることが得意なタイプ。",
        detail:  "人の気持ちに寄りそい、場の空気を和らげるのが得意です。",
        personality: "相手の立場に立って物事を考える、あたたかさのあるタイプ。",
        strengths: "聞く力・調整力・サポート力が高く、安心して相談できる存在になりやすいです。",
        other: "自分の気持ちを後回しにしがちなので、「自分はどう感じているか？」を言葉にしてみる時間も大切にしてみてください。"
      },
      "analytical" => {
        name: "Analytical（分析型）",
        summary: "論理的にじっくり考えるタイプ。",
        detail:  "情報を集めて整理し、リスクを踏まえて慎重に判断するのが得意です。",
        personality: "ものごとを深く理解し、「なぜそうなるのか」を考えるのが好きなタイプ。",
        strengths: "分析力・計画力・正確さに優れ、ミスを減らしたり品質を高めたりする役割で力を発揮します。",
        other: "完璧を目指しすぎて動き出すまでに時間がかかることも。7〜8割OKなら一度動いてみる、というマイルールもおすすめです。"
      }
    }

    @current_type_info = @type_definitions[dominant_type.to_s] || @type_definitions["amiable"]

    # バディ画像を出す
    @buddy_images = {
      "expressive"  => "buddies/expressive_buddy.png",
      "driving"     => "buddies/driving_buddy.png",
      "amiable"     => "buddies/amiable_buddy.png",
      "analytical"  => "buddies/analytical_buddy.png"
    }
    @buddy_image_path = @buddy_images[dominant_type.to_s] || @buddy_images["amiable"]
  end
end
