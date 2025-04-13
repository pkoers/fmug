class Schedule < ApplicationRecord
  belongs_to :conference

  validate :conference_must_be_current

  private

  def conference_must_be_current
    unless conference&.current?
      errors.add(:conference, "must be the current conference")
    end
  end
end
