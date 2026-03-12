class PagesController < ApplicationController
  def landing
    @invitation_token_supplied = params[:invitation_token].present?
    @invitation_token_valid = validate_invitation_token(params[:invitation_token]) if @invitation_token_supplied

    return if @invitation_token_supplied

    @current_conference = Conference.find_by(current: true)
    @current_registration = current_user&.registrations&.find_by(conference: @current_conference)
    @registration_confirmation = current_user&.registrations&.find_by(id: flash[:registration_confirmation_id])
    @invitation_email_body = flash[:invitation_email_body]
    @conferences = Conference.all.order(:start_date)
    @schedules = Schedule.order(:day, :time)
  end

  private

  def validate_invitation_token(token)
    invitation = Invitation.find_by_token(token)
    invitation&.usable? || false
  end
end
