require "test_helper"

class RegistrationsControllerTest < ActionController::TestCase
  setup do
    @user = User.create!(
      email: "registered@example.com",
      first_name: "Registered",
      last_name: "User",
      role: "Member"
    )
    @conference = conferences(:one)
  end

  test "should create a registration for the signed-in user" do
    session[:user_id] = @user.id

    assert_difference("Registration.count", 1) do
      post :create, params: { registration: { attendance_mode: "physical" } }
    end

    registration = Registration.last
    assert_equal @user, registration.user
    assert_equal @conference, registration.conference
    assert registration.attending_physically?
    assert_redirected_to root_url
  end

  test "should reject registration without attendance mode" do
    session[:user_id] = @user.id

    assert_no_difference("Registration.count") do
      post :create, params: { registration: { attendance_mode: "" } }
    end

    assert_redirected_to root_url
  end

  test "should remove an existing registration" do
    session[:user_id] = @user.id
    registration = Registration.create!(user: @user, conference: @conference, attending_physically: false)

    assert_difference("Registration.count", -1) do
      delete :destroy
    end

    assert_not Registration.exists?(registration.id)
    assert_redirected_to root_url
  end
end
