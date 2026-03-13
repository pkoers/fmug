require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  test "cannot create schedule for non-current conference" do
    schedule = Schedule.new(
      conference: conferences(:two),
      day: 1,
      time: "09:00",
      length: 60,
      description: "Past conference session"
    )

    assert_not schedule.valid?
    assert_includes schedule.errors[:conference], "must be the current conference"
  end

  test "can create schedule for current conference" do
    schedule = Schedule.new(
      conference: conferences(:one),
      day: 1,
      time: "09:00",
      length: 60,
      description: "Current conference session"
    )

    assert schedule.valid?
  end

  test "schedule must belong to a conference" do
    schedule = Schedule.new(day: 1, time: "09:00", length: 60, description: "Session without conference")

    assert_not schedule.valid?
    assert_includes schedule.errors[:conference], "must exist"
  end
end
