class AdmMenuLog < ApplicationRecord
  self.table_name = "adm_menu_logs"

  scope :ordered, -> { order(access_time: :desc, id: :desc) }

  class << self
    def record_access(user:, request:, menu_id:, menu_name:, menu_path:, session_token: nil)
      if user.blank?
        return
      end
      if menu_name.blank? || menu_path.blank?
        return
      end

      create(
        user_id: user.user_id_code,
        user_name: user.user_nm,
        menu_id: menu_id,
        menu_name: menu_name,
        menu_path: menu_path,
        access_time: Time.current,
        ip_address: request.remote_ip,
        user_agent: request.user_agent&.truncate(1000),
        session_id: session_token.presence,
        referrer: request.referer&.truncate(500)
      )
    rescue StandardError => e
      Rails.logger.error("[menu_log] failed to record access: #{e.class} #{e.message}")
    end
  end
end
