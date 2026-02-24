class SeedOmCustomerSystemConfigCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "OM_SETUP_UNIT",
      code_name: "OM 설정단위",
      details: [
        { detail_code: "SYSTEM", detail_code_name: "시스템", sort_order: 1 },
        { detail_code: "CUSTOMER", detail_code_name: "고객", sort_order: 2 }
      ]
    },
    {
      code: "OM_SETUP_LCLAS",
      code_name: "OM 대분류",
      details: [
        { detail_code: "ORD_RECV", detail_code_name: "오더접수", sort_order: 1 },
        { detail_code: "ORD_CREATE", detail_code_name: "오더생성", sort_order: 2 },
        { detail_code: "ORD_ALLOC", detail_code_name: "오더분배", sort_order: 3 },
        { detail_code: "ORD_SEND", detail_code_name: "오더전송", sort_order: 4 }
      ]
    },
    {
      code: "OM_SETUP_MCLAS",
      code_name: "OM 중분류",
      details: [
        { detail_code: "REQUIRED", detail_code_name: "필수항목검증기준", sort_order: 1 },
        { detail_code: "VALIDATE", detail_code_name: "검증", sort_order: 2 }
      ]
    },
    {
      code: "OM_SETUP_SCLAS",
      code_name: "OM 소분류",
      details: [
        { detail_code: "WORK_QTY", detail_code_name: "작업물량", ref_code: "REQUIRED", sort_order: 1 },
        { detail_code: "ITEM_NM", detail_code_name: "품명", ref_code: "REQUIRED", sort_order: 2 },
        { detail_code: "ORIGIN", detail_code_name: "출발거점", ref_code: "REQUIRED", sort_order: 3 },
        { detail_code: "DEST", detail_code_name: "도착거점", ref_code: "REQUIRED", sort_order: 4 },
        { detail_code: "DUE_DATE", detail_code_name: "납기일자", ref_code: "REQUIRED", sort_order: 5 },
        { detail_code: "CREDIT_LIMIT", detail_code_name: "여신한도체크", ref_code: "REQUIRED", sort_order: 6 },
        { detail_code: "CREATE", detail_code_name: "오더생성", ref_code: "VALIDATE", sort_order: 7 },
        { detail_code: "ALLOC", detail_code_name: "오더분배", ref_code: "VALIDATE", sort_order: 8 },
        { detail_code: "SEND", detail_code_name: "오더전송", ref_code: "VALIDATE", sort_order: 9 }
      ]
    },
    {
      code: "OM_SETUP_SCTN",
      code_name: "OM 설정구분",
      details: [
        { detail_code: "VALIDATE", detail_code_name: "검증", sort_order: 1 },
        { detail_code: "OPTION", detail_code_name: "옵션", sort_order: 2 }
      ]
    }
  ].freeze

  def up
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

    now = Time.current

    CODE_DEFINITIONS.each do |definition|
      upsert_header!(definition, now)
      upsert_details!(definition, now)
    end
  end

  def down
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

    CODE_DEFINITIONS.each do |definition|
      MigrationAdmCodeDetail.where(code: definition[:code]).delete_all
      MigrationAdmCodeHeader.where(code: definition[:code]).delete_all
    end
  end

  private
    def upsert_header!(definition, now)
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
    end

    def upsert_details!(definition, now)
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
