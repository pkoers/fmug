class RegistrationsController < ApplicationController
  before_action :require_login
  before_action :set_current_conference

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

    registration = current_user.registrations.create!(
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
end
