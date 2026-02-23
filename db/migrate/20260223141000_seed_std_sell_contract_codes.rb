class SeedStdSellContractCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "STD_SELL_CTRT_SCTN",
      code_name: "매출계약구분",
      details: [
        { detail_code: "GENERAL", detail_code_name: "일반계약", sort_order: 1 },
        { detail_code: "SPECIAL", detail_code_name: "특별계약", sort_order: 2 }
      ]
    },
    {
      code: "STD_SELL_CTRT_KIND",
      code_name: "매출계약종류",
      details: [
        { detail_code: "NORMAL", detail_code_name: "정기", sort_order: 1 },
        { detail_code: "SPOT", detail_code_name: "수시", sort_order: 2 },
        { detail_code: "LONGTERM", detail_code_name: "장기", sort_order: 3 }
      ]
    },
    {
      code: "STD_INDGRP",
      code_name: "산업군",
      details: [
        { detail_code: "MANUFACTURE", detail_code_name: "제조업", sort_order: 1 },
        { detail_code: "DISTRIBUTION", detail_code_name: "유통업", sort_order: 2 },
        { detail_code: "SERVICE", detail_code_name: "서비스업", sort_order: 3 },
        { detail_code: "IT", detail_code_name: "IT/정보통신", sort_order: 4 }
      ]
    }
  ].freeze

  def up
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    now = Time.current
    CODE_DEFINITIONS.each do |definition|
      header = MigrationAdmCodeHeader.find_or_initialize_by(code: definition[:code])
      header.assign_attributes(
        code_name: definition[:code_name],
        use_yn: "Y",
        update_by: "system",
        update_time: now
      )
      if header.new_record?
        header.create_by = "system"
        header.create_time = now
      end
      header.save!

      definition[:details].each do |detail_definition|
        detail = MigrationAdmCodeDetail.find_or_initialize_by(
          code: definition[:code],
          detail_code: detail_definition[:detail_code]
        )
        detail.assign_attributes(
          detail_code_name: detail_definition[:detail_code_name],
          short_name: detail_definition[:detail_code_name],
          ref_code: detail_definition[:ref_code],
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

  def down
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    codes = CODE_DEFINITIONS.map { |definition| definition[:code] }
    MigrationAdmCodeDetail.where(code: codes).delete_all
    MigrationAdmCodeHeader.where(code: codes).delete_all
  end
end
