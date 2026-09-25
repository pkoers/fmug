class RegistrationCampaignsController < ApplicationController
  before_action :require_admin
  before_action :set_campaign, only: [ :show, :revoke ]

  def index
    @registration_campaigns = RegistrationCampaign.includes(:conference, :created_by).order(created_at: :desc)
    @current_conference = Conference.find_by(current: true)
    @active_campaign = RegistrationCampaign.active_for(@current_conference) if @current_conference
  end

  def new
    active_campaign = RegistrationCampaign.active_for(Conference.find_by(current: true))
    if active_campaign
      redirect_to registration_campaign_path(active_campaign), notice: "This conference already has an active launch registration campaign."
      return
    end

    @registration_campaign = RegistrationCampaign.new
  end

  def create
    conference = Conference.find_by(current: true)

    unless conference
      redirect_to registration_campaigns_path, alert: "A current conference is required before creating a launch registration campaign."
      return
    end

    @registration_campaign, created = RegistrationCampaign.start_for!(conference:, created_by: current_user)

    if created
      @campaign_url = launch_registration_url(@registration_campaign.raw_token)
      render :show, status: :created
    else
      redirect_to registration_campaign_path(@registration_campaign), notice: "This conference already has an active launch registration campaign."
    end
  end

  def show
    @active_campaign = RegistrationCampaign.active_for(@registration_campaign.conference)
  end

  def revoke
    @registration_campaign.revoke!
    redirect_to registration_campaign_path(@registration_campaign), notice: "The launch registration campaign has been revoked."
  end

  private

  def set_campaign
    @registration_campaign = RegistrationCampaign.find(params[:id])
  end
end
