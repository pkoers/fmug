require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "notify builds the email" do
    mail = NotificationMailer.with(
      to: "member@example.com",
      subject: "FMUG update",
      body: "Conference registration is open."
    ).notify

    assert_equal [ "member@example.com" ], mail.to
    assert_equal [ ENV.fetch("MAILER_FROM_EMAIL", "noreply@fmug.local") ], mail.from
    assert_equal "FMUG update", mail.subject
    assert_includes mail.text_part.body.to_s, "Conference registration is open."
    assert_includes mail.html_part.body.to_s, "Conference registration is open."
  end
end
