class SeedWorkplaceTypeCode < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  DETAILS = [
    { detail_code: "WH", detail_code_name: "창고", sort_order: 1 },
    { detail_code: "FC", detail_code_name: "공장", sort_order: 2 },
    { detail_code: "OF", detail_code_name: "사무소", sort_order: 3 }
  ].freeze

  def up
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    now = Time.current

    header = MigrationAdmCodeHeader.find_or_initialize_by(code: "WORKPL_TYPE")
    header.code_name = "작업장유형"
    header.use_yn = "Y"
    header.update_by = "system"
    header.update_time = now

    if header.new_record?
      header.create_by = "system"
      header.create_time = now
    end

    header.save!

    DETAILS.each do |attrs|
      detail = MigrationAdmCodeDetail.find_or_initialize_by(code: "WORKPL_TYPE", detail_code: attrs[:detail_code])
      detail.detail_code_name = attrs[:detail_code_name]
      detail.short_name = attrs[:detail_code_name]
      detail.sort_order = attrs[:sort_order]
      detail.ref_code = nil
      detail.use_yn = "Y"
      detail.update_by = "system"
      detail.update_time = now

      if detail.new_record?
        detail.create_by = "system"
        detail.create_time = now
      end

      detail.save!
    end
  end

  def down
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    MigrationAdmCodeDetail.where(code: "WORKPL_TYPE").delete_all
    MigrationAdmCodeHeader.where(code: "WORKPL_TYPE").delete_all
  end
end
