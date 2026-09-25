require "test_helper"

class RegistrationCampaignStartConcurrencyTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    @admin = User.create!(email: "campaign-start-admin@example.com", first_name: "Admin", last_name: "User", role: "Member", admin: true)
    @conference = conferences(:one)
  end

  teardown do
    RegistrationCampaign.where(conference: @conference).destroy_all
    @admin.destroy!
  end

  test "concurrent starts create only one active campaign" do
    ready = Queue.new
    release = Queue.new
    results = Queue.new

    threads = 2.times.map do
      Thread.new do
        conference = Conference.find(@conference.id)
        ready << true
        release.pop
        campaign, created = RegistrationCampaign.start_for!(conference:, created_by: @admin)
        results << [ campaign.id, created ]
      end
    end

    2.times { ready.pop }
    2.times { release << true }
    threads.each(&:join)

    started_campaigns = 2.times.map { results.pop }
    assert_equal 1, started_campaigns.count { |_id, created| created }
    assert_equal 1, started_campaigns.map(&:first).uniq.count
    assert RegistrationCampaign.active_for(@conference)
    assert_equal 1, @conference.registration_campaigns.count
  end
end
