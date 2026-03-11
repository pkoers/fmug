require "test_helper"

class ConferenceTest < ActiveSupport::TestCase
  test "only one conference can be current" do
    conference2 = Conference.new(edition: 2, current: true)
    assert_not conference2.valid?
  end

  test "non-current conference cannot have schedules" do
    conference = Conference.create!(edition: 1, current: false)
    schedule = conference.schedules.build(day: 1, time: Time.current, length: 60)
    assert_not schedule.valid?
  end

  test "current conference can have schedules" do
    conference = conferences(:one)
    schedule = conference.schedules.build(day: 1, time: Time.current, length: 60)
    assert schedule.valid?
  end

  test "conference accepts supported image types" do
    conference = Conference.new(edition: 3, current: false)
    conference.image.attach(
      io: StringIO.new("fake-image"),
      filename: "conference.png",
      content_type: "image/png"
    )

    assert conference.valid?
  end
end
