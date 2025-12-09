module DiagnosesHelper
  # バディ名 → タイプキー の対応
  BUDDY_NAME_TO_TYPE = {
    "ルナ"   => "amiable",
    "キエル" => "analytical",
    "エルフィ" => "expressive",
    "ヴァル" => "driving"
  }.freeze

  def diagnosis_type_image(type_or_name, **options)
    key = type_or_name.to_s

    # 1. まずタイプキーとして扱う（expressive / amiable / driving / analytical）
    type_key =
      case key
      when "expressive", "amiable", "driving", "analytical"
        key
      else
        # 2. それ以外なら「バディ名」とみなしてタイプを引き当てる
        BUDDY_NAME_TO_TYPE[key]
      end

    # タイプが特定できなければ画像を出さない
    return "" if type_key.blank?

    filename =
      case type_key
      when "expressive" then "表現型.png"
      when "amiable"    then "協調型.png"
      when "driving"    then "行動型.png"
      when "analytical" then "分析型.png"
      end

    return "" if filename.blank?

    default_options = {
      alt: type_or_name,
      class: "w-10 h-10 rounded-full object-cover"
    }

    image_tag("diagnosis_result/#{filename}", default_options.merge(options))
  end
end
