class AdmLoginHistory < ApplicationRecord
  self.table_name = "adm_login_histories"

  belongs_to :user, foreign_key: :user_id_code, primary_key: :user_id_code, optional: true

  scope :recent_first, -> { order(login_time: :desc) }
  scope :by_user, ->(code) { where("user_id_code LIKE ?", "%#{code}%") }
  scope :by_success, ->(flag) { where(login_success: flag) }
  scope :since, ->(time) { where("login_time >= ?", time) }
  scope :until_time, ->(time) { where("login_time <= ?", time) }

  class << self
    def record_success(user:, request:)
      browser_info = parse_user_agent(request.user_agent)

      create!(
        user_id_code: user.user_id_code,
        user_nm: user.user_nm,
        login_time: Time.current,
        login_success: true,
        ip_address: request.remote_ip,
        user_agent: request.user_agent&.truncate(500),
        browser: browser_info[:browser],
        os: browser_info[:os]
      )
    end

    def record_failure(email_input:, request:, reason:)
      browser_info = parse_user_agent(request.user_agent)
      user = User.find_by(email_address: email_input)

      create!(
        user_id_code: user&.user_id_code || email_input&.truncate(16),
        user_nm: user&.user_nm,
        login_time: Time.current,
        login_success: false,
        ip_address: request.remote_ip,
        user_agent: request.user_agent&.truncate(500),
        browser: browser_info[:browser],
        os: browser_info[:os],
        failure_reason: reason&.truncate(200)
      )
    end

    private
      def parse_user_agent(ua_string)
        return { browser: nil, os: nil } if ua_string.blank?

        b = Browser.new(ua_string)
        {
          browser: "#{b.name} #{b.version}".strip.truncate(100),
          os: "#{b.platform.name} #{b.platform.version}".strip.truncate(100)
        }
      end
  end
end
