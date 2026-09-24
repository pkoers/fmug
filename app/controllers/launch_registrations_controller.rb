class LaunchRegistrationsController < ApplicationController
  before_action :set_campaign
  before_action :require_active_campaign

  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = @campaign.invitations.build(
      invitation_attributes.merge(
        conference: @campaign.conference,
        inviter: @campaign.created_by
      )
    )

    unless @invitation.valid?
      render :new, status: :unprocessable_entity
      return
    end

    magic_link = nil
    created = false
    ActiveRecord::Base.transaction do
      @campaign.lock!
      next unless @campaign.accepting_registrations?
      next if User.exists?(email: @invitation.email)

      @invitation.save!
      magic_link = @invitation.magic_links.create!(magic_link_attributes)
      created = true
    end

    unless created
      redirect_to launch_registration_path(params[:token]), notice: submission_notice
      return
    end

    EmailDeliveryService.notify(
      to: @invitation.email,
      subject: helpers.magic_link_email_subject,
      body: helpers.magic_link_email_body(magic_link),
      html_body: helpers.magic_link_email_html_body(magic_link),
      from_name: "FMUG Chair",
      from_email: "chair@fmug.eu",
      delivery: :brevo
    )

    redirect_to launch_registration_path(params[:token]), notice: submission_notice
  rescue ActiveRecord::RecordNotUnique
    redirect_to launch_registration_path(params[:token]), notice: submission_notice
  end

  private

  def set_campaign
    @campaign = RegistrationCampaign.find_by_token(params[:token])
  end

  def require_active_campaign
    return if @campaign&.accepting_registrations?

    render :unavailable, status: :unprocessable_entity
  end

  def invitation_attributes
    params.require(:launch_registration).permit(:first_name, :email)
  end

  def magic_link_attributes
    params.require(:launch_registration).permit(:first_name, :last_name, :company_name)
  end

  def submission_notice
    "If your details are eligible, an activation link will arrive shortly. Existing members can use Login."
  end
end
