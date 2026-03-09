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
      attending_physically: true
    )

    assert registration.valid?
  end

  test "registration requires the physical attendance flag" do
    registration = Registration.new(user: @user, conference: @conference)

    assert_not registration.valid?
    assert_includes registration.errors[:attending_physically], "is not included in the list"
  end

  test "user can only register once per conference" do
    Registration.create!(user: @user, conference: @conference, attending_physically: true)
    duplicate = Registration.new(user: @user, conference: @conference, attending_physically: false)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
