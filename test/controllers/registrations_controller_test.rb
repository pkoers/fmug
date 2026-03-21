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
    delivery_payload = nil

    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**kwargs) {
      delivery_payload = kwargs
      { "messageId" => "<brevo@example.com>" }
    }) do
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
    assert_equal "registered@example.com", delivery_payload[:to]
    assert_equal "Registration confirmed for Conference 1", delivery_payload[:subject]
    assert_equal :brevo, delivery_payload[:delivery]
    assert_equal "FMUG Chair", delivery_payload[:from_name]
    assert_equal "chair@fmug.eu", delivery_payload[:from_email]
    assert_includes delivery_payload[:html_body], "<ul>"
    assert_redirected_to root_url
    assert_equal "You are registered for Conference 1. A confirmation email has been sent to registered@example.com.", flash[:notice]
  end

  test "should reject registration without attendance mode" do
    session[:user_id] = @user.id

    assert_no_difference("Registration.count") do
      post :create, params: { registration: { attendance_mode: "", agenda_present: "1" } }
    end

    assert_redirected_to root_url
  end

  test "should reject registration without an agenda selection instead of crashing" do
    session[:user_id] = @user.id

    assert_no_difference("Registration.count") do
      post :create, params: {
        registration: {
          attendance_mode: "physical",
          agenda_present: "0",
          agenda_question: "0",
          agenda_something_else: "0",
          agenda_nothing_to_present: "0"
        }
      }
    end

    assert_redirected_to root_url
    assert_equal "Select at least one agenda option", flash[:alert]
  end

  test "should reject registration with missing dietary details instead of crashing" do
    session[:user_id] = @user.id

    assert_no_difference("Registration.count") do
      post :create, params: {
        registration: {
          attendance_mode: "physical",
          agenda_present: "1",
          has_dietary_requirements: "1",
          dietary_requirements_text: "Please specify"
        }
      }
    end

    assert_redirected_to root_url
    assert_equal "Dietary requirements text must be provided when dietary requirements are selected", flash[:alert]
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

  private

  def with_replaced_singleton_method(object, method_name, implementation)
    singleton_class = object.singleton_class
    original_method = singleton_class.instance_method(method_name) if singleton_class.method_defined?(method_name)

    singleton_class.define_method(method_name, implementation)
    yield
  ensure
    if original_method
      singleton_class.define_method(method_name, original_method)
    else
      singleton_class.remove_method(method_name)
    end
  end
end
