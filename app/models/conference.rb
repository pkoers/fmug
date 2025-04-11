class Conference < ApplicationRecord
  has_many :schedules, dependent: :destroy, if: -> { current? }

  # Example method to check if the conference is current
  def current?
    self.current
  end
end
