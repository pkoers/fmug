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

  test "normalizes email addresses and rejects case-insensitive duplicates" do
    user = User.create!(email: " Member@Example.COM ", first_name: "Member", last_name: "User", role: "Member")
    duplicate = User.new(email: "MEMBER@example.com", first_name: "Duplicate", last_name: "User", role: "Member")

    assert_equal "member@example.com", user.email
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "database rejects case-insensitive duplicates that bypass model validation" do
    now = Time.current
    User.insert_all!([ {
      email: "RaceMember@Example.com",
      first_name: "Race",
      last_name: "Member",
      role: "Member",
      created_at: now,
      updated_at: now
    } ])

    assert_raises ActiveRecord::RecordNotUnique do
      User.insert_all!([ {
        email: "racemember@example.com",
        first_name: "Duplicate",
        last_name: "Member",
        role: "Member",
        created_at: now,
        updated_at: now
      } ])
    end
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
    assert user.errors.of_kind?(:photo, :too_large)
    assert_includes user.errors[:photo], "must be 0.5 MB or smaller"
  end

  test "user rejects unsupported profile picture formats" do
    user = User.new(email: "member@example.com", first_name: "Member", last_name: "User")
    user.photo.attach(io: StringIO.new("photo"), filename: "photo.gif", content_type: "image/gif")

    assert_not user.valid?
    assert user.errors.of_kind?(:photo, :unsupported_format)
    assert_includes user.errors[:photo], "must be a PNG, JPG, JPEG, or WEBP"
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
