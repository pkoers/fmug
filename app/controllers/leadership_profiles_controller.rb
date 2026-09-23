class LeadershipProfilesController < ApplicationController
  before_action :require_admin

  def update
    leadership_profile = LeadershipProfile.instance

    if leadership_profile.update(leadership_profile_params)
      redirect_to users_path, notice: "Leadership profiles were updated."
    else
      redirect_to users_path, alert: leadership_profile.errors.full_messages.to_sentence
    end
  end

  def chair_photo
    leadership_profile = LeadershipProfile.current
    leadership_profile&.chair_photo&.purge if leadership_profile&.chair_photo&.attached?

    redirect_to users_path, notice: "Chair photo was removed."
  end

  def vice_chair_photo
    leadership_profile = LeadershipProfile.current
    leadership_profile&.vice_chair_photo&.purge if leadership_profile&.vice_chair_photo&.attached?

    redirect_to users_path, notice: "Vice-Chair photo was removed."
  end

  private

  def leadership_profile_params
    params.fetch(:leadership_profile, ActionController::Parameters.new).permit(
      :chair_name,
      :vice_chair_name,
      :chair_photo,
      :vice_chair_photo
    )
  end
end
