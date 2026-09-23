require "test_helper"
require "stringio"

class LeadershipProfileTest < ActiveSupport::TestCase
  test "accepts supported Chair and Vice-Chair photo formats" do
    %w[image/png image/jpeg image/jpg image/webp].each do |content_type|
      profile = LeadershipProfile.new
      profile.chair_photo.attach(io: StringIO.new("photo"), filename: "chair", content_type: content_type)
      profile.vice_chair_photo.attach(io: StringIO.new("photo"), filename: "vice-chair", content_type: content_type)

      assert profile.valid?, "expected #{content_type} to be accepted for both leadership photos"
    end
  end

  test "accepts leadership photos at the maximum size" do
    profile = LeadershipProfile.new
    profile.chair_photo.attach(
      io: StringIO.new("x" * ImageAttachmentValidations::PHOTO_MAXIMUM_SIZE),
      filename: "chair.png",
      content_type: "image/png"
    )
    profile.vice_chair_photo.attach(
      io: StringIO.new("x" * ImageAttachmentValidations::PHOTO_MAXIMUM_SIZE),
      filename: "vice-chair.png",
      content_type: "image/png"
    )

    assert profile.valid?
  end

  test "rejects oversized leadership photos" do
    profile = LeadershipProfile.new
    profile.chair_photo.attach(
      io: StringIO.new("x" * (ImageAttachmentValidations::PHOTO_MAXIMUM_SIZE + 1)),
      filename: "chair.png",
      content_type: "image/png"
    )

    assert_not profile.valid?
    assert profile.errors.of_kind?(:chair_photo, :too_large)
  end

  test "rejects unsupported leadership photos" do
    profile = LeadershipProfile.new
    profile.vice_chair_photo.attach(io: StringIO.new("photo"), filename: "vice-chair.gif", content_type: "image/gif")

    assert_not profile.valid?
    assert profile.errors.of_kind?(:vice_chair_photo, :unsupported_format)
  end
end
