class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    unless auth
      redirect_to root_path, alert: "Google login failed."
      return
    end

    identity = Identity.find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user = identity.user || User.find_by(email: auth.info.email)

    unless user
      user = User.create!(
        email: auth.info.email,
        first_name: auth.info.first_name.presence || auth.info.name.to_s.split.first || "Unknown",
        last_name: auth.info.last_name.presence || auth.info.name.to_s.split.drop(1).join(" ").presence || "Unknown",
        role: "Member"
      )
    end

    identity.user = user
    identity.save!

    session[:user_id] = user.id

    redirect_to root_path, notice: "Signed in successfully."
  end

  def failure
    redirect_to root_path, alert: params[:message].presence || "Google login failed."
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end
end
