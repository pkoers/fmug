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

  test "registration list requires the admin flag before looking up conferences" do
    registration = @user.registrations.create!(conference: @conference, attending_physically: true, agenda_present: true, chair_note: "Private answer")
    [ nil, @user.id ].each do |user_id|
      @user.update!(role: "Admin")
      session[:user_id] = user_id
      get :index, params: { conference_id: @conference.id }
      assert_redirected_to root_path
      assert_not_includes response.body, registration.chair_note
      get :index, params: { conference_id: 0 }
      assert_redirected_to root_path
    end
  end

  test "admins see all current registration answers without mutation or email" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    registration = @user.registrations.create!(conference: @conference, attending_physically: true,
      agenda_present: true, agenda_question: true, agenda_something_else: true,
      agenda_something_else_text: "Workshop\nDiscussion", has_dietary_requirements: true,
      dietary_requirements_text: "Vegetarian", chair_note: "Please contact me", created_at: Time.zone.local(2026, 1, 2))
    @user.registrations.create!(conference: conferences(:two), attending_physically: false, agenda_present: true, chair_note: "Other conference secret")
    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**) { flunk "Read-only page must not send email" }) do
      assert_no_changes -> { registration.reload.attributes } do
        assert_no_difference("Registration.count") { get :index, params: { conference_id: @conference.id } }
      end
    end
    assert_response :success
    [ "Registered User", @user.email, "Jan 2, 2026", "Physical attendance", "Present / Pitch an idea to the community",
      "Ask a question/discuss a topic", "Something else: Workshop", "Discussion", "Dietary requirements: Vegetarian", "Please contact me" ].each do |answer|
      assert_includes response.body, answer
    end
    assert_not_includes response.body, "Other conference secret"
    assert_select "#registrations article", count: 1
    assert_select "a[href=?]", conferences_path, text: "Back to conferences"
  end

  test "registration list rejects missing non-current and stale conference ids" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    [ 0, conferences(:two).id ].each do |id|
      assert_raises(ActiveRecord::RecordNotFound) { get :index, params: { conference_id: id } }
    end
    @conference.update!(current: false)
    assert_raises(ActiveRecord::RecordNotFound) { get :index, params: { conference_id: @conference.id } }
    conferences(:two).update!(current: true)
    assert_raises(ActiveRecord::RecordNotFound) { get :index, params: { conference_id: @conference.id } }
  end

  test "registration list has an empty state and excludes unregistered members" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    get :index, params: { conference_id: @conference.id }
    assert_response :success
    assert_select "#registrations", text: /No registrations yet for this conference/
    assert_select "#registrations article", count: 0
    assert_select "a[href=?]", conferences_path, text: "Back to conferences"
  end

  test "registration list orders names and handles online blank and legacy answers" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    names = [ [ "Zoe", "A" ], [ "Amy", "Z" ], [ "Amy", "A" ], [ "Amy", "A" ] ]
    registrations = names.each_with_index.map do |(first, last), index|
      user = User.create!(first_name: first, last_name: last, email: "list#{index}@example.com", role: "Member")
      user.registrations.create!(conference: @conference, attending_physically: false, agenda_nothing_to_present: true)
    end
    registrations.first.update_columns(agenda_nothing_to_present: false)
    get :index, params: { conference_id: @conference.id }
    assert_equal [ "Amy A", "Amy A", "Amy Z", "Zoe A" ], css_select("#registrations h2").map(&:text)
    assert_equal [ "list2@example.com", "list3@example.com", "list1@example.com", "list0@example.com" ], css_select("#registrations article > p").map(&:text)
    [ "Online attendance", "Nothing to present", "No agenda selections provided", "No dietary requirements", "No message provided" ].each { |answer| assert_includes response.body, answer }
  end

  test "registration list escapes member supplied text" do
    @user.update!(admin: true, first_name: "<script>alert(1)</script>")
    session[:user_id] = @user.id
    @user.registrations.create!(conference: @conference, attending_physically: true, agenda_something_else: true,
      agenda_something_else_text: "<script>agenda</script>", has_dietary_requirements: true,
      dietary_requirements_text: "<script>diet</script>", chair_note: "<script>chair</script>")
    get :index, params: { conference_id: @conference.id }
    assert_select "#registrations script", count: 0
    [ "alert(1)", "agenda", "diet", "chair" ].each { |value| assert_includes response.body, "&lt;script&gt;#{value}&lt;/script&gt;" }
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
