require "test_helper"

class DevelopmentSeedTest < ActiveSupport::TestCase
  PATRICK_EMAIL = "pkoers75@gmail.com"

  setup do
    User.where(email: PATRICK_EMAIL).delete_all
  end

  test "development seed provisions an administrator idempotently without email" do
    with_development_environment do
      with_replaced_singleton_method(EmailDeliveryService, :notify, ->(**) { flunk "development seed must not send email" }) do
        assert_difference("User.count", 1) do
          load Rails.root.join("db/seeds.rb")
        end

        User.find_by!(email: PATRICK_EMAIL).update!(
          first_name: "Old",
          last_name: "Details",
          role: "Member",
          admin: false
        )

        assert_no_difference("User.count") do
          load Rails.root.join("db/seeds.rb")
        end
      end
    end

    user = User.find_by!(email: PATRICK_EMAIL)
    assert_equal "Patrick", user.first_name
    assert_equal "Koers", user.last_name
    assert_equal "Chair FMUG", user.role
    assert user.admin?
    assert_equal 1, User.where(email: PATRICK_EMAIL).count
    assert_nil user.company
    assert_empty user.identities
    assert_empty user.login_magic_links
    assert_empty user.registrations
    assert_empty user.sent_invitations
  end

  test "seed does not provision the development administrator outside development" do
    load Rails.root.join("db/seeds.rb")

    assert_nil User.find_by(email: PATRICK_EMAIL)
  end

  private

  def with_development_environment
    environment = Rails.env
    environment_singleton_class = environment.singleton_class
    environment_singleton_class.define_method(:development?) { true }
    yield
  ensure
    environment_singleton_class.remove_method(:development?)
  end

  def with_replaced_singleton_method(object, method_name, implementation)
    singleton_class = object.singleton_class
    original_method = singleton_class.instance_method(method_name)
    singleton_class.define_method(method_name, implementation)
    yield
  ensure
    singleton_class.define_method(method_name, original_method)
  end
end
