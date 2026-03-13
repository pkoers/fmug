class InvitationsController < ApplicationController
  before_action :require_login
  before_action :set_current_conference

  def create
    invitation = current_user.sent_invitations.build(invitation_params.merge(conference: @conference))

    if invitation.save
      EmailDeliveryService.notify(
        to: invitation.email,
        subject: helpers.invitation_email_subject(@conference),
        body: helpers.invitation_email_body(invitation, token: invitation.raw_token),
        html_body: helpers.invitation_email_html_body(invitation, token: invitation.raw_token),
        from_name: "FMUG Chair",
        from_email: "chair@fmug.eu",
        delivery: :brevo
      )

      redirect_to root_path, notice: "Invitation sent to #{invitation.email}."
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
