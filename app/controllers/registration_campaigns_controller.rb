class RegistrationCampaignsController < ApplicationController
  before_action :require_admin
  before_action :set_campaign, only: [ :show, :revoke ]

  def index
    @registration_campaigns = RegistrationCampaign.includes(:conference, :created_by).order(created_at: :desc)
  end

  def new
    @registration_campaign = RegistrationCampaign.new
  end

  def create
    conference = Conference.find_by(current: true)

    unless conference
      redirect_to registration_campaigns_path, alert: "A current conference is required before creating a launch registration campaign."
      return
    end

    @registration_campaign = RegistrationCampaign.new(conference:, created_by: current_user)

    if @registration_campaign.save
      @campaign_url = launch_registration_url(@registration_campaign.raw_token)
      render :show, status: :created
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
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
