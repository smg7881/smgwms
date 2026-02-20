class SeedNoticeCategoryCode < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE = "NOTICE_CATEGORY".freeze
  CODE_NAME = "공지 분류".freeze
  DETAIL_DEFINITIONS = [
    { detail_code: "GENERAL", detail_code_name: "일반공지", sort_order: 1 },
    { detail_code: "SYSTEM", detail_code_name: "시스템공지", sort_order: 2 },
    { detail_code: "EVENT", detail_code_name: "이벤트", sort_order: 3 }
  ].freeze

  def up
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    now = Time.current
    header = MigrationAdmCodeHeader.find_or_initialize_by(code: CODE)
    header.code_name = CODE_NAME
    header.use_yn = "Y"
    header.update_by = "system"
    header.update_time = now

    if header.new_record?
      header.create_by = "system"
      header.create_time = now
    end

    header.save!

    DETAIL_DEFINITIONS.each do |definition|
      detail = MigrationAdmCodeDetail.find_or_initialize_by(code: CODE, detail_code: definition[:detail_code])
      detail.detail_code_name = definition[:detail_code_name]
      detail.short_name = definition[:detail_code_name]
      detail.ref_code = nil
      detail.sort_order = definition[:sort_order]
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

    MigrationAdmCodeDetail.where(code: CODE).delete_all
    MigrationAdmCodeHeader.where(code: CODE).delete_all
  end
end
