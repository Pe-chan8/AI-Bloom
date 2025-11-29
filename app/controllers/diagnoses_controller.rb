class DiagnosesController < ApplicationController
  # 説明ページ
  def top
  end

  # 質問10問表示
  def questions
    @questions = DiagnosisQuestion.order(:position)
  end

  # 結果ページ
  def result
    raw_answers = params[:answers] || {}

    # 何も送られてこなかった場合
    if raw_answers.empty?
      redirect_to diagnosis_questions_path,
                  alert: "結果を集計できませんでした。もう一度診断を行ってください。"
      return
    end

    # タイプごとのスコア初期値
    scores = Hash.new(0)

    # 各質問のスコアを加算
    raw_answers.each do |question_id, value|
      question = DiagnosisQuestion.find_by(id: question_id)
      next if question.nil?

      score = value.to_i
      scores[question.category] += score
    end

    # すべてスコア 0 なら失敗扱い
    if scores.values.all?(&:zero?)
      redirect_to diagnosis_questions_path,
                  alert: "結果を集計できませんでした。もう一度診断を行ってください。"
      return
    end

    # 一番スコアが高いタイプ
    @dominant_type, @dominant_score = scores.max_by { |_, v| v }

    # 万が一 nil や未知のキーだったときのフォールバック
    valid_types = %w[expressive driving amiable analytical]

    @dominant_type = @dominant_type.to_s
    @dominant_type = "amiable" unless valid_types.include?(@dominant_type)

    @scores = scores

    # タイプごとの説明データ
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
      # Analytical（分析型）がユーザーのとき
      "analytical" => {
        best:  "Analytical（分析型）バディ",
        reason: "物事の捉え方やペースが近く、落ち着いて相談できる“安心感の大きい相棒”だからです。",
        ranking: [
          # 1位：同タイプ同士が最高の相棒
          [ "Analytical（分析型）",
           "ロジカルに整理しながら話せる最高の相棒。就活・婚活の作戦会議や情報整理にぴったりです。" ],
          # 2位：支え合えるパートナー
          [ "Amiable（協調型）",
           "気持ちをやさしく受け止めてくれる聞き役バディ。考えすぎて疲れたときのクールダウンにも向いています。" ],
          # 3位：良い意味での刺激になる相手
          [ "Driving（行動型）",
           "「いつ動く？」「まず一歩やってみよう！」と背中を押してくれる存在。慎重さとのバランスが取れると◎。" ],
          # 4位：少しすれ違いやすい相手
          [ "Expressive（表現型）",
           "感情表現が賑やかで刺激的な一方、情報量が多く疲れてしまうことも。テーマを絞って話すと相性アップ。" ]
        ]
      },

      # Amiable（協調型）がユーザーのとき
      "amiable" => {
        best:  "Amiable（協調型）バディ",
        reason: "お互いの気持ちを大切にし合える、“安心して弱音も本音も話せる関係”をつくりやすいからです。",
        ranking: [
          [ "Amiable（協調型）",
           "安心して相談し合える相互支援関係。就活や人間関係のモヤモヤをじっくり吐き出す場として最適です。" ],
          [ "Analytical（分析型）",
           "冷静な視点で状況を整理してくれるサポート役。感情と事実をバランスよく見直したいときに心強い存在です。" ],
          [ "Expressive（表現型）",
           "明るいテンションに引っ張られて元気をもらえる相手。落ち込んだときに気分転換したいときに相性◎。" ],
          [ "Driving（行動型）",
           "行動のスピード感が合わないと、少し強引に感じることも。自分のペースを言葉にして共有できると◎。" ]
        ]
      },

      # Driving（行動型）がユーザーのとき
      "driving" => {
        best:  "Driving（行動型）バディ",
        reason: "目標志向やテンポ感が近く、“一緒に前へ進んでくれる相棒”として最もストレスなく動けるからです。",
        ranking: [
          [ "Driving（行動型）",
           "目標設定や行動計画をどんどん前に進めてくれる同志。就活・転職・婚活の「やること整理」に最強の相棒です。" ],
          [ "Expressive（表現型）",
           "勢いとアイデアを形にしていくコンビ。新しいチャレンジをするときの発想・モチベーション源になってくれます。" ],
          [ "Amiable（協調型）",
           "頑張りすぎて疲れたときに、やさしく受け止めてくれる癒やし枠。オン／オフの切り替えに役立つ存在です。" ],
          [ "Analytical（分析型）",
           "リスクや懸念を丁寧に指摘してくれる一方、スピード感の違いから“ブレーキ役”に感じることもあります。" ]
        ]
      },

      # Expressive（表現型）がユーザーのとき
      "expressive" => {
        best:  "Expressive（表現型）バディ",
        reason: "気持ちやアイデアをのびのび表現できて、“ノリと感情で共鳴し合える心強い味方”だからです。",
        ranking: [
          [ "Expressive（表現型）",
           "感情もアイデアも遠慮なく共有できる、共鳴タイプのバディ。日々の出来事を楽しく振り返りたい人にぴったり。" ],
          [ "Driving（行動型）",
           "あなたのひらめきを行動プランに落とし込んでくれる実行担当。就活や新しい挑戦を加速させたいときに◎。" ],
          [ "Amiable（協調型）",
           "気持ちをやさしく受け止めてくれるクッション役。落ち込んだときに「話を聞いてもらう」相手として相性が良いです。" ],
          [ "Analytical（分析型）",
           "ロジカルな問いかけで冷静さをくれる一方、勢いを止められたように感じることも。テーマを決めて相談すると◎。" ]
        ]
      }
    }

    # メインタイプと説明／バディ相性をビューで使うための変数
    @current_type_info      = @type_definitions[@dominant_type]
    @current_buddy_relation = @buddy_relations[@dominant_type]

    # 診断結果をログインユーザーに保存
    if user_signed_in?
      current_user.update(
        social_type: @dominant_type,
        recommended_buddy_type: case @dominant_type
                                when "analytical" then "analytical"
                                when "amiable"    then "amiable"
                                when "driving"    then "driving"
                                when "expressive" then "expressive"
                                end
      )
      flash.now[:notice] = "あなたのタイプを保存しました。"
    end

    @type_images = {
      "expressive"  => "diagnosis_types/expressive.png",
      "driving"     => "diagnosis_types/driving.png",
      "amiable"     => "diagnosis_types/amiable.png",
      "analytical"  => "diagnosis_types/analytical.png"
    }

    # --- シェア機能用の生成（Twitter/X）
    type_name = @current_type_info[:name]
    type_summary = @current_type_info[:summary]

    # 画像のフルURL
    @share_image_url = view_context.asset_url(@type_images[@dominant_type])

    # シェアテキスト
    raw_share_text = <<~TEXT
      AI-Bloomでソーシャルタイプ診断をしました！
      結果は「#{type_name}」でした。
      タイプ概要：#{type_summary}
      #AI_Bloom #ソーシャルタイプ診断
      #{@share_image_url}
    TEXT

    @share_text = raw_share_text.strip
    @share_url  = diagnosis_top_url

    @twitter_intent_url =
      "https://twitter.com/intent/tweet?text=#{ERB::Util.url_encode(@share_text)}&url=#{ERB::Util.url_encode(@share_url)}"
  end

    private

  def set_bottom_nav
    @bottom_nav_key = "diagnosis"
  end
end
