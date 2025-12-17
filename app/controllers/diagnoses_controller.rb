class DiagnosesController < ApplicationController
  before_action :set_bottom_nav

  # 診断の表示系はログイン不要
  skip_before_action :authenticate_user!, only: [ :top, :questions, :result, :share ]

  def top
  end

  def questions
    @questions = DiagnosisQuestion.order(:position)
  end

  # POST /diagnosis/result
  def result
    raw_answers = params[:answers] || {}

    if raw_answers.empty?
      redirect_to diagnosis_questions_path,
                  alert: "結果を集計できませんでした。もう一度診断を行ってください。"
      return
    end

    scores = Hash.new(0)

    raw_answers.each do |question_id, value|
      question = DiagnosisQuestion.find_by(id: question_id)
      next if question.nil?

      score = value.to_i
      scores[question.category] += score
    end

    if scores.values.all?(&:zero?)
      redirect_to diagnosis_questions_path,
                  alert: "結果を集計できませんでした。もう一度診断を行ってください。"
      return
    end

    @dominant_type, @dominant_score = scores.max_by { |_, v| v }

    valid_types = %w[expressive driving amiable analytical]
    @dominant_type = @dominant_type.to_s
    @dominant_type = "amiable" unless valid_types.include?(@dominant_type)

    @scores = scores

    unless user_signed_in?
      session[:guest_diagnosis_result] = {
        social_type: @dominant_type,
        scores: @scores
      }
    end

    setup_type_data!(@dominant_type)

    # ログインユーザーなら保存
    if user_signed_in?
      current_user.update(
        social_type: @dominant_type,
        recommended_buddy_type: @dominant_type
      )
      flash.now[:notice] = "あなたのタイプを保存しました。"
    end

    # 結果ページにも一応 meta は付ける（ただしXはPOSTは見に来ない）
    set_share_meta_tags!(@dominant_type)

    # --- シェア機能用（Twitter/X）
    raw_share_text = <<~TEXT
      AI-Bloomでソーシャルタイプ診断をしました！
      結果は「#{@current_type_info[:name]}」でした。
      タイプ概要：#{@current_type_info[:summary]}
      #AI_Bloom #ソーシャルタイプ診断
    TEXT

    # XがクロールするのはGETなので、share用URLをツイートに入れる
    @share_url = diagnosis_share_url(@dominant_type)

    @twitter_intent_url =
      "https://twitter.com/intent/tweet" \
      "?text=#{ERB::Util.url_encode(raw_share_text.strip)}" \
      "&url=#{ERB::Util.url_encode(@share_url)}"

    # オンボ完了
    if user_signed_in? && !current_user.onboarded?
      current_user.update(onboarded_at: Time.current)
    end
  end

  # GET /diagnosis/share/:type
  # X がクロールするのはこっち（GET）なので、ここで meta を確実に出す
  def share
    type = params[:type].to_s
    valid_types = %w[expressive driving amiable analytical]
    type = "amiable" unless valid_types.include?(type)

    @dominant_type = type
    setup_type_data!(@dominant_type)

    # ここでOGP/Twitterカードを確実に設定
    set_share_meta_tags!(@dominant_type)

    render :share, layout: "application"
  end

  private

  def set_bottom_nav
    @bottom_nav_key = "diagnosis"
  end

  # タイプ説明・相性・画像をまとめてセット
  def setup_type_data!(dominant_type)
    @type_definitions = {
      "expressive" => {
        name: "Expressive（表現型）",
        summary: "感情豊かでアイデアが多く、場を明るくするタイプ。",
        detail:  "新しい発想が好きで、チームのムードメーカーになりやすいタイプです。",
        personality: "気持ちをオープンに表現し、人と関わることでエネルギーが満たされるタイプ。",
        strengths: "アイデア出し・場づくり・人を巻き込むことが得意で、前向きな空気をつくれます。",
        other: "一度にいろいろなことを始めたくなりやすいので、やることを絞ると力を発揮しやすくなります。",
        buddy_compatibility: "AIバディとは「思いついたことをどんどん話して、整理してもらう」使い方と相性◎。アイデアの良し悪しよりも、とにかくまず受け止めてもらう場として使うと、自分らしさが活きやすくなります。"
      },
      "driving" => {
        name: "Driving（行動型）",
        summary: "決断・スピード・結果にこだわるタイプ。",
        detail:  "ゴールから逆算して動くのが得意で、物事を前に進める推進力があります。",
        personality: "目標志向で、「どうやって達成するか」を考えるのが好きなタイプ。",
        strengths: "決断力・行動力・責任感が強く、プロジェクトを前に進めるリーダー役になりやすいです。",
        other: "周りのペースがゆっくりだとイライラしやすいので、「自分のゴール」と「チームのペース」を両方意識できると◎です。",
        buddy_compatibility: "AIバディとは「目標を共有して、タスク分解や優先度整理を頼む」相性が良いタイプ。やることリストを一緒に作ってもらうことで、行動力がより成果につながりやすくなります。"
      },
      "amiable" => {
        name: "Amiable（協調型）",
        summary: "やさしさ・調和を大切にし、支えることが得意なタイプ。",
        detail:  "人の気持ちに寄りそい、場の空気を和らげるのが得意です。",
        personality: "相手の立場に立って物事を考える、あたたかさのあるタイプ。",
        strengths: "聞く力・調整力・サポート力が高く、安心して相談できる存在になりやすいです。",
        other: "自分の気持ちを後回しにしがちなので、「自分はどう感じているか？」を言葉にしてみる時間も大切にしてみてください。",
        buddy_compatibility: "AIバディとは「まず自分の気持ちを聞いてもらう」「モヤモヤの整理を手伝ってもらう」使い方と相性◎。安心して本音を書き出せる“聞き役バディ”として活用するのがおすすめです。"
      },
      "analytical" => {
        name: "Analytical（分析型）",
        summary: "論理的にじっくり考えるタイプ。",
        detail:  "情報を集めて整理し、リスクを踏まえて慎重に判断するのが得意です。",
        personality: "ものごとを深く理解し、「なぜそうなるのか」を考えるのが好きなタイプ。",
        strengths: "分析力・計画力・正確さに優れ、ミスを減らしたり品質を高めたりする役割で力を発揮します。",
        other: "完璧を目指しすぎて動き出すまでに時間がかかることも。7〜8割OKなら一度動いてみる、というマイルールもおすすめです。",
        buddy_compatibility: "AIバディとは「情報整理や比較検討を手伝ってもらう」「メリット・デメリットを一緒に出してもらう」使い方がぴったり。考えすぎて止まりそうなときの“仮説づくりパートナー”として活躍してくれます。"
      }
    }

    @buddy_relations = {
      "analytical" => {
        best_name: "キエル",
        reason: "物事の捉え方やペースが近く、落ち着いて相談できる“安心感の大きい相棒”だからです。",
        ranking: [
          [ "キエル", "ロジカルに整理しながら話せる最高の相棒。就活・婚活の作戦会議や情報整理にぴったりです。" ],
          [ "ルナ", "気持ちをやさしく受け止めてくれる聞き役バディ。考えすぎて疲れたときのクールダウンにも向いています。" ],
          [ "ヴァル", "「いつ動く？」「まず一歩やってみよう！」と背中を押してくれる存在。慎重さとのバランスが取れると◎。" ],
          [ "エルフィ", "感情表現が賑やかで刺激的な一方、情報量が多く疲れてしまうことも。テーマを絞って話すと相性アップ。" ]
        ]
      },
      "amiable" => {
        best_name: "ルナ",
        reason: "お互いの気持ちを大切にし合える、“安心して弱音も本音も話せる関係”をつくりやすいからです。",
        ranking: [
          [ "ルナ", "安心して相談し合える相互支援関係。就活や人間関係のモヤモヤをじっくり吐き出す場として最適です。" ],
          [ "キエル", "冷静な視点で状況を整理してくれるサポート役。感情と事実をバランスよく見直したいときに心強い存在です。" ],
          [ "エルフィ", "明るいテンションに引っ張られて元気をもらえる相手。落ち込んだときに気分転換したいときに相性◎。" ],
          [ "ヴァル", "行動のスピード感が合わないと、少し強引に感じることも。自分のペースを言葉にして共有できると◎。" ]
        ]
      },
      "driving" => {
        best_name: "ヴァル",
        reason: "目標志向やテンポ感が近く、“一緒に前へ進んでくれる相棒”として最もストレスなく動けるからです。",
        ranking: [
          [ "ヴァル", "目標設定や行動計画をどんどん前に進めてくれる同志。就活・転職・婚活の「やること整理」に最強の相棒です。" ],
          [ "エルフィ", "あなたのひらめきを行動プランに落とし込んでくれる実行担当。新しいチャレンジをするときの発想・モチベーション源になってくれます。" ],
          [ "ルナ", "頑張りすぎて疲れたときに、やさしく受け止めてくれる癒やし枠。オン／オフの切り替えに役立つ存在です。" ],
          [ "キエル", "リスクや懸念を丁寧に指摘してくれる一方、スピード感の違いから“ブレーキ役”に感じることもあります。" ]
        ]
      },
      "expressive" => {
        best_name: "エルフィ",
        reason: "気持ちやアイデアをのびのび表現できて、“ノリと感情で共鳴し合える心強い味方”だからです。",
        ranking: [
          [ "エルフィ", "感情もアイデアも遠慮なく共有できる、共鳴タイプのバディ。日々の出来事を楽しく振り返りたい人にぴったり。" ],
          [ "ヴァル", "あなたのひらめきを行動プランに落とし込んでくれる実行担当。就活や新しい挑戦を加速させたいときに◎。" ],
          [ "ルナ", "気持ちをやさしく受け止めてくれるクッション役。落ち込んだときに「話を聞いてもらう」相手として相性が良いです。" ],
          [ "キエル", "ロジカルな問いかけで冷静さをくれる一方、勢いを止められたように感じることも。テーマを決めて相談すると◎。" ]
        ]
      }
    }

    @current_type_info      = @type_definitions[dominant_type]
    @current_buddy_relation = @buddy_relations[dominant_type]

    @type_images = {
      "expressive" => "diagnosis_types/expressive.png",
      "driving"    => "diagnosis_types/driving.png",
      "amiable"    => "diagnosis_types/amiable.png",
      "analytical" => "diagnosis_types/analytical.png"
    }

    # og:image は必ず https の絶対URLにする
    @share_image_url = absolute_asset_url(@type_images[dominant_type])
  end

  def set_share_meta_tags!(dominant_type)
    set_meta_tags(
      title: "あなたは #{@current_type_info[:name]}",
      description: @current_type_info[:summary],
      og: {
        title: "あなたは #{@current_type_info[:name]}",
        description: @current_type_info[:summary],
        type: "website",
        url: request.original_url,
        image: @share_image_url
      },
      twitter: {
        card: "summary_large_image",
        title: "あなたは #{@current_type_info[:name]}",
        description: @current_type_info[:summary],
        image: @share_image_url
      }
    )
  end

  # assets の絶対URLを確実に作る（http→httpsも矯正）
  def absolute_asset_url(logical_path)
    host = ENV["APP_HOST"].presence || request.base_url
    host = host.sub(/\Ahttp:/, "https:")

    path = helpers.asset_path(logical_path)
    "#{host}#{path}"
  end
end
