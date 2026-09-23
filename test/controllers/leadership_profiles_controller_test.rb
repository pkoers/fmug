require "test_helper"

class LeadershipProfilesControllerTest < ActionController::TestCase
  setup do
    @admin = User.create!(email: "admin@example.com", first_name: "Admin", last_name: "User", role: "Member", admin: true)
    @member = User.create!(email: "member@example.com", first_name: "Member", last_name: "User", role: "Member")
  end

  test "admin can save both display names" do
    sign_in_as(@admin)

    patch :update, params: { leadership_profile: { chair_name: "Ada Chair", vice_chair_name: "Grace Vice" } }

    assert_redirected_to users_path
    assert_equal "Leadership profiles were updated.", flash[:notice]
    assert_equal "Ada Chair", LeadershipProfile.first.chair_name
    assert_equal "Grace Vice", LeadershipProfile.first.vice_chair_name
  end

  test "admin can upload initial photos for both leadership profiles" do
    sign_in_as(@admin)

    patch :update, params: {
      leadership_profile: {
        chair_photo: uploaded_photo(filename: "chair.png", content_type: "image/png"),
        vice_chair_photo: uploaded_photo(filename: "vice-chair.webp", content_type: "image/webp")
      }
    }

    assert_redirected_to users_path
    assert LeadershipProfile.first.chair_photo.attached?
    assert LeadershipProfile.first.vice_chair_photo.attached?
  end

  test "admin can upload and replace each leadership photo" do
    profile = LeadershipProfile.create!
    profile.chair_photo.attach(io: StringIO.new("original-chair"), filename: "chair.png", content_type: "image/png")
    profile.vice_chair_photo.attach(io: StringIO.new("original-vice"), filename: "vice-chair.png", content_type: "image/png")
    chair_blob_id = profile.chair_photo.blob.id
    vice_chair_blob_id = profile.vice_chair_photo.blob.id
    sign_in_as(@admin)

    patch :update, params: {
      leadership_profile: {
        chair_photo: uploaded_photo(filename: "replacement-chair.webp", content_type: "image/webp"),
        vice_chair_photo: uploaded_photo(filename: "replacement-vice.jpg", content_type: "image/jpeg")
      }
    }

    assert_redirected_to users_path
    assert_equal "image/webp", profile.reload.chair_photo.blob.content_type
    assert_equal "image/jpeg", profile.vice_chair_photo.blob.content_type
    assert_not_equal chair_blob_id, profile.chair_photo.blob.id
    assert_not_equal vice_chair_blob_id, profile.vice_chair_photo.blob.id
  end

  test "invalid replacement preserves the current leadership photo" do
    profile = LeadershipProfile.create!
    profile.chair_photo.attach(io: StringIO.new("original"), filename: "chair.png", content_type: "image/png")
    chair_blob_id = profile.chair_photo.blob.id
    sign_in_as(@admin)

    patch :update, params: { leadership_profile: { chair_photo: uploaded_photo(filename: "chair.gif", content_type: "image/gif") } }

    assert_redirected_to users_path
    assert_equal "Chair photo must be a PNG, JPG, JPEG, or WEBP", flash[:alert]
    assert_equal chair_blob_id, profile.reload.chair_photo.blob.id
  end

  test "submitting without a photo preserves current leadership photos" do
    profile = LeadershipProfile.create!(chair_name: "Original")
    profile.chair_photo.attach(io: StringIO.new("original"), filename: "chair.png", content_type: "image/png")
    chair_blob_id = profile.chair_photo.blob.id
    sign_in_as(@admin)

    patch :update, params: { leadership_profile: { chair_name: "Updated" } }

    assert_redirected_to users_path
    assert_equal "Updated", profile.reload.chair_name
    assert_equal chair_blob_id, profile.chair_photo.blob.id
  end

  test "admin can remove either leadership photo independently" do
    profile = LeadershipProfile.create!
    profile.chair_photo.attach(io: StringIO.new("chair"), filename: "chair.png", content_type: "image/png")
    profile.vice_chair_photo.attach(io: StringIO.new("vice-chair"), filename: "vice-chair.png", content_type: "image/png")
    sign_in_as(@admin)

    delete :chair_photo

    assert_redirected_to users_path
    assert_not profile.reload.chair_photo.attached?
    assert profile.vice_chair_photo.attached?

    delete :vice_chair_photo

    assert_redirected_to users_path
    assert_not profile.reload.vice_chair_photo.attached?
  end

  test "guests cannot update or remove leadership profiles" do
    patch :update, params: { leadership_profile: { chair_name: "Ada Chair" } }

    assert_redirected_to root_path
    assert_nil LeadershipProfile.first

    delete :chair_photo

    assert_redirected_to root_path
  end

  test "non-admin members cannot update or remove leadership profiles" do
    sign_in_as(@member)

    patch :update, params: { leadership_profile: { chair_name: "Ada Chair" } }

    assert_redirected_to root_path
    assert_nil LeadershipProfile.first

    delete :vice_chair_photo

    assert_redirected_to root_path
  end

  private

  def sign_in_as(user)
    session[:user_id] = user.id
  end

  def uploaded_photo(filename:, content_type:)
    fixture_file_upload("profile-picture.png", content_type, original_filename: filename)
  end
end
