class SeedStdClientCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "STD_BZAC_SCTN_GRP",
      code_name: "Client Section Group",
      details: [
        { detail_code: "INTERNAL", detail_code_name: "Internal", sort_order: 1 },
        { detail_code: "PARTNER", detail_code_name: "Partner", sort_order: 2 },
        { detail_code: "CUSTOMER", detail_code_name: "Customer", sort_order: 3 }
      ]
    },
    {
      code: "STD_BZAC_SCTN",
      code_name: "Client Section",
      details: [
        { detail_code: "SELF", detail_code_name: "Own Company", ref_code: "INTERNAL", sort_order: 1 },
        { detail_code: "SUPPLIER", detail_code_name: "Supplier", ref_code: "PARTNER", sort_order: 2 },
        { detail_code: "FORWARDER", detail_code_name: "Forwarder", ref_code: "PARTNER", sort_order: 3 },
        { detail_code: "AGENT", detail_code_name: "Agent", ref_code: "PARTNER", sort_order: 4 },
        { detail_code: "DOMESTIC", detail_code_name: "Domestic Customer", ref_code: "CUSTOMER", sort_order: 5 },
        { detail_code: "OVERSEAS", detail_code_name: "Overseas Customer", ref_code: "CUSTOMER", sort_order: 6 }
      ]
    },
    {
      code: "STD_BZAC_KIND",
      code_name: "Client Kind",
      details: [
        { detail_code: "CORP", detail_code_name: "Corporate", sort_order: 1 },
        { detail_code: "INDIV", detail_code_name: "Individual", sort_order: 2 }
      ]
    },
    {
      code: "STD_NATION",
      code_name: "Nation",
      details: [
        { detail_code: "KR", detail_code_name: "Korea", sort_order: 1 },
        { detail_code: "US", detail_code_name: "United States", sort_order: 2 },
        { detail_code: "CN", detail_code_name: "China", sort_order: 3 },
        { detail_code: "JP", detail_code_name: "Japan", sort_order: 4 }
      ]
    }
  ].freeze

  def up
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    now = Time.current

    CODE_DEFINITIONS.each do |definition|
      header = MigrationAdmCodeHeader.find_or_initialize_by(code: definition[:code])
      header.code_name = definition[:code_name]
      header.use_yn = "Y"
      header.update_by = "system"
      header.update_time = now

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
        detail.detail_code_name = detail_definition[:detail_code_name]
        detail.short_name = detail_definition[:detail_code_name]
        detail.ref_code = detail_definition[:ref_code]
        detail.sort_order = detail_definition[:sort_order]
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
  end

  def down
    return unless table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)

    codes = CODE_DEFINITIONS.map { |definition| definition[:code] }
    MigrationAdmCodeDetail.where(code: codes).delete_all
    MigrationAdmCodeHeader.where(code: codes).delete_all
  end
end
