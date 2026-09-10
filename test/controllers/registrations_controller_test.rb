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

  test "admins see all answers for current registrations without mutations or email" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    registration = create_registration(
      agenda_present: true, agenda_question: true, agenda_something_else: true,
      agenda_something_else_text: "Workshop\nSecond topic",
      has_dietary_requirements: true, dietary_requirements_text: "Vegetarian\nNo nuts",
      chair_note: "Please call\nAfter lunch", created_at: Time.zone.local(2026, 9, 1)
    )
    outsider = User.create!(email: "outsider@example.com", first_name: "Outside", last_name: "Member", role: "Member")
    create_registration(user: outsider, conference: conferences(:two), chair_note: "Other conference secret")
    User.create!(email: "unregistered@example.com", first_name: "Unregistered", last_name: "Member", role: "Member")
    before = Registration.order(:id).map(&:attributes)

    with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**) { flunk "GET must not send email" }) do
      get :index, params: { conference_id: @conference.id }
    end

    assert_response :success
    assert_equal before, Registration.order(:id).map(&:attributes)
    assert_select "article", count: 1
    assert_select "#registration_#{registration.id}" do
      [ "Registered User", @user.email, "Physical attendance", "Present / Pitch an idea to the community",
        "Ask a question/discuss a topic", "Something else: Workshop\nSecond topic", "Nothing to present",
        "Dietary requirements: Vegetarian\nNo nuts", "Please call\nAfter lunch", "September 01, 2026" ].each do |answer|
        assert_includes response.body, answer
      end
    end
    assert_not_includes response.body, outsider.email
    assert_not_includes response.body, "Other conference secret"
    assert_not_includes response.body, "unregistered@example.com"
    assert_select "a[href=?]", conferences_path, text: "Back to conferences"
    assert_select "article img", count: 0
  end

  test "guests and non-admins including admin role text cannot read registrations" do
    create_registration(chair_note: "Private chair note")
    @user.update!(role: "Admin")
    [ nil, @user.id ].each do |user_id|
      session[:user_id] = user_id
      get :index, params: { conference_id: @conference.id }
      assert_redirected_to root_path
      assert_not_includes response.body, @user.email
      assert_not_includes response.body, "Private chair note"
      assert_select "article", count: 0
    end
  end

  test "unknown non-current and stale conference IDs are not found" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    [ Conference.maximum(:id) + 1, conferences(:two).id ].each do |id|
      assert_raises(ActiveRecord::RecordNotFound) { get :index, params: { conference_id: id } }
    end
    @conference.update!(current: false)
    assert_raises(ActiveRecord::RecordNotFound) { get :index, params: { conference_id: @conference.id } }
    conferences(:two).update!(current: true)
    assert_raises(ActiveRecord::RecordNotFound) { get :index, params: { conference_id: @conference.id } }
  end

  test "online legacy registrations and blank optional answers are readable" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    registration = create_registration(attending_physically: false)
    registration.update_columns(agenda_nothing_to_present: false)
    get :index, params: { conference_id: @conference.id }

    assert_response :success
    assert_includes response.body, "Online attendance"
    assert_includes response.body, "No agenda selections recorded"
    assert_includes response.body, "No dietary requirements"
    assert_includes response.body, "Not provided"

    registration.update_columns(agenda_something_else: true)
    get :index, params: { conference_id: @conference.id }
    assert_includes response.body, "No additional details provided"
  end

  test "registrations are ordered by first name last name then registration id" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    records = [ [ "Zoe", "Alpha" ], [ "Amy", "Zulu" ], [ "Amy", "Alpha" ], [ "Amy", "Alpha" ] ].each_with_index.map do |(first, last), i|
      user = User.create!(email: "ordered#{i}@example.com", first_name: first, last_name: last, role: "Member")
      create_registration(user: user)
    end

    get :index, params: { conference_id: @conference.id }

    assert_equal [ records[2], records[3], records[1], records[0] ].map { |record| "registration_#{record.id}" },
      css_select("article").map { |article| article["id"] }
  end

  test "member entered content is escaped" do
    payload = '<script>alert("private")</script>'
    @user.update!(admin: true, first_name: payload, last_name: payload, email: "#{payload}@example.com")
    session[:user_id] = @user.id
    create_registration(agenda_something_else: true, agenda_something_else_text: payload,
      has_dietary_requirements: true, dietary_requirements_text: payload, chair_note: payload)

    get :index, params: { conference_id: @conference.id }

    assert_select "article script", count: 0
    assert_not_includes response.body, payload
    assert_includes response.body, ERB::Util.html_escape(payload)
    assert_select "article h2", text: "#{payload} #{payload}"
  end

  test "empty current conference has return navigation" do
    @user.update!(admin: true)
    session[:user_id] = @user.id
    get :index, params: { conference_id: @conference.id }

    assert_response :success
    assert_includes response.body, "No registrations yet for this conference"
    assert_select "a[href=?]", conferences_path, text: "Back to conferences"
  end

  private

  def create_registration(**attributes)
    Registration.create!({ user: @user, conference: @conference, attending_physically: true,
      agenda_nothing_to_present: true }.merge(attributes))
  end

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
