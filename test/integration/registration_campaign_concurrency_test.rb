require "test_helper"

class RegistrationCampaignConcurrencyTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    @admin = User.create!(email: "concurrency-admin@example.com", first_name: "Admin", last_name: "User", role: "Member", admin: true)
    @campaign = RegistrationCampaign.create!(
      conference: conferences(:one),
      created_by: @admin,
      successful_registrations_count: 99
    )
    @links = [ "concurrency-one@example.com", "concurrency-two@example.com" ].map do |email|
      invitation = Invitation.create!(
        conference: @campaign.conference,
        inviter: @admin,
        registration_campaign: @campaign,
        first_name: "Concurrent",
        email:
      )
      invitation.magic_links.create!(first_name: "Concurrent", last_name: "Member", company_name: "Example Airlines")
    end
  end

  teardown do
    MagicLink.where(invitation_id: @campaign.invitations.select(:id)).delete_all
    Invitation.where(registration_campaign: @campaign).delete_all
    @campaign.destroy!
    User.where(email: [ @admin.email, *@links.map { |link| link.invitation.email } ]).delete_all
  end

  test "concurrent campaign activations cannot exceed the cap" do
    ready = Queue.new
    release = Queue.new
    responses = Queue.new

    threads = @links.map do |magic_link|
      Thread.new do
        session = ActionDispatch::Integration::Session.new(Rails.application)
        ready << true
        release.pop
        session.post activate_magic_link_path, params: { token: magic_link.raw_token }
        responses << session.response.status
      end
    end

    2.times { ready.pop }
    2.times { release << true }
    threads.each(&:join)

    assert_equal [ 302, 422 ], 2.times.map { responses.pop }.sort
    assert_equal 100, @campaign.reload.successful_registrations_count
    assert_equal 1, User.where(email: @links.map { |link| link.invitation.email }).count
  end
end
