class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :google_oauth_configured?, :google_oauth_login_button_visible?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def google_oauth_configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def google_oauth_login_button_visible?
    google_oauth_configured? && google_oauth_host != "fmug.eu"
  end

  def require_login
    return if logged_in?

    redirect_to root_path, alert: "Please sign in first."
  end

  def require_admin
    return if logged_in? && current_user.admin?

    redirect_to root_path, alert: "You are not authorized to perform that action."
  end

  def google_oauth_host
    app_url = ENV["APP_URL"].presence
    return unless app_url

    URI.parse(app_url[%r{\Ahttps?://}i] ? app_url : "https://#{app_url}").host&.downcase
  end
end
