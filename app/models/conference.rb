class Conference < ApplicationRecord
  has_one_attached :image, dependent: :purge
  has_many :schedules, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :users, through: :registrations

  scope :current_conference, -> { where(current: true) }

  validates :current, uniqueness: true, if: :current?
  validate :image_must_be_supported_format

  def current?
    self.current
  end

  private

  def image_must_be_supported_format
    return unless image.attached?
    return if image.blob.content_type.in?(%w[image/png image/jpeg image/jpg image/webp])

    errors.add(:image, "must be a PNG, JPG, JPEG, or WEBP")
  end
end
