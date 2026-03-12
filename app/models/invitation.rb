class Invitation < ApplicationRecord
  EXPIRATION_PERIOD = 7.days

  belongs_to :conference
  belongs_to :inviter, class_name: "User"

  attr_reader :raw_token

  before_validation :normalize_attributes
  before_validation :assign_token, on: :create
  before_validation :assign_expiration, on: :create

  validates :email, :first_name, :token_digest, :expires_at, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest, uniqueness: true

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def usable?
    used_at.nil? && !expired?
  end

  def mark_as_used!
    update!(used_at: Time.current)
  end

  def self.find_by_token(token)
    find_by(token_digest: digest(token))
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  private

  def normalize_attributes
    self.first_name = first_name.to_s.strip
    self.email = email.to_s.strip.downcase
  end

  def assign_token
    return if token_digest.present?

    loop do
      @raw_token = SecureRandom.urlsafe_base64(32)
      self.token_digest = self.class.digest(@raw_token)
      break unless self.class.exists?(token_digest: token_digest)
    end
  end

  def assign_expiration
    self.expires_at ||= EXPIRATION_PERIOD.from_now
  end
end
