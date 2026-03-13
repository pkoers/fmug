require "test_helper"

class SchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = schedules(:one)
    @current_conference = conferences(:one)
  end

  test "should get index" do
    get schedules_url
    assert_response :success
  end

  test "should get new" do
    get new_schedule_url
    assert_response :success
  end

  test "should create schedule" do
    assert_difference("Schedule.count") do
      post schedules_url, params: {
        schedule: {
          conference_id: @current_conference.id,
          day: 1,
          time: "10:30",
          length: 45,
          description: "New session"
        }
      }
    end

    assert_redirected_to schedule_url(Schedule.last)
  end

  test "should show schedule" do
    get schedule_url(@schedule)
    assert_response :success
  end

  test "should get edit" do
    get edit_schedule_url(@schedule)
    assert_response :success
  end

  test "should update schedule" do
    patch schedule_url(@schedule), params: {
      schedule: {
        conference_id: @current_conference.id,
        day: @schedule.day,
        time: @schedule.time.strftime("%H:%M"),
        length: 90,
        description: "Updated description"
      }
    }

    assert_redirected_to schedule_url(@schedule)
    assert_equal "Updated description", @schedule.reload.description
    assert_equal 90, @schedule.length
  end

  test "should destroy schedule" do
    assert_difference("Schedule.count", -1) do
      delete schedule_url(@schedule)
    end

    assert_redirected_to schedules_url
  end
end
