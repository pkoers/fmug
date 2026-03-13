class EmailDeliveryService
  DELIVERY_METHODS = {
    now: :export_now,
    later: :export_later,
    brevo: :deliver_via_brevo
  }.freeze

  def self.notify(...)
    new.notify(...)
  end

  def notify(to:, subject:, body:, delivery: :now, export_path: nil, html_body: nil, text_body: nil, from_email: nil, from_name: nil)
    message = NotificationMailer.with(
      to:,
      subject:,
      body:,
      html_body:,
      text_body:,
      from_email:,
      from_name:
    ).notify

    send(delivery_method_for(delivery), message, export_path:)
  end

  private

  def export_now(message, export_path:)
    EmailExport.new(message, export_path:).save
  end

  def export_later(message, export_path:)
    EmailExportJob.perform_later(message.encoded, export_path: export_path&.to_s)
  end

  def deliver_via_brevo(message, export_path:)
    BrevoEmailService.deliver(message)
  end

  def delivery_method_for(delivery)
    DELIVERY_METHODS.fetch(delivery.to_sym) do
      raise ArgumentError, "Unsupported delivery mode: #{delivery.inspect}"
    end
  end
end
