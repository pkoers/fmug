class User < ApplicationRecord
  belongs_to :company, optional: true
  has_many :identities, dependent: :destroy

  validates :email, :first_name, :last_name, :role, presence: true
  validates :email, uniqueness: true
end
