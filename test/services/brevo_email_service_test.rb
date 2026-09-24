require "test_helper"
require "stringio"

class BrevoEmailServiceTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:code, :body)

  test "deliver posts the message to the Brevo API" do
    mail = NotificationMailer.with(
      to: "Member Example <member@example.com>",
      subject: "FMUG update",
      from_name: "FMUG Chair",
      from_email: "chair@fmug.eu",
      body: "Conference registration is open."
    ).notify

    captured_request = nil
    captured_use_ssl = nil

    with_replaced_singleton_method(Net::HTTP, :start, ->(_hostname, _port, use_ssl:, &block) {
      captured_use_ssl = use_ssl

      http = Object.new
      http.define_singleton_method(:request) do |request|
        captured_request = request
        FakeResponse.new("201", '{"messageId":"<abc123@example.com>"}')
      end

      block.call(http)
    }) do
      response = BrevoEmailService.new(api_key: "test-api-key").deliver(mail)

      assert_equal({ "messageId" => "<abc123@example.com>" }, response)
    end

    assert_equal true, captured_use_ssl
    assert_equal "application/json", captured_request["content-type"]
    assert_equal "test-api-key", captured_request["api-key"]

    payload = JSON.parse(captured_request.body)
    assert_equal({ "email" => "chair@fmug.eu", "name" => "FMUG Chair" }, payload["sender"])
    assert_equal [ { "email" => "member@example.com", "name" => "Member Example" } ], payload["to"]
    assert_equal "FMUG update", payload["subject"]
    assert_nil payload["headers"]
    assert_includes payload["htmlContent"], "Conference registration is open."
    assert_includes payload["textContent"], "Conference registration is open."
  end

  test "deliver raises a helpful error when the API key is missing" do
    mail = NotificationMailer.with(
      to: "member@example.com",
      subject: "FMUG update",
      body: "Conference registration is open."
    ).notify

    error = assert_raises(BrevoEmailService::Error) do
      BrevoEmailService.new(api_key: nil).deliver(mail)
    end

    assert_equal "Missing BREVO_API_KEY", error.message
  end

  test "deliver raises an error for non-success responses" do
    mail = NotificationMailer.with(
      to: "member@example.com",
      subject: "FMUG update",
      body: "Conference registration is open."
    ).notify

    with_replaced_singleton_method(Net::HTTP, :start, ->(_hostname, _port, use_ssl:, &block) {
      http = Object.new
      http.define_singleton_method(:request) do |_request|
        FakeResponse.new("401", '{"message":"unauthorized"}')
      end

      block.call(http)
    }) do
      error = assert_raises(BrevoEmailService::Error) do
        BrevoEmailService.new(api_key: "bad-key").deliver(mail)
      end

      assert_equal 'Brevo API request failed (status 401): {"message":"unauthorized"}', error.message
    end
  end

  test "deliver translates an open timeout into a stable service error" do
    assert_transport_error(Net::OpenTimeout.new("open timeout"))
  end

  test "deliver translates a read timeout into a stable service error" do
    assert_transport_error(Net::ReadTimeout.new)
  end

  test "deliver translates a socket error into a stable service error" do
    assert_transport_error(SocketError.new("DNS lookup failed"))
  end

  test "deliver translates a connection refused error into a stable service error" do
    assert_transport_error(Errno::ECONNREFUSED.new)
  end

  test "deliver does not translate unexpected errors" do
    with_replaced_singleton_method(Net::HTTP, :start, ->(*) { raise ArgumentError, "unexpected failure" }) do
      error = assert_raises(ArgumentError) do
        BrevoEmailService.new(api_key: "test-api-key").deliver(notification_mail)
      end

      assert_equal "unexpected failure", error.message
    end
  end

  test "payload_for builds the preview JSON payload" do
    mail = NotificationMailer.with(
      to: "member@example.com",
      subject: "FMUG update",
      body: "Conference registration is open.",
      html_body: "<p>Conference registration is open.</p>",
      from_name: "FMUG Chair",
      from_email: "chair@fmug.eu"
    ).notify

    payload = BrevoEmailService.payload_for(mail)

    assert_equal({ email: "chair@fmug.eu", name: "FMUG Chair" }, payload[:sender])
    assert_equal [ { email: "member@example.com" } ], payload[:to]
    assert_equal "FMUG update", payload[:subject]
    assert_includes payload[:htmlContent], "<p>Conference registration is open.</p>"
    assert_includes payload[:textContent], "Conference registration is open."
    assert_nil payload[:headers]
  end

  test "payload_for includes sandbox header when explicitly configured" do
    mail = NotificationMailer.with(
      to: "member@example.com",
      subject: "FMUG update",
      body: "Conference registration is open."
    ).notify

    payload = BrevoEmailService.payload_for(mail, sandbox_mode: "drop")

    assert_equal({ "X-Sib-Sandbox" => "drop" }, payload[:headers])
  end

  private

  def assert_transport_error(transport_error)
    log_output = StringIO.new
    logger = ActiveSupport::Logger.new(log_output)

    with_replaced_singleton_method(Rails, :logger, -> { logger }) do
      with_replaced_singleton_method(Net::HTTP, :start, ->(*) { raise transport_error }) do
        error = assert_raises(BrevoEmailService::Error) do
          BrevoEmailService.new(api_key: "test-api-key").deliver(notification_mail)
        end

        assert_equal BrevoEmailService::TRANSPORT_ERROR_MESSAGE, error.message
        assert_same transport_error, error.cause
      end
    end

    assert_includes log_output.string, transport_error.class.name
    assert_includes log_output.string, transport_error.message
    refute_includes log_output.string, "member@example.com"
  end

  def notification_mail
    NotificationMailer.with(
      to: "member@example.com",
      subject: "FMUG update",
      body: "Conference registration is open."
    ).notify
  end

  def with_replaced_singleton_method(object, method_name, implementation)
    singleton_class = object.singleton_class
    original_method = singleton_class.instance_method(method_name) if singleton_class.method_defined?(method_name)

    singleton_class.define_method(method_name, implementation)
    yield
  ensure
    if original_method
      singleton_class.define_method(method_name, original_method)
    else
      singleton_class.remove_method(method_name)
    end
  end
end
