module Excel
  module Handlers
    class UsersHandler < BaseHandler
      def headers
        [
          "user_id_code",
          "user_nm",
          "email_address",
          "dept_cd",
          "dept_nm",
          "role_cd",
          "position_cd",
          "job_title_cd",
          "work_status",
          "hire_date",
          "resign_date",
          "phone",
          "address",
          "detail_address"
        ]
      end

      def filename_prefix
        "users"
      end

      def export_rows(records)
        records.map do |user|
          [
            user.user_id_code,
            user.user_nm,
            user.email_address,
            user.dept_cd,
            user.dept_nm,
            user.role_cd,
            user.position_cd,
            user.job_title_cd,
            user.work_status,
            user.hire_date&.to_s,
            user.resign_date&.to_s,
            user.phone,
            user.address,
            user.detail_address
          ]
        end
      end

      def import_row!(row_hash)
        user_id_code = normalized_string(row_hash["user_id_code"])
        if user_id_code.blank?
          raise ArgumentError, "user_id_code is required"
        end

        user = User.find_or_initialize_by(user_id_code: user_id_code)
        attrs = {
          user_nm: normalized_string(row_hash["user_nm"]),
          email_address: normalized_string(row_hash["email_address"]),
          dept_cd: normalized_string(row_hash["dept_cd"]),
          dept_nm: normalized_string(row_hash["dept_nm"]),
          role_cd: normalized_string(row_hash["role_cd"]),
          position_cd: normalized_string(row_hash["position_cd"]),
          job_title_cd: normalized_string(row_hash["job_title_cd"]),
          work_status: normalized_string(row_hash["work_status"]) || "ACTIVE",
          hire_date: parse_date(row_hash["hire_date"]),
          resign_date: parse_date(row_hash["resign_date"]),
          phone: normalized_string(row_hash["phone"]),
          address: normalized_string(row_hash["address"]),
          detail_address: normalized_string(row_hash["detail_address"])
        }

        user.assign_attributes(attrs)
        if user.new_record? && user.password_digest.blank?
          user.password = SecureRandom.hex(8)
        end

        user.save!
      end
    end
  end
end
