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
      body: helpers.login_magic_link_email_body(login_magic_link, invitation_token: invitation_token_for(user)),
      html_body: helpers.login_magic_link_email_html_body(login_magic_link, invitation_token: invitation_token_for(user)),
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
    consume_invitation_for(login_magic_link.user)
    session[:user_id] = login_magic_link.user.id

    redirect_to root_path, notice: "Signed in successfully."
  end

  private

  def login_magic_link_params
    params.require(:login_magic_link).permit(:email, :invitation_token)
  end

  def invitation_token_for(user)
    invitation = invitation_from_token
    invitation&.email == user.email ? login_magic_link_params[:invitation_token] : nil
  end

  def consume_invitation_for(user)
    invitation = invitation_from_token
    return unless invitation&.email == user.email

    invitation.mark_as_used!
  end

  def invitation_from_token
    token = params[:invitation_token] || params.dig(:login_magic_link, :invitation_token)
    @invitation_from_token ||= Invitation.find_by_token(token) if token.present?
  end

  def redirect_if_logged_in
    return unless logged_in?

    redirect_to root_path, alert: "You are already signed in."
  end
end
