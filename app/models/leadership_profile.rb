class LeadershipProfile < ApplicationRecord
  include ImageAttachmentValidations

  SINGLETON_KEY = 1

  has_one_attached :chair_photo, dependent: :purge
  has_one_attached :vice_chair_photo, dependent: :purge

  validate :chair_photo_is_valid
  validate :vice_chair_photo_is_valid

  def self.current
    find_by(singleton_key: SINGLETON_KEY)
  end

  def self.instance
    create_or_find_by!(singleton_key: SINGLETON_KEY)
  end

  private

  def chair_photo_is_valid
    validate_image_attachment(:chair_photo)
  end

  def vice_chair_photo_is_valid
    validate_image_attachment(:vice_chair_photo)
  end
end
