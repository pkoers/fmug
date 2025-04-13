require "test_helper"

class ConferenceTest < ActiveSupport::TestCase
  test "only one conference can be current" do
    conference1 = Conference.create!(edition: 1, current: true)
    conference2 = Conference.new(edition: 2, current: true)
    assert_not conference2.valid?
  end

  test "non-current conference cannot have schedules" do
    conference = Conference.create!(edition: 1, current: false)
    schedule = conference.schedules.build(date: Date.current, time: Time.current, length: 60)
    assert_not schedule.valid?
  end

  test "current conference can have schedules" do
    conference = Conference.create!(edition: 1, current: true)
    schedule = conference.schedules.build(date: Date.current, time: Time.current, length: 60)
    assert schedule.valid?
  end
end
