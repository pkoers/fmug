class User < ApplicationRecord
  belongs_to :company, optional: true
  has_many :identities, dependent: :destroy
  has_many :login_magic_links, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy
  has_many :conferences, through: :registrations

  validates :email, :first_name, :last_name, presence: true
  validates :email, uniqueness: true
end
