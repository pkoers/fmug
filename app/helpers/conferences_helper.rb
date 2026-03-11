module ConferencesHelper
  CONFERENCE_PLACEHOLDER_IMAGE = "https://images.unsplash.com/photo-1547191783-94d5f8f6d8b1?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=400&q=80".freeze

  def conference_image_source(conference)
    conference.image.attached? ? conference.image : CONFERENCE_PLACEHOLDER_IMAGE
  end
end
