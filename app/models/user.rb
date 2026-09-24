class User < ApplicationRecord
  include ImageAttachmentValidations

  PHOTO_CONTENT_TYPES = ImageAttachmentValidations::PHOTO_CONTENT_TYPES
  PHOTO_MAXIMUM_SIZE = ImageAttachmentValidations::PHOTO_MAXIMUM_SIZE

  has_one_attached :photo, dependent: :purge

  belongs_to :company, optional: true
  has_many :identities, dependent: :destroy
  has_many :login_magic_links, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy
  has_many :created_registration_campaigns, class_name: "RegistrationCampaign", foreign_key: :created_by_id, dependent: :restrict_with_exception
  has_many :conferences, through: :registrations

  validates :email, :first_name, :last_name, presence: true
  validates :email, uniqueness: true
  validate :photo_is_valid

  private

  def photo_is_valid
    validate_image_attachment(:photo)
  end
end
