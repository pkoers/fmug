class PagesController < ApplicationController
  def landing
    @conferences = Conference.all.order(:start_date)
  end
end
