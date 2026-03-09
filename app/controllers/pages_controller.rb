class PagesController < ApplicationController
  def landing
    @current_conference = Conference.find_by(current: true)
    @current_registration = current_user&.registrations&.find_by(conference: @current_conference)
    @conferences = Conference.all.order(:start_date)
    @schedules = Schedule.order(:day, :time)
  end
end
