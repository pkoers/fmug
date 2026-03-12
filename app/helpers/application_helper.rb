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
end
