require "json"
require "net/http"

class BrevoEmailService
  API_URL = ENV.fetch("BREVO_EMAIL_API_URL", "https://api.brevo.com/v3/smtp/email")

  Error = Class.new(StandardError)

  def self.deliver(...)
    new.deliver(...)
  end

  def self.payload_for(message, sandbox_mode: ENV["BREVO_SANDBOX_MODE"])
    new(sandbox_mode:).payload_for(message)
  end

  def initialize(api_key: ENV["BREVO_API_KEY"], api_url: API_URL, sandbox_mode: ENV["BREVO_SANDBOX_MODE"])
    @api_key = api_key
    @api_url = api_url
    @sandbox_mode = sandbox_mode
  end

  def deliver(message)
    raise Error, "Missing BREVO_API_KEY" if api_key.blank?

    uri = URI.parse(api_url)
    request = Net::HTTP::Post.new(uri)
    request["accept"] = "application/json"
    request["api-key"] = api_key
    request["content-type"] = "application/json"
    request.body = JSON.generate(payload_for(message))

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    body = response.body.presence || "{}"
    parsed_body = JSON.parse(body)

    return parsed_body if response.code.to_i.between?(200, 299)

    raise Error, "Brevo API request failed (status #{response.code}): #{body}"
  end

  def payload_for(message)
    payload = {
      sender: sender_for(message[:from], fallback: message.from),
      to: recipients_for(message[:to], fallback: message.to),
      subject: message.subject.to_s
    }

    payload[:htmlContent] = html_content_for(message) if html_content_for(message).present?
    payload[:textContent] = text_content_for(message) if text_content_for(message).present?
    payload[:headers] = { "X-Sib-Sandbox" => sandbox_mode } if sandbox_mode.present?
    payload
  end

  private

  attr_reader :api_key, :api_url, :sandbox_mode

  def sender_for(header, fallback:)
    address = addresses_from_header(header).first || Mail::Address.new(Array(fallback).first.to_s)
    sender = { email: address.address }
    sender[:name] = address.display_name if address.display_name.present?
    sender
  end

  def recipients_for(header, fallback:)
    header_addresses = addresses_from_header(header)
    return header_addresses.map { |address| recipient_for(address) } if header_addresses.any?

    Array(fallback).map do |value|
      address = Mail::Address.new(value.to_s)
      recipient_for(address)
    end
  end

  def recipient_for(address)
    recipient = { email: address.address }
    recipient[:name] = address.display_name if address.display_name.present?
    recipient
  end

  def addresses_from_header(header)
    return [] if header.blank?

    Mail::AddressList.new(header.value.to_s).addresses
  rescue Mail::Field::ParseError
    []
  end

  def html_content_for(message)
    part_body(message.html_part) || text_content_for(message)
  end

  def text_content_for(message)
    part_body(message.text_part) || body_content(message)
  end

  def part_body(part)
    part&.decoded.to_s.presence
  end

  def body_content(message)
    return if message.multipart?

    message.body.decoded.to_s.presence
  end
end
