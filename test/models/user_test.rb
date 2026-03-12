require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user is valid without a role" do
    user = User.new(
      email: "member@example.com",
      first_name: "Member",
      last_name: "User"
    )

    assert user.valid?
  end
end
