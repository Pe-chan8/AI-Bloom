module BuddiesHelper
  def buddy_image_for(buddy)
    return "buddies/default.png" if buddy.nil?

    {
      "analytical" => "buddies/analytical.png",
      "amiable"    => "buddies/amiable.png",
      "driving"    => "buddies/driving.png",
      "expressive" => "buddies/expressive.png"
    }[buddy.code] || "buddies/default.png"
  end
end
