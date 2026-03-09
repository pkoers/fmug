class Conference < ApplicationRecord
  has_many :schedules, -> { where("conferences.current = ?", true) }, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :users, through: :registrations

  scope :current_conference, -> { where(current: true) }

  validates :current, uniqueness: true, if: :current?

  def current?
    self.current
  end
end
