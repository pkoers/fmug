require "test_helper"

class ProfilePicturesControllerTest < ActionController::TestCase
  setup do
    @member = User.create!(
      email: "member@example.com",
      first_name: "Ada",
      last_name: "Lovelace",
      role: "Member"
    )
    @other_member = User.create!(
      email: "other@example.com",
      first_name: "Grace",
      last_name: "Hopper",
      role: "Member"
    )
  end

  test "member can upload a supported profile picture" do
    session[:user_id] = @member.id

    patch :update, params: { profile_picture: { photo: uploaded_photo(content_type: "image/png") } }

    assert_redirected_to users_path
    assert_equal "Your profile picture was updated.", flash[:notice]
    assert @member.reload.photo.attached?
    assert_equal "image/png", @member.photo.blob.content_type
  end

  test "member can replace a profile picture" do
    @member.photo.attach(io: StringIO.new("original"), filename: "original.png", content_type: "image/png")
    original_blob_id = @member.photo.blob.id
    session[:user_id] = @member.id

    patch :update, params: { profile_picture: { photo: uploaded_photo(content_type: "image/webp", filename: "replacement.webp") } }

    assert_redirected_to users_path
    assert @member.reload.photo.attached?
    assert_equal "image/webp", @member.photo.blob.content_type
    assert_not_equal original_blob_id, @member.photo.blob.id
  end

  test "member can remove a profile picture" do
    @member.photo.attach(io: StringIO.new("photo"), filename: "photo.png", content_type: "image/png")
    session[:user_id] = @member.id

    delete :destroy

    assert_redirected_to users_path
    assert_equal "Your profile picture was removed.", flash[:notice]
    assert_not @member.reload.photo.attached?
  end

  test "does not remove a profile picture when no replacement is selected" do
    @member.photo.attach(io: StringIO.new("original"), filename: "original.png", content_type: "image/png")
    original_blob_id = @member.photo.blob.id
    session[:user_id] = @member.id

    patch :update, params: { profile_picture: { photo: nil } }

    assert_redirected_to users_path
    assert_equal "Choose a profile picture to upload.", flash[:alert]
    assert_equal original_blob_id, @member.reload.photo.blob.id
  end

  test "rejects unsupported profile picture types without replacing the current picture" do
    @member.photo.attach(io: StringIO.new("original"), filename: "original.png", content_type: "image/png")
    original_blob_id = @member.photo.blob.id
    session[:user_id] = @member.id

    patch :update, params: { profile_picture: { photo: uploaded_photo(content_type: "image/gif", filename: "photo.gif") } }

    assert_redirected_to users_path
    assert_equal "Your profile picture must be a PNG, JPEG/JPG, or WebP image. Please choose a supported image.", flash[:alert]
    assert_equal original_blob_id, @member.reload.photo.blob.id
  end

  test "rejects oversized profile pictures without replacing the current picture" do
    @member.photo.attach(io: StringIO.new("original"), filename: "original.png", content_type: "image/png")
    original_blob_id = @member.photo.blob.id
    session[:user_id] = @member.id

    patch :update, params: { profile_picture: { photo: uploaded_photo(content_type: "image/png", size: User::PHOTO_MAXIMUM_SIZE + 1) } }

    assert_redirected_to users_path
    assert_equal "Your profile picture exceeds the 0.5 MB maximum. Please choose a smaller image.", flash[:alert]
    assert_equal original_blob_id, @member.reload.photo.blob.id
  end

  test "reports every invalid profile picture restriction without replacing the current picture" do
    @member.photo.attach(io: StringIO.new("original"), filename: "original.png", content_type: "image/png")
    original_blob_id = @member.photo.blob.id
    session[:user_id] = @member.id

    patch :update, params: {
      profile_picture: {
        photo: uploaded_photo(content_type: "image/gif", filename: "photo.gif", size: User::PHOTO_MAXIMUM_SIZE + 1)
      }
    }

    assert_redirected_to users_path
    assert_equal "Your profile picture must be a PNG, JPEG/JPG, or WebP image. Please choose a supported image. Your profile picture exceeds the 0.5 MB maximum. Please choose a smaller image.", flash[:alert]
    assert_equal original_blob_id, @member.reload.photo.blob.id
  end

  test "guests cannot upload or remove profile pictures" do
    patch :update, params: { profile_picture: { photo: uploaded_photo(content_type: "image/png") } }

    assert_redirected_to root_path
    assert_not @member.reload.photo.attached?

    delete :destroy

    assert_redirected_to root_path
    assert_not @member.reload.photo.attached?
  end

  test "profile picture routes ignore supplied user ids" do
    session[:user_id] = @member.id

    patch :update, params: {
      id: @other_member.id,
      profile_picture: { photo: uploaded_photo(content_type: "image/jpeg", filename: "photo.jpg") }
    }

    assert @member.reload.photo.attached?
    assert_not @other_member.reload.photo.attached?
  end

  test "admins can only manage their own profile picture" do
    @member.update!(admin: true)
    session[:user_id] = @member.id

    patch :update, params: {
      id: @other_member.id,
      profile_picture: { photo: uploaded_photo(content_type: "image/jpg", filename: "photo.jpg") }
    }

    assert @member.reload.photo.attached?
    assert_not @other_member.reload.photo.attached?
  end

  private

  def uploaded_photo(content_type:, filename: "photo.png", size: nil)
    return fixture_file_upload("profile-picture.png", content_type, original_filename: filename) unless size

    file = Tempfile.new([ "profile-picture", File.extname(filename) ])
    file.binmode
    file.write("x" * size)
    file.rewind
    fixture_file_upload(file.path, content_type, original_filename: filename)
  end
end
