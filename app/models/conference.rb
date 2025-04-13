class Conference < ApplicationRecord
  has_many :schedules, -> { where("conferences.current = ?", true) }, dependent: :destroy

  scope :current_conference, -> { where(current: true) }
  
  validates :current, uniqueness: true, if: :current?

  def current?
    self.current
  end
end
