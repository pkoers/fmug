module ImageAttachmentValidations
  PHOTO_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp].freeze
  PHOTO_MAXIMUM_SIZE = 0.5.megabytes

  private

  def validate_image_attachment(attachment_name)
    attachment = public_send(attachment_name)
    return unless attachment.attached?

    unless attachment.blob.content_type.in?(PHOTO_CONTENT_TYPES)
      errors.add(attachment_name, :unsupported_format, message: "must be a PNG, JPG, JPEG, or WEBP")
    end

    return if attachment.blob.byte_size <= PHOTO_MAXIMUM_SIZE

    errors.add(attachment_name, :too_large, message: "must be 0.5 MB or smaller")
  end
end
