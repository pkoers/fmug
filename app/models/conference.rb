class Conference < ApplicationRecord
  has_many :schedules, dependent: :destroy

  scope :current_conference, -> { where(current: true) }

  def current?
    self.current
  end
end
