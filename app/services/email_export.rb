require "fileutils"
require "securerandom"

class EmailExport
  DEFAULT_DIRECTORY = Rails.root.join("tmp", "emails")

  def initialize(message, export_path: nil)
    @message = message
    @export_path = export_path.presence || DEFAULT_DIRECTORY
  end

  def save
    FileUtils.mkdir_p(directory)
    File.write(path, formatted_message)
    path
  end

  private

  attr_reader :message, :export_path

  def directory
    Pathname.new(export_path)
  end

  def path
    @path ||= directory.join(filename)
  end

  def filename
    [
      timestamp,
      message.subject.to_s.parameterize.presence || "email",
      SecureRandom.hex(4)
    ].join("-") + ".txt"
  end

  def timestamp
    Time.current.strftime("%Y%m%d-%H%M%S")
  end

  def formatted_message
    <<~TEXT
      To: #{Array(message.to).join(", ")}
      From: #{Array(message.from).join(", ")}
      Subject: #{message.subject}

      --- Text Body ---
      #{text_body}

      --- HTML Body ---
      #{html_body}
    TEXT
  end

  def text_body
    body_for(message.text_part) || body_for(message)
  end

  def html_body
    body_for(message.html_part)
  end

  def body_for(part)
    return if part.blank?

    part.body.decoded.to_s.strip
  end
end
