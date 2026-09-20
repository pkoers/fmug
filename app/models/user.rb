class User < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp].freeze
  PHOTO_MAXIMUM_SIZE = 0.5.megabytes

  has_one_attached :photo, dependent: :purge

  belongs_to :company, optional: true
  has_many :identities, dependent: :destroy
  has_many :login_magic_links, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy
  has_many :conferences, through: :registrations

  validates :email, :first_name, :last_name, presence: true
  validates :email, uniqueness: true
  validate :photo_must_be_supported_format
  validate :photo_must_not_exceed_maximum_size

  private

  def photo_must_be_supported_format
    return unless photo.attached?
    return if photo.blob.content_type.in?(PHOTO_CONTENT_TYPES)

    errors.add(:photo, :unsupported_format, message: "must be a PNG, JPG, JPEG, or WEBP")
  end

  def photo_must_not_exceed_maximum_size
    return unless photo.attached?
    return if photo.blob.byte_size <= PHOTO_MAXIMUM_SIZE

    errors.add(:photo, :too_large, message: "must be 0.5 MB or smaller")
  end
end
