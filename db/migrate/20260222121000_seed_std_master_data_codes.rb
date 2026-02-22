class SeedStdMasterDataCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "STD_VAT_SCTN",
      code_name: "VAT Section",
      details: [
        { detail_code: "GENERAL", detail_code_name: "General Taxpayer", sort_order: 1 },
        { detail_code: "SIMPLIFIED", detail_code_name: "Simplified Taxpayer", sort_order: 2 },
        { detail_code: "EXEMPT", detail_code_name: "Tax Exempt", sort_order: 3 }
      ]
    },
    {
      code: "STD_SYS_LANG",
      code_name: "System Language",
      details: [
        { detail_code: "KO", detail_code_name: "Korean", sort_order: 1 },
        { detail_code: "EN", detail_code_name: "English", sort_order: 2 },
        { detail_code: "ZH", detail_code_name: "Chinese", sort_order: 3 }
      ]
    },
    {
      code: "STD_MON_CODE",
      code_name: "Currency",
      details: [
        { detail_code: "KRW", detail_code_name: "KRW", sort_order: 1 },
        { detail_code: "USD", detail_code_name: "USD", sort_order: 2 },
        { detail_code: "EUR", detail_code_name: "EUR", sort_order: 3 },
        { detail_code: "JPY", detail_code_name: "JPY", sort_order: 4 },
        { detail_code: "CNY", detail_code_name: "CNY", sort_order: 5 }
      ]
    },
    {
      code: "STD_TIMEZONE",
      code_name: "Time Zone",
      details: [
        { detail_code: "ASIA_SEOUL", detail_code_name: "Asia/Seoul (UTC+09:00)", sort_order: 1, ref_code: "KR" },
        { detail_code: "ASIA_TOKYO", detail_code_name: "Asia/Tokyo (UTC+09:00)", sort_order: 2, ref_code: "JP" },
        { detail_code: "ASIA_SHANGHAI", detail_code_name: "Asia/Shanghai (UTC+08:00)", sort_order: 3, ref_code: "CN" },
        { detail_code: "AMERICA_NEW_YORK", detail_code_name: "America/New_York (UTC-05:00)", sort_order: 4, ref_code: "US" }
      ]
    },
    {
      code: "STD_BIZMAN_YN",
      code_name: "Business Type",
      details: [
        { detail_code: "BUSINESS", detail_code_name: "Business", sort_order: 1 },
        { detail_code: "INDIVIDUAL", detail_code_name: "Individual", sort_order: 2 }
      ]
    },
    {
      code: "STD_IF_SCTN",
      code_name: "Interface Section",
      details: [
        { detail_code: "INTERNAL", detail_code_name: "Internal", sort_order: 1 },
        { detail_code: "EXTERNAL", detail_code_name: "External", sort_order: 2 }
      ]
    },
    {
      code: "STD_IF_METHOD",
      code_name: "Interface Method",
      details: [
        { detail_code: "API", detail_code_name: "API", sort_order: 1 },
        { detail_code: "FILE", detail_code_name: "FILE", sort_order: 2 },
        { detail_code: "BATCH", detail_code_name: "BATCH", sort_order: 3 }
      ]
    },
    {
      code: "STD_SYS_SCTN",
      code_name: "System Section",
      details: [
        { detail_code: "WMS", detail_code_name: "WMS", sort_order: 1 },
        { detail_code: "ERP", detail_code_name: "ERP", sort_order: 2 },
        { detail_code: "MES", detail_code_name: "MES", sort_order: 3 }
      ]
    },
    {
      code: "STD_SEND_RECV_SCTN",
      code_name: "Send Receive Section",
      details: [
        { detail_code: "SEND", detail_code_name: "Send", sort_order: 1 },
        { detail_code: "RECV", detail_code_name: "Receive", sort_order: 2 },
        { detail_code: "BOTH", detail_code_name: "Both", sort_order: 3 }
      ]
    },
    {
      code: "STD_RSV_WORK_CYCLE",
      code_name: "Reserved Job Cycle",
      details: [
        { detail_code: "MINUTE", detail_code_name: "Minute", sort_order: 1 },
        { detail_code: "HOURLY", detail_code_name: "Hourly", sort_order: 2 },
        { detail_code: "DAILY", detail_code_name: "Daily", sort_order: 3 },
        { detail_code: "WEEKLY", detail_code_name: "Weekly", sort_order: 4 },
        { detail_code: "MONTHLY", detail_code_name: "Monthly", sort_order: 5 }
      ]
    },
    {
      code: "STD_PGM_SCTN",
      code_name: "Program Section",
      details: [
        { detail_code: "BATCH", detail_code_name: "Batch", sort_order: 1 },
        { detail_code: "SERVICE", detail_code_name: "Service", sort_order: 2 },
        { detail_code: "WORKER", detail_code_name: "Worker", sort_order: 3 }
      ]
    },
    {
      code: "STD_ANNO_DGRCNT",
      code_name: "Announcement Degree",
      details: [
        { detail_code: "FIRST", detail_code_name: "First", sort_order: 1 },
        { detail_code: "FINAL", detail_code_name: "Final", sort_order: 2 }
      ]
    },
    {
      code: "STD_FIN_ORG",
      code_name: "Financial Organization",
      details: [
        { detail_code: "KDB", detail_code_name: "KDB", sort_order: 1 },
        { detail_code: "KOOKMIN", detail_code_name: "Kookmin Bank", sort_order: 2 },
        { detail_code: "HANA", detail_code_name: "Hana Bank", sort_order: 3 },
        { detail_code: "WOORI", detail_code_name: "Woori Bank", sort_order: 4 }
      ]
    },
    {
      code: "STD_HATAE",
      code_name: "Goods Type",
      details: [
        { detail_code: "GENERAL", detail_code_name: "General", sort_order: 1 },
        { detail_code: "COLD", detail_code_name: "Cold Chain", sort_order: 2 },
        { detail_code: "DANGEROUS", detail_code_name: "Dangerous", sort_order: 3 }
      ]
    },
    {
      code: "STD_ITEM_GRP",
      code_name: "Item Group",
      details: [
        { detail_code: "RAW", detail_code_name: "Raw Material", sort_order: 1 },
        { detail_code: "FINISH", detail_code_name: "Finished Goods", sort_order: 2 },
        { detail_code: "ETC", detail_code_name: "Etc", sort_order: 3 }
      ]
    },
    {
      code: "STD_ITEM",
      code_name: "Item",
      details: [
        { detail_code: "ITEM_A", detail_code_name: "Item A", sort_order: 1 },
        { detail_code: "ITEM_B", detail_code_name: "Item B", sort_order: 2 },
        { detail_code: "ITEM_C", detail_code_name: "Item C", sort_order: 3 }
      ]
    },
    {
      code: "STD_HWAJONG",
      code_name: "Cargo Type",
      details: [
        { detail_code: "DRY", detail_code_name: "Dry", sort_order: 1 },
        { detail_code: "REEFER", detail_code_name: "Reefer", sort_order: 2 },
        { detail_code: "BULK", detail_code_name: "Bulk", sort_order: 3 }
      ]
    },
    {
      code: "STD_HWAJONG_GRP",
      code_name: "Cargo Group",
      details: [
        { detail_code: "SOLID", detail_code_name: "Solid", sort_order: 1 },
        { detail_code: "LIQUID", detail_code_name: "Liquid", sort_order: 2 },
        { detail_code: "MIXED", detail_code_name: "Mixed", sort_order: 3 }
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
