require "test_helper"

class SchedulesControllerTest < ActionController::TestCase
  setup do
    @schedule = schedules(:one)
    @current_conference = conferences(:one)
    @admin = User.create!(
      email: "admin@example.com",
      first_name: "Admin",
      last_name: "User",
      role: "Member",
      admin: true
    )
    @member = User.create!(
      email: "member@example.com",
      first_name: "Member",
      last_name: "User",
      role: "Member"
    )
  end

  test "redirects guests away from agenda management" do
    get :index

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform that action.", flash[:alert]
  end

  test "redirects non-admins away from agenda management" do
    session[:user_id] = @member.id

    get :index

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform that action.", flash[:alert]
  end

  test "allows public access to the published agenda" do
    get :agenda

    assert_response :success
  end

  test "should get index" do
    session[:user_id] = @admin.id

    get :index
    assert_response :success
  end

  test "should get new" do
    session[:user_id] = @admin.id

    get :new
    assert_response :success
  end

  test "should create schedule" do
    session[:user_id] = @admin.id

    assert_difference("Schedule.count") do
      post :create, params: {
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
    session[:user_id] = @admin.id

    get :show, params: { id: @schedule.id }
    assert_response :success
  end

  test "should get edit" do
    session[:user_id] = @admin.id

    get :edit, params: { id: @schedule.id }
    assert_response :success
  end

  test "should update schedule" do
    session[:user_id] = @admin.id

    patch :update, params: {
      id: @schedule.id,
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
    session[:user_id] = @admin.id

    assert_difference("Schedule.count", -1) do
      delete :destroy, params: { id: @schedule.id }
    end

    assert_redirected_to schedules_url
  end
end
