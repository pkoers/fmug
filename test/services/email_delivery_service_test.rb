require "test_helper"

class EmailDeliveryServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    clear_performed_jobs
    @export_path = Rails.root.join("tmp", "test-emails")
    FileUtils.rm_rf(@export_path)
  end

  teardown do
    FileUtils.rm_rf(@export_path)
  end

  test "notify exports a text file immediately by default" do
    exported_file = EmailDeliveryService.notify(
      to: "member@example.com",
      subject: "FMUG update",
      body: "Agenda changes are live.",
      export_path: @export_path
    )

    assert File.exist?(exported_file)
    contents = File.read(exported_file)
    assert_includes contents, "To: member@example.com"
    assert_includes contents, "Subject: FMUG update"
    assert_includes contents, "Agenda changes are live."
  end

  test "notify can enqueue an export" do
    assert_enqueued_with(job: EmailExportJob) do
      EmailDeliveryService.notify(
        to: "member@example.com",
        subject: "FMUG update",
        body: "Agenda changes are live.",
        delivery: :later,
        export_path: @export_path
      )
    end

    perform_enqueued_jobs

    exported_files = Dir.glob(@export_path.join("*.txt"))
    assert_equal 1, exported_files.length
    assert_includes File.read(exported_files.first), "Agenda changes are live."
  end

  test "notify rejects unsupported delivery modes" do
    error = assert_raises(ArgumentError) do
      EmailDeliveryService.notify(
        to: "member@example.com",
        subject: "FMUG update",
        body: "Agenda changes are live.",
        delivery: :invalid
      )
    end

    assert_equal "Unsupported delivery mode: :invalid", error.message
  end
end
