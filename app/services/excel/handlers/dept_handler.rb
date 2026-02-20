module Excel
  module Handlers
    class DeptHandler < BaseHandler
      HEADER_MAP = {
        "dept_code" => "부서코드",
        "dept_nm" => "부서명",
        "dept_type" => "부서유형",
        "parent_dept_code" => "상위부서코드",
        "dept_order" => "부서순서",
        "use_yn" => "사용여부",
        "description" => "설명"
      }.freeze

      def headers
        HEADER_MAP.values
      end

      def acceptable_headers
        [ headers, HEADER_MAP.keys ]
      end

      def filename_prefix
        "dept"
      end

      def export_rows(records)
        records.map do |dept|
          [
            dept.dept_code,
            dept.dept_nm,
            dept.dept_type,
            dept.parent_dept_code,
            dept.dept_order,
            dept.use_yn,
            dept.description
          ]
        end
      end

      def import_row!(row_hash)
        dept_code = normalized_string(row_hash[HEADER_MAP["dept_code"]])
        if dept_code.blank?
          raise ArgumentError, "부서코드는 필수입니다."
        end

        dept = AdmDept.find_or_initialize_by(dept_code: dept_code)
        attrs = {
          dept_nm: normalized_string(row_hash[HEADER_MAP["dept_nm"]]),
          dept_type: normalized_string(row_hash[HEADER_MAP["dept_type"]]),
          parent_dept_code: normalized_string(row_hash[HEADER_MAP["parent_dept_code"]]),
          dept_order: row_hash[HEADER_MAP["dept_order"]].to_i,
          use_yn: normalized_string(row_hash[HEADER_MAP["use_yn"]]) || "Y",
          description: normalized_string(row_hash[HEADER_MAP["description"]])
        }

        dept.assign_attributes(attrs)
        dept.save!
      end
    end
  end
end
