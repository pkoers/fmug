class ProfilePicturesController < ApplicationController
  before_action :require_login

  def update
    photo = profile_picture_params[:photo]

    if photo.blank?
      redirect_to users_path, alert: "Choose a profile picture to upload."
    elsif current_user.update(photo: photo)
      redirect_to users_path, notice: "Your profile picture was updated."
    else
      redirect_to users_path, alert: current_user.errors.full_messages.to_sentence
    end
  end

  def destroy
    current_user.photo.purge if current_user.photo.attached?

    redirect_to users_path, notice: "Your profile picture was removed."
  end

  private

  def profile_picture_params
    params.require(:profile_picture).permit(:photo)
  end
end
