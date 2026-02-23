class SeedStdClientItemCodeUnits < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "STD_WGT_UNIT",
      code_name: "중량단위코드",
      details: [
        { detail_code: "KG", detail_code_name: "킬로그램(KG)", sort_order: 1 },
        { detail_code: "G", detail_code_name: "그램(G)", sort_order: 2 },
        { detail_code: "LB", detail_code_name: "파운드(LB)", sort_order: 3 }
      ]
    },
    {
      code: "STD_QTY_UNIT",
      code_name: "수량단위코드",
      details: [
        { detail_code: "EA", detail_code_name: "개(EA)", sort_order: 1 },
        { detail_code: "BOX", detail_code_name: "박스(BOX)", sort_order: 2 },
        { detail_code: "PLT", detail_code_name: "팔레트(PLT)", sort_order: 3 }
      ]
    },
    {
      code: "STD_TMPT_UNIT",
      code_name: "온도단위코드",
      details: [
        { detail_code: "C", detail_code_name: "섭씨(C)", sort_order: 1 },
        { detail_code: "F", detail_code_name: "화씨(F)", sort_order: 2 }
      ]
    },
    {
      code: "STD_VOL_UNIT",
      code_name: "부피단위코드",
      details: [
        { detail_code: "CBM", detail_code_name: "세제곱미터(CBM)", sort_order: 1 },
        { detail_code: "M3", detail_code_name: "세제곱미터(M3)", sort_order: 2 },
        { detail_code: "L", detail_code_name: "리터(L)", sort_order: 3 }
      ]
    },
    {
      code: "STD_BASIS_UNIT",
      code_name: "기본단위코드",
      details: [
        { detail_code: "EA", detail_code_name: "개(EA)", sort_order: 1 },
        { detail_code: "BOX", detail_code_name: "박스(BOX)", sort_order: 2 },
        { detail_code: "SET", detail_code_name: "세트(SET)", sort_order: 3 }
      ]
    },
    {
      code: "STD_LEN_UNIT",
      code_name: "길이단위코드",
      details: [
        { detail_code: "M", detail_code_name: "미터(M)", sort_order: 1 },
        { detail_code: "CM", detail_code_name: "센티미터(CM)", sort_order: 2 },
        { detail_code: "MM", detail_code_name: "밀리미터(MM)", sort_order: 3 }
      ]
    }
  ].freeze

  def up
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

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
    if !table_exists?(:adm_code_headers) || !table_exists?(:adm_code_details)
      return
    end

    codes = CODE_DEFINITIONS.map { |definition| definition[:code] }
    MigrationAdmCodeDetail.where(code: codes).delete_all
    MigrationAdmCodeHeader.where(code: codes).delete_all
  end
end
