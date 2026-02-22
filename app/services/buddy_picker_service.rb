class BuddyPickerService
  def initialize(params:)
    @params = params
  end

  def call
    key = recommend_key
    return { key: nil, primary_buddy: nil, extra_buddies: [] } if key.nil?

    yaml = Rails.application.config_for("buddy_recommendations") || {}

    primary_ids = Array(yaml[key.to_s])
    primary_buddy =
      if primary_ids.empty?
        nil
      else
        Buddy.where(id: primary_ids, is_active: true).order(Arel.sql("RANDOM()")).first
      end

    extra_ids = Array(yaml["special"])
    extra_buddies = Buddy.where(id: extra_ids, is_active: true).to_a

    { key: key, primary_buddy: primary_buddy, extra_buddies: extra_buddies }
  end

  private

  def recommend_key
    q1 = @params[:q1]
    q2 = @params[:q2]
    q3 = @params[:q3]
    return nil if [ q1, q2, q3 ].any?(&:blank?)

    base =
      if q1 == "talk" && q2 == "intuition"
        :expressive
      elsif q1 == "talk" && q2 == "logic"
        :driving
      elsif q1 == "solo" && q2 == "intuition"
        :amiable
      else
        :analytical
      end

    case q3
    when "energize" then :expressive
    when "decide"   then :driving
    when "soothe"   then :amiable
    when "organize" then :analytical
    else
      base
    end
  end
end
