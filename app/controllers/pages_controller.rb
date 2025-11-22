class PagesController < ApplicationController
  def landing
    @conferences = Conference.all.order(:start_date)
    @schedules = Schedule.order(:day, :time)
  end
end
