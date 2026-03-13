class MagicLinksController < ApplicationController
  before_action :redirect_if_logged_in, only: :create

  def create
    invitation = Invitation.find_by_token(magic_link_params[:invitation_token])

    unless invitation&.usable?
      redirect_to root_path, alert: "This invitation is no longer valid."
      return
    end

    if User.exists?(email: invitation.email)
      redirect_to root_path(invitation_token: invitation.raw_token || magic_link_params[:invitation_token]), alert: "An account already exists for this invitation."
      return
    end

    magic_link = invitation.magic_links.create!(magic_link_request_attributes)

    EmailDeliveryService.notify(
      to: invitation.email,
      subject: helpers.magic_link_email_subject,
      body: helpers.magic_link_email_body(magic_link),
      html_body: helpers.magic_link_email_html_body(magic_link),
      from_name: "FMUG Chair",
      from_email: "chair@fmug.eu",
      delivery: :brevo
    )

    redirect_to root_path, notice: "Your magic link has been sent. It is valid for 15 minutes."
  rescue ActiveRecord::RecordInvalid
    redirect_to root_path(invitation_token: magic_link_params[:invitation_token]), alert: "Please enter both your first name and last name."
  end

  def show
    magic_link = MagicLink.find_by_token(params[:token])

    unless magic_link&.usable?
      render :invalid, status: :unprocessable_entity
      return
    end

    user = nil

    ActiveRecord::Base.transaction do
      user = User.find_or_create_by!(email: magic_link.invitation.email) do |record|
        record.first_name = magic_link.first_name
        record.last_name = magic_link.last_name
        record.role = "Member"
      end

      magic_link.mark_as_used!
      magic_link.invitation.mark_as_used!
    end

    session[:user_id] = user.id

    redirect_to root_path, notice: "Your account has been activated and you are now signed in."
  end

  private

  def magic_link_params
    params.require(:magic_link).permit(:invitation_token, :first_name, :last_name)
  end

  def magic_link_request_attributes
    magic_link_params.slice(:first_name, :last_name)
  end

  def redirect_if_logged_in
    return unless logged_in?

    redirect_to root_path, alert: "You are already signed in."
  end
end
