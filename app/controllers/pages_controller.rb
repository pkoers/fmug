class PagesController < ApplicationController
  def landing
    @current_conference = Conference.find_by(current: true)
    @current_registration = current_user&.registrations&.find_by(conference: @current_conference)
    @registration_confirmation = current_user&.registrations&.find_by(id: flash[:registration_confirmation_id])
    @invitation_email_body = flash[:invitation_email_body]
    @conferences = Conference.all.order(:start_date)
    @schedules = Schedule.order(:day, :time)
  end
end
