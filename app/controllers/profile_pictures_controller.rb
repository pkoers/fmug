class ProfilePicturesController < ApplicationController
  before_action :require_login

  def update
    photo = profile_picture_params[:photo]

    if photo.blank?
      redirect_to users_path, alert: "Choose a profile picture to upload."
    elsif current_user.update(photo: photo)
      redirect_to users_path, notice: "Your profile picture was updated."
    else
      redirect_to users_path, alert: profile_picture_error_message
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

  def profile_picture_error_message
    messages = []
    messages << "Your profile picture must be a PNG, JPEG/JPG, or WebP image. Please choose a supported image." if current_user.errors.of_kind?(:photo, :unsupported_format)
    messages << "Your profile picture exceeds the 0.5 MB maximum. Please choose a smaller image." if current_user.errors.of_kind?(:photo, :too_large)

    messages.presence&.join(" ") || current_user.errors.full_messages.to_sentence
  end
end
