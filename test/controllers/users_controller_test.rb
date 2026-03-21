require "test_helper"

class UsersControllerTest < ActionController::TestCase
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

  test "redirects guests away from the members list" do
    get :index

    assert_redirected_to root_path
    assert_equal "Please sign in first.", flash[:alert]
  end

  test "shows the members list when signed in" do
    @other_member.update!(admin: true)

    session[:user_id] = @member.id
    get :index

    assert_response :success
    assert_includes response.body, "Members"
    assert_includes response.body, "Ada Lovelace"
    assert_includes response.body, "Grace Hopper (Admin)"
    assert_not_includes response.body, "member@example.com"
    assert_not_includes response.body, "other@example.com"
  end

  test "shows member email addresses to admins" do
    @member.update!(admin: true)
    @other_member.update!(admin: true)

    session[:user_id] = @member.id
    get :index

    assert_response :success
    assert_includes response.body, "Ada Lovelace (Admin)"
    assert_includes response.body, "member@example.com"
    assert_includes response.body, "Grace Hopper (Admin)"
    assert_includes response.body, "other@example.com"
    assert_includes response.body, "Admin On"
    assert_includes response.body, "Delete"
  end

  test "admins can grant admin rights to another user" do
    @member.update!(admin: true)

    session[:user_id] = @member.id
    patch :admin, params: { id: @other_member.id, admin: true }

    assert_redirected_to users_path
    assert_equal "Grace Hopper admin access updated.", flash[:notice]
    assert @other_member.reload.admin?
  end

  test "admins can remove admin rights from another user" do
    @member.update!(admin: true)
    @other_member.update!(admin: true)

    session[:user_id] = @member.id
    patch :admin, params: { id: @other_member.id, admin: false }

    assert_redirected_to users_path
    assert_equal "Grace Hopper admin access updated.", flash[:notice]
    assert_not @other_member.reload.admin?
  end

  test "admins cannot remove their own admin rights" do
    @member.update!(admin: true)

    session[:user_id] = @member.id
    patch :admin, params: { id: @member.id, admin: false }

    assert_redirected_to users_path
    assert_equal "You cannot remove your own admin rights.", flash[:alert]
    assert @member.reload.admin?
  end

  test "non-admins cannot change admin rights" do
    session[:user_id] = @member.id
    patch :admin, params: { id: @other_member.id, admin: true }

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform that action.", flash[:alert]
    assert_not @other_member.reload.admin?
  end

  test "members can delete their own account" do
    session[:user_id] = @member.id

    assert_difference("User.count", -1) do
      delete :destroy, params: { id: @member.id }
    end

    assert_redirected_to root_path
    assert_equal "Your account has been deleted.", flash[:notice]
    assert_nil session[:user_id]
  end

  test "members cannot delete another account" do
    session[:user_id] = @member.id

    assert_no_difference("User.count") do
      delete :destroy, params: { id: @other_member.id }
    end

    assert_redirected_to users_path
    assert_equal "You can only delete your own account.", flash[:alert]
  end

  test "admins cannot delete their own account" do
    @member.update!(admin: true)
    session[:user_id] = @member.id

    assert_no_difference("User.count") do
      delete :destroy, params: { id: @member.id }
    end

    assert_redirected_to users_path
    assert_equal "Admins cannot delete their own account.", flash[:alert]
    assert @member.reload.admin?
  end

  test "admins can delete another account" do
    @member.update!(admin: true)
    session[:user_id] = @member.id

    assert_difference("User.count", -1) do
      delete :destroy, params: { id: @other_member.id }
    end

    assert_redirected_to users_path
    assert_equal "Grace Hopper has been deleted.", flash[:notice]
  end
end

class LandingMembersNavigationTest < ActionController::TestCase
  tests PagesController

  test "shows the members button on the landing page only when signed in" do
    get :landing

    assert_response :success
    assert_not_includes response.body, ">Members<"

    member = User.create!(
      email: "member@example.com",
      first_name: "Ada",
      last_name: "Lovelace",
      role: "Member"
    )
    session[:user_id] = member.id

    get :landing

    assert_response :success
    assert_includes response.body, ">Members<"
    assert_includes response.body, users_path
  end

  test "shows the conference admin button on the landing page only to admins" do
    member = User.create!(
      email: "member@example.com",
      first_name: "Ada",
      last_name: "Lovelace",
      role: "Member"
    )
    admin = User.create!(
      email: "admin@example.com",
      first_name: "Grace",
      last_name: "Hopper",
      role: "Member",
      admin: true
    )

    session[:user_id] = member.id
    get :landing

    assert_response :success
    assert_not_includes response.body, ">Conference Admin<"

    session[:user_id] = admin.id
    get :landing

    assert_response :success
    assert_includes response.body, ">Conference Admin<"
    assert_includes response.body, conferences_path
  end
end
