class EmailExportJob < ApplicationJob
  queue_as :default

  def perform(encoded_message, export_path: nil)
    message = Mail.read_from_string(encoded_message)

    EmailExport.new(message, export_path:).save
  end
end
