require "application_system_test_case"

class ProfilePicturesTest < ApplicationSystemTestCase
  setup do
    @member = User.create!(
      email: "profile-picture-system@example.com",
      first_name: "Profile",
      last_name: "Picture",
      role: "Member"
    )
    @member.photo.attach(io: StringIO.new("original"), filename: "original.png", content_type: "image/png")
  end

  test "submitting replacement without selecting a file preserves the picture and shows guidance" do
    sign_in_as(@member)

    visit users_url
    find("summary[aria-label='Manage your profile picture']").click
    click_on "Replace picture"

    assert_text "Choose a profile picture to upload."
    assert @member.reload.photo.attached?
    assert_equal "original.png", @member.photo.filename.to_s
  end

  test "member can replace a picture after selecting an image" do
    sign_in_as(@member)

    visit users_url
    find("summary[aria-label='Manage your profile picture']").click
    attach_file "profile_picture_photo", file_fixture("profile-picture.png")
    click_on "Replace picture"

    assert_text "Your profile picture was updated."
    assert_equal "profile-picture.png", @member.reload.photo.filename.to_s
  end

  test "member can upload their first picture" do
    @member.photo.purge
    sign_in_as(@member)

    visit users_url
    find("summary[aria-label='Manage your profile picture']").click
    attach_file "profile_picture_photo", file_fixture("profile-picture.png")
    click_on "Upload picture"

    assert_text "Your profile picture was updated."
    assert @member.reload.photo.attached?
  end

  test "member can delete their picture after confirming" do
    sign_in_as(@member)

    visit users_url
    find("summary[aria-label='Manage your profile picture']").click
    accept_confirm do
      click_on "Delete picture"
    end

    assert_text "Your profile picture was removed."
    assert_not @member.reload.photo.attached?
  end

  private

  def sign_in_as(user)
    login_magic_link = user.login_magic_links.create!

    visit login_magic_link_path(login_magic_link.raw_token)
    assert_text "Signed in successfully."
  end
end
