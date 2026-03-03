class AddStdZipUseYnCommonCode < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE = "STD_ZIP_USE_YN".freeze

  def up
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

    now = Time.current
    actor = "system"

    header = MigrationAdmCodeHeader.find_or_initialize_by(code: CODE)
    header.code_name = "우편번호 사용여부"
    header.use_yn = "Y"
    header.update_by = actor
    header.update_time = now
    if header.new_record?
      header.create_by = actor
      header.create_time = now
    end
    header.save!

    upsert_detail(detail_code: "Y", detail_code_name: "예", sort_order: 1, now: now, actor: actor)
    upsert_detail(detail_code: "N", detail_code_name: "아니요", sort_order: 2, now: now, actor: actor)
  end

  def down
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

    MigrationAdmCodeDetail.where(code: CODE).delete_all
    MigrationAdmCodeHeader.where(code: CODE).delete_all
  end

  private
    def upsert_detail(detail_code:, detail_code_name:, sort_order:, now:, actor:)
      detail = MigrationAdmCodeDetail.find_or_initialize_by(code: CODE, detail_code: detail_code)
      detail.detail_code_name = detail_code_name
      detail.short_name = detail_code_name
      detail.sort_order = sort_order
      detail.use_yn = "Y"
      detail.update_by = actor
      detail.update_time = now
      if detail.new_record?
        detail.create_by = actor
        detail.create_time = now
      end
      detail.save!
    end
end
