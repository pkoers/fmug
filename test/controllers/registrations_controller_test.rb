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
      post :create, params: {
        registration: {
          attendance_mode: "physical",
          agenda_present: "1",
          agenda_question: "0",
          agenda_something_else: "1",
          agenda_something_else_text: "Open discussion about routes",
          agenda_nothing_to_present: "0",
          has_dietary_requirements: "1",
          dietary_requirements_text: "Vegetarian",
          chair_note: "A visa letter may be needed."
        }
      }
    end

    registration = Registration.last
    assert_equal @user, registration.user
    assert_equal @conference, registration.conference
    assert registration.attending_physically?
    assert registration.agenda_present?
    assert registration.agenda_something_else?
    assert_equal "Open discussion about routes", registration.agenda_something_else_text
    assert registration.has_dietary_requirements?
    assert_equal "Vegetarian", registration.dietary_requirements_text
    assert_equal "A visa letter may be needed.", registration.chair_note
    assert_redirected_to root_url
  end

  test "should reject registration without attendance mode" do
    session[:user_id] = @user.id

    assert_no_difference("Registration.count") do
      post :create, params: { registration: { attendance_mode: "", agenda_present: "1" } }
    end

    assert_redirected_to root_url
  end

  test "should remove an existing registration" do
    session[:user_id] = @user.id
    registration = Registration.create!(
      user: @user,
      conference: @conference,
      attending_physically: false,
      agenda_nothing_to_present: true
    )

    assert_difference("Registration.count", -1) do
      delete :destroy
    end

    assert_not Registration.exists?(registration.id)
    assert_redirected_to root_url
  end
end
