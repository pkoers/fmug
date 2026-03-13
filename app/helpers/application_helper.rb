module ApplicationHelper
  def registration_attendance_label(registration)
    registration.attending_physically? ? "Physical attendance" : "Online attendance"
  end

  def registration_agenda_labels(registration)
    labels = []
    labels << "Present / Pitch an idea to the community" if registration.agenda_present?
    labels << "Ask a question/discuss a topic" if registration.agenda_question?
    labels << "Something else: #{registration.agenda_something_else_text}" if registration.agenda_something_else?
    labels << "Nothing to present" if registration.agenda_nothing_to_present?
    labels
  end

  def registration_dietary_label(registration)
    return "No dietary requirements" unless registration.has_dietary_requirements?

    "Dietary requirements: #{registration.dietary_requirements_text}"
  end

  def registration_confirmation_email_subject(conference)
    "Registration confirmed for Conference #{conference.edition}"
  end

  def registration_confirmation_email_body(registration)
    conference = registration.conference
    [
      "Dear #{registration.user.first_name},",
      "",
      "Your registration for Conference #{conference.edition} has been received.",
      "",
      "Conference dates: #{conference.start_date.strftime("%b %-d, %Y")} - #{conference.end_date.strftime("%b %-d, %Y")}",
      "Location: #{conference.location}",
      "Attendance: #{registration_attendance_label(registration)}",
      "Agenda: #{registration_agenda_labels(registration).join('; ')}",
      registration_dietary_label(registration),
      ("Chair note: #{registration.chair_note}" if registration.chair_note.present?),
      "",
      "Kind regards,",
      "The Chair"
    ].compact.join("\n")
  end

  def registration_confirmation_email_html_body(registration)
    conference = registration.conference
    details = [
      "Conference dates: #{conference.start_date.strftime("%b %-d, %Y")} - #{conference.end_date.strftime("%b %-d, %Y")}",
      "Location: #{conference.location}",
      "Attendance: #{registration_attendance_label(registration)}",
      "Agenda: #{registration_agenda_labels(registration).join('; ')}",
      registration_dietary_label(registration),
      ("Chair note: #{registration.chair_note}" if registration.chair_note.present?)
    ].compact

    safe_join([
      content_tag(:p, "Dear #{registration.user.first_name},"),
      content_tag(:p, "Your registration for Conference #{conference.edition} has been received."),
      content_tag(:ul, safe_join(details.map { |detail| content_tag(:li, detail) })),
      content_tag(:p, "Kind regards,"),
      content_tag(:p, "The Chair")
    ])
  end

  def invitation_email_subject(conference)
    "Invitation to Conference #{conference.edition}"
  end

  def invitation_email_body(invitation, token:)
    conference = invitation.conference
    inviter_name = [ invitation.inviter.first_name, invitation.inviter.last_name ].compact.join(" ").presence || invitation.inviter.email
    invitation_link = root_url(invitation_token: token)

    [
      "Hi #{invitation.first_name},",
      "",
      "#{inviter_name} invited you to join Conference #{conference.edition}.",
      "",
      "Conference dates: #{conference.start_date.strftime("%b %-d, %Y")} - #{conference.end_date.strftime("%b %-d, %Y")}",
      "Location: #{conference.location}",
      "",
      "Invitation token: #{token}",
      "",
      "Use this invitation link to register:",
      invitation_link,
      "",
      "This invitation expires on #{invitation.expires_at.strftime("%b %-d, %Y at %H:%M %Z")}.",
      "It can only be used once.",
      "",
      "Best regards,",
      inviter_name
    ].join("\n")
  end

  def invitation_email_html_body(invitation, token:)
    conference = invitation.conference
    inviter_name = [ invitation.inviter.first_name, invitation.inviter.last_name ].compact.join(" ").presence || invitation.inviter.email
    invitation_link = root_url(invitation_token: token)

    safe_join([
      content_tag(:p, "Hi #{invitation.first_name},"),
      content_tag(:p, "#{inviter_name} invited you to join Conference #{conference.edition}."),
      content_tag(:ul, safe_join([
        content_tag(:li, "Conference dates: #{conference.start_date.strftime("%b %-d, %Y")} - #{conference.end_date.strftime("%b %-d, %Y")}"),
        content_tag(:li, "Location: #{conference.location}"),
        content_tag(:li, "Invitation token: #{token}"),
        content_tag(:li, "This invitation expires on #{invitation.expires_at.strftime("%b %-d, %Y at %H:%M %Z")}."),
        content_tag(:li, "It can only be used once.")
      ])),
      content_tag(:p, "Use this invitation link to register:"),
      content_tag(:p, link_to(invitation_link, invitation_link)),
      content_tag(:p, "Best regards,"),
      content_tag(:p, inviter_name)
    ])
  end

  def magic_link_email_subject
    "Your FMUG magic link"
  end

  def magic_link_email_body(magic_link)
    [
      "Hi #{magic_link.first_name},",
      "",
      "Your FMUG magic link is ready.",
      "",
      "Use this link within 15 minutes to activate your account and sign in:",
      magic_link_url(magic_link.raw_token),
      "",
      "After you click it, your invitation will be completed and you will be signed in.",
      "",
      "Kind regards,",
      "FMUG Chair"
    ].join("\n")
  end

  def magic_link_email_html_body(magic_link)
    link = magic_link_url(magic_link.raw_token)

    safe_join([
      content_tag(:p, "Hi #{magic_link.first_name},"),
      content_tag(:p, "Your FMUG magic link is ready."),
      content_tag(:p, "Use this link within 15 minutes to activate your account and sign in:"),
      content_tag(:p, link_to(link, link)),
      content_tag(:p, "After you click it, your invitation will be completed and you will be signed in."),
      content_tag(:p, "Kind regards,"),
      content_tag(:p, "FMUG Chair")
    ])
  end
end
