class SeedStdSellbuyAttributeCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITION = {
    code: "STD_SELLBUY_SCTN",
    code_name: "매출입구분",
    details: [
      { detail_code: "SELL", detail_code_name: "매출", sort_order: 1 },
      { detail_code: "PUR", detail_code_name: "매입", sort_order: 2 },
      { detail_code: "BOTH", detail_code_name: "매출/매입", sort_order: 3 }
    ]
  }.freeze

  def up
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    now = Time.current

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

  def down
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    MigrationAdmCodeDetail.where(code: CODE_DEFINITION[:code]).delete_all
    MigrationAdmCodeHeader.where(code: CODE_DEFINITION[:code]).delete_all
  end
end
