class UserToken < ApplicationRecord
  belongs_to :user
  before_create :generate_token

  attr_readonly :token

  validates :name, presence: true, length: { maximum: 255 }
  validates :token, uniqueness: true, length: { is: 32 }, if: -> { token.present? }
  validate :expires_at_is_in_future
  validates :user, presence: true

  # Returns active tokens (not expired or with no expiration date)
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  # Returns only expired tokens
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

  private
  def expires_at_is_in_future
    if expires_at.present? && expires_at <= Time.current
      errors.add(:expires_at, "must be in the future")
    end
  end

  def generate_token
    self.token = SecureRandom.hex(16)
  end
end
