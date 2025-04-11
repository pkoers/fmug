require "test_helper"

class ConferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @conference = conferences(:one)
  end

  test "should get index" do
    get conferences_url
    assert_response :success
  end

  test "should get new" do
    get new_conference_url
    assert_response :success
  end

  test "should create conference" do
    assert_difference("Conference.count") do
      post conferences_url, params: { conference: {} }
    end

    assert_redirected_to conference_url(Conference.last)
  end

  test "should show conference" do
    get conference_url(@conference)
    assert_response :success
  end

  test "should get edit" do
    get edit_conference_url(@conference)
    assert_response :success
  end

  test "should update conference" do
    patch conference_url(@conference), params: { conference: {} }
    assert_redirected_to conference_url(@conference)
  end

  test "should destroy conference" do
    assert_difference("Conference.count", -1) do
      delete conference_url(@conference)
    end

    assert_redirected_to conferences_url
  end
end
