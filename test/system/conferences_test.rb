require "application_system_test_case"

class ConferencesTest < ApplicationSystemTestCase
  setup do
    @conference = conferences(:one)
  end

  test "visiting the index" do
    visit conferences_url
    assert_selector "h1", text: "Conferences"
  end

  test "should create conference" do
    visit conferences_url
    click_on "New conference"

    click_on "Create Conference"

    assert_text "Conference was successfully created"
    click_on "Back"
  end

  test "should update Conference" do
    visit conference_url(@conference)
    click_on "Edit this conference", match: :first

    click_on "Update Conference"

    assert_text "Conference was successfully updated"
    click_on "Back"
  end

  test "should destroy Conference" do
    visit conference_url(@conference)
    accept_confirm { click_on "Destroy this conference", match: :first }

    assert_text "Conference was successfully destroyed"
  end
end
