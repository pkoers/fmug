class PagesController < ApplicationController
  def landing
    @invitation_token_supplied = params[:invitation_token].present?
    @invitation = find_valid_invitation(params[:invitation_token]) if @invitation_token_supplied
    @invitation_token_valid = @invitation.present?
    set_invited_user_state if @invitation_token_valid

    return if @invitation_token_supplied

    @current_conference = Conference.find_by(current: true)
    @current_registration = current_user&.registrations&.find_by(conference: @current_conference)
    @registration_confirmation = current_user&.registrations&.find_by(id: flash[:registration_confirmation_id])
    @invitation_email_body = flash[:invitation_email_body]
    @conferences = Conference.all.order(:start_date)
    @schedules = Schedule.order(:day, :time)
  end

  private

  def find_valid_invitation(token)
    invitation = Invitation.find_by_token(token)
    invitation if invitation&.usable?
  end

  def set_invited_user_state
    @invited_user = User.find_by(email: @invitation.email)
    @invited_user_exists = @invited_user.present?
    return unless @invited_user_exists

    @current_conference = Conference.find_by(current: true)
    @invited_user_registered_for_current_conference = @current_conference.present? && @invited_user.registrations.exists?(conference: @current_conference)
  end
end
