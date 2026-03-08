class Company < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :iata_code, uniqueness: true, allow_blank: true
end
