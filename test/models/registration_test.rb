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

  test "registration is valid with each attendance status" do
    registration = Registration.new(
      user: @user,
      conference: @conference,
      attendance_status: "physical",
      agenda_present: true
    )

    assert registration.valid?
    assert registration.attending_physically?

    registration.attendance_status = "online"
    assert registration.valid?
    assert_not registration.attending_physically?

    registration.attendance_status = "awaiting_travel_approval"
    assert registration.valid?
    assert_not registration.attending_physically?
  end

  test "registration requires a valid attendance status" do
    registration = Registration.new(user: @user, conference: @conference, agenda_present: true)

    assert_not registration.valid?
    assert_includes registration.errors[:attendance_status], "is not included in the list"

    registration.attendance_status = "unknown"
    assert_not registration.valid?
    assert_includes registration.errors[:attendance_status], "is not included in the list"
  end

  test "database constraint rejects an invalid attendance status" do
    registration = Registration.create!(
      user: @user,
      conference: @conference,
      attendance_status: "physical",
      agenda_present: true
    )

    Registration.transaction(requires_new: true) do
      assert_raises(ActiveRecord::StatementInvalid) do
        registration.update_column(:attendance_status, "unknown")
      end

      raise ActiveRecord::Rollback
    end
    assert_equal "physical", registration.reload.attendance_status
  end

  test "database constraint rejects incompatible attendance status and legacy flag combinations" do
    [ [ "physical", false ], [ "online", true ], [ "awaiting_travel_approval", true ] ].each do |status, attending_physically|
      user = User.create!(
        email: "#{status}-#{attending_physically}@example.com",
        first_name: "Invalid",
        last_name: "Compatibility",
        role: "Member"
      )
      registration = Registration.create!(
        user: user,
        conference: @conference,
        attendance_status: "online",
        agenda_present: true
      )

      Registration.transaction(requires_new: true) do
        assert_raises(ActiveRecord::StatementInvalid) do
          registration.update_columns(attendance_status: status, attending_physically: attending_physically)
        end

        raise ActiveRecord::Rollback
      end
      assert_equal "online", registration.reload.attendance_status
      assert_not registration.attending_physically?
    end
  end

  test "user can only register once per conference" do
    Registration.create!(user: @user, conference: @conference, attendance_status: "physical", agenda_present: true)
    duplicate = Registration.new(user: @user, conference: @conference, attendance_status: "online", agenda_question: true)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "registration requires at least one agenda option" do
    registration = Registration.new(user: @user, conference: @conference, attendance_status: "physical")

    assert_not registration.valid?
    assert_includes registration.errors[:base], "Select at least one agenda option"
  end

  test "dietary requirements need details when selected" do
    registration = Registration.new(
      user: @user,
      conference: @conference,
      attendance_status: "physical",
      agenda_present: true,
      has_dietary_requirements: true,
      dietary_requirements_text: "Please specify"
    )

    assert_not registration.valid?
    assert_includes registration.errors[:dietary_requirements_text], "must be provided when dietary requirements are selected"
  end
end
