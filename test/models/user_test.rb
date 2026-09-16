require "test_helper"
require "stringio"

class UserTest < ActiveSupport::TestCase
  test "user is valid without a role" do
    user = User.new(
      email: "member@example.com",
      first_name: "Member",
      last_name: "User"
    )

    assert user.valid?
  end

  test "user accepts supported profile picture formats" do
    %w[image/png image/jpeg image/jpg image/webp].each do |content_type|
      user = User.new(email: "#{content_type.delete('/')}-member@example.com", first_name: "Member", last_name: "User")
      user.photo.attach(io: StringIO.new("photo"), filename: "photo", content_type: content_type)

      assert user.valid?, "expected #{content_type} to be accepted"
    end
  end

  test "user rejects profile picture larger than 0.5 MB" do
    user = User.new(email: "member@example.com", first_name: "Member", last_name: "User")
    user.photo.attach(
      io: StringIO.new("x" * (User::PHOTO_MAXIMUM_SIZE + 1)),
      filename: "photo.png",
      content_type: "image/png"
    )

    assert_not user.valid?
    assert_includes user.errors[:photo], "must be 0.5 MB or smaller"
  end

  test "user accepts profile picture at the maximum size" do
    user = User.new(email: "member@example.com", first_name: "Member", last_name: "User")
    user.photo.attach(
      io: StringIO.new("x" * User::PHOTO_MAXIMUM_SIZE),
      filename: "photo.png",
      content_type: "image/png"
    )

    assert user.valid?
  end
end
