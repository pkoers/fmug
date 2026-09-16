require "csv"

class RegistrationsController < ApplicationController
  before_action :require_admin, only: :index
  before_action :require_login, only: [ :create, :destroy ]
  before_action :set_current_conference, only: [ :create, :destroy ]

  def index
    @conference = Conference.current_conference.find(params[:conference_id])
    @registrations = @conference.registrations.joins(:user).preload(:user)
      .order("users.first_name", "users.last_name", "registrations.id")

    respond_to do |format|
      format.html
      format.csv do
        send_data registrations_csv,
          filename: "conference-#{@conference.edition}-registrations.csv",
          type: "text/csv; charset=utf-8",
          disposition: :attachment
      end
    end
  end

  def create
    if current_user.registrations.exists?(conference: @conference)
      redirect_to root_path, alert: "You are already registered for this conference."
      return
    end

    attendance_mode = registration_params[:attendance_mode]

    unless %w[physical online].include?(attendance_mode)
      redirect_to root_path, alert: "Please choose whether you will attend physically or online."
      return
    end

    registration = current_user.registrations.build(
      conference: @conference,
      attending_physically: attendance_mode == "physical",
      agenda_present: registration_params[:agenda_present],
      agenda_question: registration_params[:agenda_question],
      agenda_something_else: registration_params[:agenda_something_else],
      agenda_something_else_text: registration_params[:agenda_something_else_text],
      agenda_nothing_to_present: registration_params[:agenda_nothing_to_present],
      has_dietary_requirements: registration_params[:has_dietary_requirements],
      dietary_requirements_text: registration_params[:dietary_requirements_text],
      chair_note: registration_params[:chair_note]
    )

    unless registration.save
      redirect_to root_path, alert: registration.errors.full_messages.to_sentence
      return
    end

    email_attributes = registration_email_attributes(registration)

    EmailDeliveryService.notify(**email_attributes, delivery: :brevo)

    redirect_to root_path, notice: "You are registered for Conference #{@conference.edition}. A confirmation email has been sent to #{current_user.email}."
  end

  def destroy
    registration = current_user.registrations.find_by(conference: @conference)

    unless registration
      redirect_to root_path, alert: "No registration was found for this conference."
      return
    end

    registration.destroy!

    redirect_to root_path, notice: "Your registration for Conference #{@conference.edition} was removed."
  end

  private

  def set_current_conference
    @conference = Conference.find_by(current: true)

    return if @conference.present?

    redirect_to root_path, alert: "There is no current conference open for registration."
  end

  def registration_params
    params.require(:registration).permit(
      :attendance_mode,
      :agenda_present,
      :agenda_question,
      :agenda_something_else,
      :agenda_something_else_text,
      :agenda_nothing_to_present,
      :has_dietary_requirements,
      :dietary_requirements_text,
      :chair_note
    )
  end

  def registration_email_attributes(registration)
    {
      to: current_user.email,
      subject: helpers.registration_confirmation_email_subject(@conference),
      body: helpers.registration_confirmation_email_body(registration),
      html_body: helpers.registration_confirmation_email_html_body(registration),
      from_name: "FMUG Chair",
      from_email: "chair@fmug.eu"
    }
  end

  def registrations_csv
    CSV.generate do |csv|
      csv << [
        "First name",
        "Last name",
        "Email",
        "Company name",
        "Attendance mode",
        "Registration date",
        "Agenda selections",
        "Something else agenda detail",
        "Dietary requirement status",
        "Dietary detail",
        "Message for the Chair"
      ]

      @registrations.each do |registration|
        csv << [
          registration.user.first_name,
          registration.user.last_name,
          registration.user.email,
          registration.user.company_name.presence || "Company not provided",
          helpers.registration_attendance_label(registration),
          registration.created_at.to_date.iso8601,
          helpers.registration_agenda_selection_labels(registration).join("; "),
          registration.agenda_something_else? ? registration.agenda_something_else_text : nil,
          registration.has_dietary_requirements? ? "Yes" : "No",
          registration.has_dietary_requirements? ? registration.dietary_requirements_text : nil,
          registration.chair_note
        ].map { |value| spreadsheet_safe_csv_value(value) }
      end
    end
  end

  def spreadsheet_safe_csv_value(value)
    value = value.to_s
    value.match?(/\A[=+\-@]/) ? "'#{value}" : value
  end
end
