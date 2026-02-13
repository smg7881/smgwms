class Session < ApplicationRecord
  belongs_to :user

  validates :token, uniqueness: true, allow_nil: true

  before_create :set_token

  private
    def set_token
      loop do
        self.token = SecureRandom.urlsafe_base64(32)
        break unless Session.exists?(token: token)
      end
    end
end
