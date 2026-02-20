class SeedCommonSelectCodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  CODE_DEFINITIONS = [
    {
      code: "CMM_USE_YN",
      code_name: "사용여부",
      details: [
        { detail_code: "Y", detail_code_name: "사용", sort_order: 1 },
        { detail_code: "N", detail_code_name: "미사용", sort_order: 2 }
      ]
    },
    {
      code: "USER_WORK_STATUS",
      code_name: "사용자 재직상태",
      details: [
        { detail_code: "ACTIVE", detail_code_name: "재직", sort_order: 1 },
        { detail_code: "RESIGNED", detail_code_name: "퇴사", sort_order: 2 }
      ]
    },
    {
      code: "USER_POSITION",
      code_name: "사용자 직급",
      details: [
        { detail_code: "STAFF", detail_code_name: "사원", sort_order: 1 },
        { detail_code: "SENIOR", detail_code_name: "주임", sort_order: 2 },
        { detail_code: "ASSISTANT_MGR", detail_code_name: "대리", sort_order: 3 },
        { detail_code: "MANAGER", detail_code_name: "과장", sort_order: 4 },
        { detail_code: "DEPUTY_GM", detail_code_name: "차장", sort_order: 5 },
        { detail_code: "GENERAL_MGR", detail_code_name: "부장", sort_order: 6 }
      ]
    },
    {
      code: "USER_JOB_TITLE",
      code_name: "사용자 직책",
      details: [
        { detail_code: "MEMBER", detail_code_name: "담당", sort_order: 1 },
        { detail_code: "TEAM_LEAD", detail_code_name: "팀장", sort_order: 2 },
        { detail_code: "PART_LEAD", detail_code_name: "파트장", sort_order: 3 }
      ]
    },
    {
      code: "MENU_TYPE",
      code_name: "메뉴 타입",
      details: [
        { detail_code: "FOLDER", detail_code_name: "폴더", sort_order: 1 },
        { detail_code: "MENU", detail_code_name: "메뉴", sort_order: 2 }
      ]
    },
    {
      code: "LOGIN_SUCCESS",
      code_name: "로그인 결과",
      details: [
        { detail_code: "TRUE", detail_code_name: "성공", sort_order: 1 },
        { detail_code: "FALSE", detail_code_name: "실패", sort_order: 2 }
      ]
    },
    {
      code: "EXCEL_RESOURCE",
      code_name: "엑셀 리소스",
      details: [
        { detail_code: "USERS", detail_code_name: "사용자", sort_order: 1 },
        { detail_code: "DEPT", detail_code_name: "부서", sort_order: 2 }
      ]
    },
    {
      code: "POST_STATUS",
      code_name: "게시물 상태",
      details: [
        { detail_code: "PUBLISHED", detail_code_name: "게시됨", sort_order: 1 },
        { detail_code: "DRAFT", detail_code_name: "임시저장", sort_order: 2 }
      ]
    }
  ].freeze

  def up
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
        detail.ref_code = nil
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
    codes = CODE_DEFINITIONS.map { |definition| definition[:code] }
    MigrationAdmCodeDetail.where(code: codes).delete_all
    MigrationAdmCodeHeader.where(code: codes).delete_all
  end
end
