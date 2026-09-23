module LeadershipProfilesHelper
  CHAIR_PLACEHOLDER_IMAGE = "https://images.unsplash.com/photo-1529778873920-4da4926a72c2?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80".freeze
  VICE_CHAIR_PLACEHOLDER_IMAGE = "https://images.unsplash.com/photo-1591871937573-74dbba515c4c?ixlib=rb-1.2.1&auto=format&fit=crop&w=300&q=80".freeze
  LEADERSHIP_AVATAR_SIZE = 144

  def leadership_display_name(leadership_profile, position)
    leadership_profile&.public_send("#{position}_name").presence || leadership_role_name(position)
  end

  def leadership_avatar_source(leadership_profile, position)
    photo = leadership_profile&.public_send("#{position}_photo")
    return photo.variant(resize_to_fill: [ LEADERSHIP_AVATAR_SIZE, LEADERSHIP_AVATAR_SIZE ]) if photo&.attached?

    position == :chair ? CHAIR_PLACEHOLDER_IMAGE : VICE_CHAIR_PLACEHOLDER_IMAGE
  end

  private

  def leadership_role_name(position)
    position == :chair ? "Chair" : "Vice-Chair"
  end
end
