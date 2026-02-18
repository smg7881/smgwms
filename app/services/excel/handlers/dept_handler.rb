module Excel
  module Handlers
    class DeptHandler < BaseHandler
      def headers
        [
          "dept_code",
          "dept_nm",
          "dept_type",
          "parent_dept_code",
          "dept_order",
          "use_yn",
          "description"
        ]
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
        dept_code = normalized_string(row_hash["dept_code"])
        if dept_code.blank?
          raise ArgumentError, "dept_code is required"
        end

        dept = AdmDept.find_or_initialize_by(dept_code: dept_code)
        attrs = {
          dept_nm: normalized_string(row_hash["dept_nm"]),
          dept_type: normalized_string(row_hash["dept_type"]),
          parent_dept_code: normalized_string(row_hash["parent_dept_code"]),
          dept_order: row_hash["dept_order"].to_i,
          use_yn: normalized_string(row_hash["use_yn"]) || "Y",
          description: normalized_string(row_hash["description"])
        }

        dept.assign_attributes(attrs)
        dept.save!
      end
    end
  end
end
