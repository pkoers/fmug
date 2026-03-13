class NotificationMailer < ApplicationMailer
  def notify
    @body = params.fetch(:body)
    @html_body = params[:html_body]
    @text_body = params[:text_body] || @body

    mail(
      to: params.fetch(:to),
      subject: params.fetch(:subject),
      from: from_address
    )
  end

  private

  def from_address
    email = params[:from_email]
    name = params[:from_name]

    return default_params[:from] if email.blank?
    return email if name.blank?

    "#{name} <#{email}>"
  end
end
