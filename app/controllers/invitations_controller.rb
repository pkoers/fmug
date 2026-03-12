class InvitationsController < ApplicationController
  before_action :require_login
  before_action :set_current_conference

  def create
    invitation = current_user.sent_invitations.build(invitation_params.merge(conference: @conference))

    if invitation.save
      body = helpers.invitation_email_body(invitation, token: invitation.raw_token)

      EmailDeliveryService.notify(
        to: invitation.email,
        subject: helpers.invitation_email_subject(@conference),
        body: body
      )

      flash[:invitation_email_body] = body
      redirect_to root_path, notice: "Invitation prepared for #{invitation.email}."
    else
      redirect_to root_path, alert: invitation.errors.full_messages.to_sentence
    end
  end

  private

  def set_current_conference
    @conference = Conference.find_by(current: true)

    return if @conference.present?

    redirect_to root_path, alert: "There is no current conference open for registration."
  end

  def invitation_params
    params.require(:invitation).permit(:first_name, :email)
  end
end
