class DiagnosesController < ApplicationController
  before_action :set_bottom_nav

  VALID_TYPES = %w[expressive driving amiable analytical].freeze

  def top
  end

  def questions
    @questions = DiagnosisQuestion.order(:position)
    render :diagnosis_questions
  end

  # POST /diagnosis/result
  # Turbo対策：成功時は必ず 303 で GET に飛ばす
  def result
    raw_answers = params[:answers].presence || {}

    if raw_answers.blank?
      return redirect_to diagnosis_questions_path,
                         alert: "結果を集計できませんでした。もう一度診断を行ってください。",
                         status: :see_other
    end

    scores = Hash.new(0)

    raw_answers.each do |question_id, value|
      question = DiagnosisQuestion.find_by(id: question_id)
      next if question.nil?

      scores[question.category] += value.to_i
    end

    if scores.empty? || scores.values.all?(&:zero?)
      return redirect_to diagnosis_questions_path,
                         alert: "結果を集計できませんでした。もう一度診断を行ってください。",
                         status: :see_other
    end

    dominant_type, _ = scores.max_by { |_, v| v }
    dominant_type = dominant_type.to_s
    dominant_type = "amiable" unless VALID_TYPES.include?(dominant_type)

    session[:diagnosis_result] = {
      social_type: dominant_type,
      scores: scores
    }

    if user_signed_in?
      ActiveRecord::Base.transaction do
        # ユーザーへ保存
        current_user.update!(
          social_type: dominant_type,
          recommended_buddy_type: dominant_type,
          dominant_type: dominant_type # GA4 user_property 用に保存
        )

        # 診断履歴として保存（将来16分類にも耐える形）
        current_user.social_type_results.create!(
          schema_version: 4,
          dominant_type: dominant_type.to_sym,              # enum想定
          scores: scores.transform_keys(&:to_s),            # jsonb向けにキーを文字列化
          question_set_key: "v1",
          diagnosed_at: Time.current
        )
      end
    end

    redirect_to diagnosis_result_page_path(type: dominant_type), status: :see_other
  end

  # GET /diagnosis/result/:type
  def result_page
    type = params[:type].to_s
    type = "amiable" unless VALID_TYPES.include?(type)

    @dominant_type = type
    @scores = session.dig(:diagnosis_result, :scores) || {}

    setup_type_data!(@dominant_type)
    set_share_meta_tags!(@dominant_type)

    raw_share_text = <<~TEXT
      AI-Bloomでソーシャルタイプ診断をしました！
      結果は「#{@current_type_info[:name]}」でした。
      タイプ概要：#{@current_type_info[:summary]}
      #AI_Bloom #ソーシャルタイプ診断
    TEXT

    @share_url = diagnosis_result_page_url(type: @dominant_type)
    @twitter_intent_url =
      "https://twitter.com/intent/tweet" \
      "?text=#{ERB::Util.url_encode(raw_share_text.strip)}" \
      "&url=#{ERB::Util.url_encode(@share_url)}"

    if user_signed_in? && !current_user.onboarded?
      current_user.update(onboarded_at: Time.current)
    end
  end

  # GET /diagnosis/share/:type
  def share
    type = params[:type].to_s
    type = "amiable" unless VALID_TYPES.include?(type)

    @dominant_type = type
    setup_type_data!(@dominant_type)
    set_share_meta_tags!(@dominant_type)

    render :share, layout: "application"
  end

  private

  def set_bottom_nav
    @bottom_nav_key = "diagnosis"
  end

  def setup_type_data!(dominant_type)
    @type_definitions = {
      "expressive" => {
        name: "Expressive（表現型）",
        summary: "感情豊かでアイデアが多く、場を明るくするタイプ。",
        detail:  "新しい発想が好きで、チームのムードメーカーになりやすいタイプです。",
        personality: "気持ちをオープンに表現し、人と関わることでエネルギーが満たされるタイプ。",
        strengths: "アイデア出し・場づくり・人を巻き込むことが得意で、前向きな空気をつくれます。",
        other: "一度にいろいろなことを始めたくなりやすいので、やることを絞ると力を発揮しやすくなります。",
        buddy_compatibility: "AIバディとは「思いついたことをどんどん話して、整理してもらう」使い方と相性◎。"
      },
      "driving" => {
        name: "Driving（行動型）",
        summary: "決断・スピード・結果にこだわるタイプ。",
        detail:  "ゴールから逆算して動くのが得意で、物事を前に進める推進力があります。",
        personality: "目標志向で、「どうやって達成するか」を考えるのが好きなタイプ。",
        strengths: "決断力・行動力・責任感が強く、プロジェクトを前に進めるリーダー役になりやすいです。",
        other: "周りのペースがゆっくりだとイライラしやすいので、「自分のゴール」と「チームのペース」を両方意識できると◎です。",
        buddy_compatibility: "AIバディとは「目標を共有して、タスク分解や優先度整理を頼む」相性が良いタイプ。"
      },
      "amiable" => {
        name: "Amiable（協調型）",
        summary: "やさしさ・調和を大切にし、支えることが得意なタイプ。",
        detail:  "人の気持ちに寄りそい、場の空気を和らげるのが得意です。",
        personality: "相手の立場に立って物事を考える、あたたかさのあるタイプ。",
        strengths: "聞く力・調整力・サポート力が高く、安心して相談できる存在になりやすいです。",
        other: "自分の気持ちを後回しにしがちなので、「自分はどう感じているか？」を言葉にしてみる時間も大切にしてみてください。",
        buddy_compatibility: "AIバディとは「まず自分の気持ちを聞いてもらう」「モヤモヤの整理を手伝ってもらう」使い方と相性◎。"
      },
      "analytical" => {
        name: "Analytical（分析型）",
        summary: "論理的にじっくり考えるタイプ。",
        detail:  "情報を集めて整理し、リスクを踏まえて慎重に判断するのが得意です。",
        personality: "ものごとを深く理解し、「なぜそうなるのか」を考えるのが好きなタイプ。",
        strengths: "分析力・計画力・正確さに優れ、ミスを減らしたり品質を高めたりする役割で力を発揮します。",
        other: "完璧を目指しすぎて動き出すまでに時間がかかることも。7〜8割OKなら一度動いてみる、というマイルールもおすすめです。",
        buddy_compatibility: "AIバディとは「情報整理や比較検討を手伝ってもらう」「メリット・デメリットを一緒に出してもらう」使い方がぴったり。"
      }
    }

    @buddy_relations = {
      "analytical" => {
        best_name: "キエル",
        reason: "物事の捉え方やペースが近く、落ち着いて相談できる“安心感の大きい相棒”だからです。",
        ranking: [
          [ "キエル", "ロジカルに整理しながら話せる最高の相棒。" ],
          [ "ルナ", "気持ちをやさしく受け止めてくれる聞き役バディ。" ],
          [ "ヴァル", "背中を押してくれる存在。" ],
          [ "エルフィ", "刺激的な一方、情報量が多く疲れてしまうことも。" ]
        ]
      },
      "amiable" => {
        best_name: "ルナ",
        reason: "お互いの気持ちを大切にし合える、“安心して弱音も本音も話せる関係”をつくりやすいからです。",
        ranking: [
          [ "ルナ", "安心して相談し合える相互支援関係。" ],
          [ "キエル", "冷静な視点で状況を整理してくれるサポート役。" ],
          [ "エルフィ", "元気をもらえる相手。" ],
          [ "ヴァル", "少し強引に感じることも。" ]
        ]
      },
      "driving" => {
        best_name: "ヴァル",
        reason: "目標志向やテンポ感が近く、“一緒に前へ進んでくれる相棒”として最もストレスなく動けるからです。",
        ranking: [
          [ "ヴァル", "「やること整理」に最強。" ],
          [ "エルフィ", "ひらめきを行動プランに落とし込んでくれる。" ],
          [ "ルナ", "癒やし枠。" ],
          [ "キエル", "ブレーキ役に感じることも。" ]
        ]
      },
      "expressive" => {
        best_name: "エルフィ",
        reason: "気持ちやアイデアをのびのび表現できて、“ノリと感情で共鳴し合える心強い味方”だからです。",
        ranking: [
          [ "エルフィ", "共鳴タイプのバディ。" ],
          [ "ヴァル", "挑戦を加速させたいときに◎。" ],
          [ "ルナ", "クッション役。" ],
          [ "キエル", "テーマを決めて相談すると◎。" ]
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

    @share_image_url = absolute_asset_url(@type_images[dominant_type])
  end

  def set_share_meta_tags!(_dominant_type)
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

  def absolute_asset_url(logical_path)
    host = ENV["APP_HOST"].presence || request.base_url
    host = host.sub(/\Ahttp:/, "https:")

    ActionController::Base.helpers.asset_url(logical_path, host: host)
  end
end
