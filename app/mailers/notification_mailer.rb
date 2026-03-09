class NotificationMailer < ApplicationMailer
  def notify
    @body = params.fetch(:body)

    mail(
      to: params.fetch(:to),
      subject: params.fetch(:subject)
    )
  end
end
