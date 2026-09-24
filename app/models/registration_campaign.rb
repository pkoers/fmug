class RegistrationCampaign < ApplicationRecord
  EXPIRATION_PERIOD = 30.days
  REGISTRATION_LIMIT = 100

  belongs_to :conference
  belongs_to :created_by, class_name: "User"
  has_many :invitations, dependent: :restrict_with_exception

  attr_reader :raw_token

  before_validation :assign_token, on: :create
  before_validation :assign_expiration, on: :create

  validates :token_digest, :expires_at, presence: true
  validates :token_digest, uniqueness: true
  validates :registration_limit, inclusion: { in: [ REGISTRATION_LIMIT ] }
  validates :successful_registrations_count, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: :registration_limit
  }

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def full?
    successful_registrations_count >= registration_limit
  end

  def accepting_registrations?
    !revoked? && !expired? && !full?
  end

  def status
    return "revoked" if revoked?
    return "expired" if expired?
    return "full" if full?

    "active"
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked?
  end

  def self.find_by_token(token)
    find_by(token_digest: digest(token))
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  private

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
