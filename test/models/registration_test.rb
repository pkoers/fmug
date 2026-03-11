require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "member@example.com",
      first_name: "Member",
      last_name: "User",
      role: "member"
    )
    @conference = Conference.create!(edition: 99, current: false)
  end

  test "registration is valid with a physical attendance flag" do
    registration = Registration.new(
      user: @user,
      conference: @conference,
      attending_physically: true,
      agenda_present: true
    )

    assert registration.valid?
  end

  test "registration requires the physical attendance flag" do
    registration = Registration.new(user: @user, conference: @conference, agenda_present: true)

    assert_not registration.valid?
    assert_includes registration.errors[:attending_physically], "is not included in the list"
  end

  test "user can only register once per conference" do
    Registration.create!(user: @user, conference: @conference, attending_physically: true, agenda_present: true)
    duplicate = Registration.new(user: @user, conference: @conference, attending_physically: false, agenda_question: true)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "registration requires at least one agenda option" do
    registration = Registration.new(user: @user, conference: @conference, attending_physically: true)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "Select at least one agenda option"
  end

  test "dietary requirements need details when selected" do
    registration = Registration.new(
      user: @user,
      conference: @conference,
      attending_physically: true,
      agenda_present: true,
      has_dietary_requirements: true,
      dietary_requirements_text: "Please specify"
    )

    assert_not registration.valid?
    assert_includes registration.errors[:dietary_requirements_text], "must be provided when dietary requirements are selected"
  end
end
