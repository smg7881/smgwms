class SeedOmCustomerOrderOfficerCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITION = {
    code: "OM_EXP_IMP_DOM_SCTN",
    code_name: "OM 수출입내수구분",
    details: [
      { detail_code: "EXPORT", detail_code_name: "수출", sort_order: 1 },
      { detail_code: "IMPORT", detail_code_name: "수입", sort_order: 2 },
      { detail_code: "DOMESTIC", detail_code_name: "내수", sort_order: 3 }
    ]
  }.freeze

  def up
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

    now = Time.current
    upsert_header!(now)
    upsert_details!(now)
  end

  def down
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

    MigrationAdmCodeDetail.where(code: CODE_DEFINITION[:code]).delete_all
    MigrationAdmCodeHeader.where(code: CODE_DEFINITION[:code]).delete_all
  end

  private
    def upsert_header!(now)
      header = MigrationAdmCodeHeader.find_or_initialize_by(code: CODE_DEFINITION[:code])
      header.assign_attributes(
        code_name: CODE_DEFINITION[:code_name],
        use_yn: "Y",
        update_by: "system",
        update_time: now
      )
      if header.new_record?
        header.create_by = "system"
        header.create_time = now
      end
      header.save!
    end

    def upsert_details!(now)
      CODE_DEFINITION[:details].each do |detail_definition|
        detail = MigrationAdmCodeDetail.find_or_initialize_by(
          code: CODE_DEFINITION[:code],
          detail_code: detail_definition[:detail_code]
        )
        detail.assign_attributes(
          detail_code_name: detail_definition[:detail_code_name],
          short_name: detail_definition[:detail_code_name],
          sort_order: detail_definition[:sort_order],
          use_yn: "Y",
          update_by: "system",
          update_time: now
        )
        if detail.new_record?
          detail.create_by = "system"
          detail.create_time = now
        end
        detail.save!
      end
    end
end
