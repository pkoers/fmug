require "test_helper"
require "stringio"

class ConferencesControllerTest < ActionController::TestCase
  setup do
    @conference = conferences(:one)
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

  test "redirects guests away from conference management" do
    get :index

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform that action.", flash[:alert]
  end

  test "redirects non-admins away from conference management" do
    session[:user_id] = @member.id

    get :index

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform that action.", flash[:alert]
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

  test "should create conference" do
    session[:user_id] = @admin.id

    assert_difference("Conference.count") do
      post :create, params: {
        conference: {
          edition: 2,
          start_date: Date.current,
          end_date: Date.current + 2.days,
          host: "Test Host",
          location: "Test Location",
          current: false
        }
      }
    end

    assert_redirected_to conference_url(Conference.last)
  end

  test "should show conference" do
    session[:user_id] = @admin.id

    get :show, params: { id: @conference.id }
    assert_response :success
  end

  test "should get edit" do
    session[:user_id] = @admin.id

    get :edit, params: { id: @conference.id }
    assert_response :success
  end

  test "should update conference" do
    session[:user_id] = @admin.id

    patch :update, params: {
      id: @conference.id,
      conference: {
        edition: @conference.edition,
        start_date: @conference.start_date,
        end_date: @conference.end_date,
        host: @conference.host,
        location: @conference.location,
        current: @conference.current
      }
    }
    assert_redirected_to conference_url(@conference)
  end

  test "should destroy conference" do
    session[:user_id] = @admin.id

    assert_difference("Conference.count", -1) do
      delete :destroy, params: { id: @conference.id }
    end

    assert_redirected_to conferences_url
  end

  test "should remove conference image" do
    session[:user_id] = @admin.id
    @conference.image.attach(
      io: StringIO.new("fake-image"),
      filename: "conference.png",
      content_type: "image/png"
    )

    patch :update, params: {
      id: @conference.id,
      conference: {
        edition: @conference.edition,
        start_date: @conference.start_date,
        end_date: @conference.end_date,
        host: @conference.host,
        location: @conference.location,
        current: @conference.current,
        remove_image: "1"
      }
    }

    assert_redirected_to conference_url(@conference)
    assert_not @conference.reload.image.attached?
  end
end
