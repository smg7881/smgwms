class SeedStdCustomerClientCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "STD_CUST_BZAC_SCTN_GRP",
      code_name: "고객거래처구분그룹",
      details: [
        { detail_code: "CUSTOMER", detail_code_name: "고객거래처", sort_order: 1 }
      ]
    },
    {
      code: "STD_CUST_BZAC_SCTN",
      code_name: "고객거래처구분",
      details: [
        {
          detail_code: "DOMESTIC",
          detail_code_name: "국내고객",
          upper_code: "STD_CUST_BZAC_SCTN_GRP",
          upper_detail_code: "CUSTOMER",
          sort_order: 1
        },
        {
          detail_code: "OVERSEAS",
          detail_code_name: "해외고객",
          upper_code: "STD_CUST_BZAC_SCTN_GRP",
          upper_detail_code: "CUSTOMER",
          sort_order: 2
        }
      ]
    },
    {
      code: "STD_CUST_BZAC_KIND",
      code_name: "고객거래처종류",
      details: [
        { detail_code: "CORP", detail_code_name: "법인", sort_order: 1 },
        { detail_code: "INDIV", detail_code_name: "개인", sort_order: 2 }
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
        detail.upper_code = detail_definition[:upper_code]
        detail.upper_detail_code = detail_definition[:upper_detail_code]
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
