require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  test "cannot create schedule for non-current conference" do
    conference = Conference.create!(edition: 1, current: false)
    schedule = Schedule.new(conference: conference, date: Date.current, time: Time.current, length: 60)
    assert_not schedule.valid?
    assert_includes schedule.errors[:conference], "must be the current conference"
  end

  test "can create schedule for current conference" do
    conference = Conference.create!(edition: 1, current: true)
    schedule = Schedule.new(conference: conference, date: Date.current, time: Time.current, length: 60)
    assert schedule.valid?
  end

  test "schedule must belong to a conference" do
    schedule = Schedule.new(date: Date.current, time: Time.current, length: 60)
    assert_not schedule.valid?
    assert_includes schedule.errors[:conference], "must exist"
  end
end
