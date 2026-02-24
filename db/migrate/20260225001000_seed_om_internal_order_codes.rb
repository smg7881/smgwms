class SeedOmInternalOrderCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "OM_ORD_STAT",
      code_name: "OM 오더상태",
      details: [
        { detail_code: "WAIT", detail_code_name: "대기", sort_order: 1 },
        { detail_code: "PROC", detail_code_name: "처리중", sort_order: 2 },
        { detail_code: "DONE", detail_code_name: "완료", sort_order: 3 },
        { detail_code: "CANCEL", detail_code_name: "취소", sort_order: 4 }
      ]
    },
    {
      code: "OM_LOC_TYPE",
      code_name: "OM 출도착지유형",
      details: [
        { detail_code: "WORKPLACE", detail_code_name: "작업장", sort_order: 1 },
        { detail_code: "CUSTOMER", detail_code_name: "고객거래처", sort_order: 2 }
      ]
    },
    {
      code: "OM_QTY_UNIT",
      code_name: "OM 수량단위",
      details: [
        { detail_code: "EA", detail_code_name: "개", sort_order: 1 },
        { detail_code: "BOX", detail_code_name: "박스", sort_order: 2 },
        { detail_code: "PLT", detail_code_name: "팔레트", sort_order: 3 }
      ]
    },
    {
      code: "OM_WGT_UNIT",
      code_name: "OM 중량단위",
      details: [
        { detail_code: "KG", detail_code_name: "킬로그램", sort_order: 1 },
        { detail_code: "TON", detail_code_name: "톤", sort_order: 2 }
      ]
    },
    {
      code: "OM_VOL_UNIT",
      code_name: "OM 부피단위",
      details: [
        { detail_code: "CBM", detail_code_name: "세제곱미터", sort_order: 1 },
        { detail_code: "LTR", detail_code_name: "리터", sort_order: 2 }
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
