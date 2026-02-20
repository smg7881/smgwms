module Excel
  module Handlers
    class UsersHandler < BaseHandler
      HEADER_MAP = {
        "user_id_code" => "사번",
        "user_nm" => "사원명",
        "email_address" => "이메일",
        "dept_cd" => "부서코드",
        "dept_nm" => "부서명",
        "role_cd" => "권한",
        "position_cd" => "직급",
        "job_title_cd" => "직책",
        "work_status" => "재직상태",
        "hire_date" => "입사일",
        "resign_date" => "퇴사일",
        "phone" => "연락처",
        "address" => "주소",
        "detail_address" => "상세주소"
      }.freeze

      def headers
        HEADER_MAP.values
      end

      def acceptable_headers
        [ headers, HEADER_MAP.keys ]
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
        user_id_code = normalized_string(row_hash[HEADER_MAP["user_id_code"]])
        if user_id_code.blank?
          raise ArgumentError, "사번은 필수입니다."
        end

        user = User.find_or_initialize_by(user_id_code: user_id_code)
        attrs = {
          user_nm: normalized_string(row_hash[HEADER_MAP["user_nm"]]),
          email_address: normalized_string(row_hash[HEADER_MAP["email_address"]]),
          dept_cd: normalized_string(row_hash[HEADER_MAP["dept_cd"]]),
          dept_nm: normalized_string(row_hash[HEADER_MAP["dept_nm"]]),
          role_cd: normalized_string(row_hash[HEADER_MAP["role_cd"]]),
          position_cd: normalized_string(row_hash[HEADER_MAP["position_cd"]]),
          job_title_cd: normalized_string(row_hash[HEADER_MAP["job_title_cd"]]),
          work_status: normalized_string(row_hash[HEADER_MAP["work_status"]]) || "ACTIVE",
          hire_date: parse_date(row_hash[HEADER_MAP["hire_date"]]),
          resign_date: parse_date(row_hash[HEADER_MAP["resign_date"]]),
          phone: normalized_string(row_hash[HEADER_MAP["phone"]]),
          address: normalized_string(row_hash[HEADER_MAP["address"]]),
          detail_address: normalized_string(row_hash[HEADER_MAP["detail_address"]])
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
