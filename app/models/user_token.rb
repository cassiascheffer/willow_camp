class UserToken < ApplicationRecord
  belongs_to :user
  before_create :generate_token

  attr_readonly :token

  validates :name, presence: true
  validates :token, uniqueness: true, if: -> { token.present? }
  validate :expires_at_is_in_future
  validates :user, presence: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

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
