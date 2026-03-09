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

    current_user.registrations.create!(
      conference: @conference,
      attending_physically: attendance_mode == "physical"
    )

    redirect_to root_path, notice: "You are registered for Conference #{@conference.edition}."
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
    params.require(:registration).permit(:attendance_mode)
  end
end
