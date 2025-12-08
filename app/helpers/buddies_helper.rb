module BuddiesHelper
  BUDDY_IMAGE_MAP = {
    "analytical"    => "buddies/analytical_buddy.png",
    "amiable"       => "buddies/amiable_buddy.png",
    "driving"       => "buddies/driving_buddy.png",
    "expressive"    => "buddies/expressive_buddy.png",
    "kansai_friend" => "buddies/kansai_friend_buddy.png",
    "normal"        => "buddies/normal_buddy.png"
  }.freeze

  def buddy_image_for(buddy)
    code = buddy&.code
    BUDDY_IMAGE_MAP[code] || BUDDY_IMAGE_MAP["normal"]
  end
end
