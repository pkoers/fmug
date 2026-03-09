class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :conference

  validates :attending_physically, inclusion: { in: [ true, false ] }
  validates :user_id, uniqueness: { scope: :conference_id }
end
