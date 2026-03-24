class PagesController < ApplicationController
  def landing
    @invitation_token_supplied = params[:invitation_token].present?
    @invitation = find_valid_invitation(params[:invitation_token]) if @invitation_token_supplied
    @invitation_token_valid = @invitation.present?
    set_invited_user_state if @invitation_token_valid
    @current_conference = Conference.find_by(current: true)
    @current_registration = current_user&.registrations&.find_by(conference: @current_conference)
    @conferences = Conference.all.order(:start_date)
    @schedules = Schedule.order(:day, :time)
    @show_known_user_invitation_popup = show_known_user_invitation_popup?
    @show_new_user_invitation_popup = show_new_user_invitation_popup?
    @known_user_invitation_popup_message = known_user_invitation_popup_message

    return unless @invitation_token_supplied
    return if @show_known_user_invitation_popup || @show_new_user_invitation_popup

    @current_conference = nil
    @current_registration = nil
    @conferences = nil
    @schedules = nil
  end

  def privacy
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

  def show_known_user_invitation_popup?
    @invitation_token_valid && @invited_user_exists
  end

  def show_new_user_invitation_popup?
    @invitation_token_valid && !@invited_user_exists
  end

  def known_user_invitation_popup_message
    return unless @show_known_user_invitation_popup

    if @invited_user_registered_for_current_conference
      "You are already registered for FMUG #{@current_conference.edition}"
    else
      "Welcome back #{@invited_user.first_name}, you are not yet registered for the upcoming FMUG"
    end
  end
end
