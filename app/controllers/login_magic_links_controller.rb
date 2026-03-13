class LoginMagicLinksController < ApplicationController
  before_action :redirect_if_logged_in, only: :create

  def create
    user = User.find_by(email: login_magic_link_params[:email].to_s.strip.downcase)

    unless user
      redirect_to root_path, alert: "No FMUG account was found for that email address."
      return
    end

    login_magic_link = user.login_magic_links.create!

    EmailDeliveryService.notify(
      to: user.email,
      subject: helpers.login_magic_link_email_subject,
      body: helpers.login_magic_link_email_body(login_magic_link),
      html_body: helpers.login_magic_link_email_html_body(login_magic_link),
      from_name: "FMUG Chair",
      from_email: "chair@fmug.eu",
      delivery: :brevo
    )

    redirect_to root_path, notice: "A login magic link has been sent. It is valid for 15 minutes."
  end

  def show
    login_magic_link = LoginMagicLink.find_by_token(params[:token])

    unless login_magic_link&.usable?
      render "magic_links/invalid", status: :unprocessable_entity
      return
    end

    login_magic_link.mark_as_used!
    session[:user_id] = login_magic_link.user.id

    redirect_to root_path, notice: "Signed in successfully."
  end

  private

  def login_magic_link_params
    params.require(:login_magic_link).permit(:email)
  end

  def redirect_if_logged_in
    return unless logged_in?

    redirect_to root_path, alert: "You are already signed in."
  end
end
