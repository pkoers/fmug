require "test_helper"
require "stringio"

class LeadershipProfilesHelperTest < ActionView::TestCase
  test "uses a 144 by 144 crop variant for an uploaded leadership photo" do
    profile = LeadershipProfile.new
    profile.chair_photo.attach(io: StringIO.new("chair"), filename: "chair.png", content_type: "image/png")

    source = leadership_avatar_source(profile, :chair)

    assert_equal [ 144, 144 ], source.variation.transformations[:resize_to_fill]
  end
end
