class Session < ApplicationRecord
  belongs_to :user

  # Optional validations for IP address and user_agent
  validates :ip_address, format: {
    with: /\A((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$|^([0-9a-f]{1,4}:){7}([0-9a-f]{1,4})\z/i,
    allow_blank: true,
    message: "must be a valid IPv4 or IPv6 address"
  }
  validates :user_agent, length: {maximum: 255}, allow_blank: true
end
