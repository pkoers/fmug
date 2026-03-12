require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @inviter = User.create!(
      email: "inviter@example.com",
      first_name: "Invite",
      last_name: "Sender",
      role: "Member"
    )
    @conference = conferences(:one)
  end

  test "creates a digest-backed token with a seven day expiry" do
    freeze_time do
      invitation = Invitation.create!(
        inviter: @inviter,
        conference: @conference,
        first_name: " Guest ",
        email: "GUEST@Example.com "
      )

      assert_equal "Guest", invitation.first_name
      assert_equal "guest@example.com", invitation.email
      assert invitation.raw_token.present?
      assert_equal Invitation.digest(invitation.raw_token), invitation.token_digest
      assert_equal invitation, Invitation.find_by_token(invitation.raw_token)
      assert_in_delta 7.days.from_now.to_f, invitation.expires_at.to_f, 1.0
      assert invitation.usable?
    end
  end

  test "becomes unusable once expired or consumed" do
    invitation = Invitation.create!(
      inviter: @inviter,
      conference: @conference,
      first_name: "Guest",
      email: "guest@example.com"
    )

    invitation.update!(expires_at: 1.minute.ago)
    assert invitation.expired?
    assert_not invitation.usable?

    invitation.update!(expires_at: 7.days.from_now, used_at: nil)
    invitation.mark_as_used!
    assert_not invitation.usable?
    assert invitation.used_at.present?
  end
end
