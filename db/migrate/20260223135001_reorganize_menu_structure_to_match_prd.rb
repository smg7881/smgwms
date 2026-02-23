class ReorganizeMenuStructureToMatchPrd < ActiveRecord::Migration[8.0]
  def up
    # 1. Create or ensure top-level and level-2/3 folders
    folders = [
      # Level 1
      { cd: "SALES", nm: "영업관리", lv: 1, parent: nil },

      # Level 2 under STD (기준정보)
      { cd: "STD_CODE", nm: "코드관리", lv: 2, parent: "STD" },
      { cd: "STD_MAPPING", nm: "Mapping관리", lv: 2, parent: "STD" },

      # Level 2 under SALES
      { cd: "SALES_CLIENT", nm: "거래처관리", lv: 2, parent: "SALES" },
      { cd: "SALES_CONTRACT", nm: "계약관리", lv: 2, parent: "SALES" },

      # Level 3 under STD_CODE
      { cd: "STD_WORK_BASE", nm: "기준작업관리", lv: 3, parent: "STD_CODE" },
      { cd: "STD_CODE_BIZ", nm: "업무공통코드관리", lv: 3, parent: "STD_CODE" },
      { cd: "STD_CODE_REGION", nm: "권역관리", lv: 3, parent: "STD_CODE" },
      { cd: "STD_CODE_SETTLEMENT", nm: "정산관리", lv: 3, parent: "STD_CODE" },
      { cd: "STD_CODE_HR", nm: "인사정보관리", lv: 3, parent: "STD_CODE" },
      { cd: "STD_CODE_APPROVAL", nm: "결재관리", lv: 3, parent: "STD_CODE" },

      # Level 3 under SALES_CONTRACT
      { cd: "SALES_CONTRACT_BASE", nm: "계약기초관리", lv: 3, parent: "SALES_CONTRACT" },
      { cd: "SALES_SB_CONTRACT", nm: "매출입계약관리", lv: 3, parent: "SALES_CONTRACT" }
    ]

    folders.each_with_index do |f, i|
      menu = AdmMenu.find_or_initialize_by(menu_cd: f[:cd])
      menu.menu_nm = f[:nm]
      menu.parent_cd = f[:parent]
      menu.menu_level = f[:lv]
      menu.menu_type = 'FOLDER'
      menu.use_yn = 'Y'
      menu.sort_order = (i + 1) * 10
      menu.save!
    end

    # 2. Re-assign sub-menus to designated folders
    mappings = {
      # STD_WORK_BASE (Level 4)
      "STD_WORK_ROUTING" => { parent: "STD_WORK_BASE", nm: "기준작업경로관리", type: "MENU" },
      "STD_WRK_RTING_STEP" => { parent: "STD_WORK_BASE", nm: "기준작업경로별작업단계관리", type: "MENU" },
      "STD_ORDER_TYPE" => { parent: "STD_WORK_BASE", nm: "오더유형관리", type: "MENU" },

      # STD_CODE_BIZ (Level 4)
      "STD_ZIP_CODE" => { parent: "STD_CODE_BIZ", nm: "우편번호관리", type: "MENU" },
      "STD_COUNTRY" => { parent: "STD_CODE_BIZ", nm: "국가코드관리", type: "MENU" },
      "STD_GOODS" => { parent: "STD_CODE_BIZ", nm: "품명코드관리", type: "MENU" },

      # STD_CODE (Level 3)
      "SYS_CODE" => { parent: "STD_CODE", nm: "공통코드관리", type: "MENU" }, # moves from SYSTEM, level is 3

      # STD_CODE_REGION (Level 4)
      "STD_REGION" => { parent: "STD_CODE_REGION", nm: "권역관리", type: "MENU" },
      "STD_WORKPLACE" => { parent: "STD_CODE_REGION", nm: "작업장관리", type: "MENU" },
      "STD_REGION_ZIP" => { parent: "STD_CODE_REGION", nm: "권역별우편번호관리", type: "MENU" },

      # STD_CODE_SETTLEMENT (Level 4)
      "STD_EXCHANGE_RATE" => { parent: "STD_CODE_SETTLEMENT", nm: "환율관리", type: "MENU" },
      "STD_SELLBUY_ATTR" => { parent: "STD_CODE_SETTLEMENT", nm: "매출입항목관리", type: "MENU" },
      "STD_FIN_ORG" => { parent: "STD_CODE_SETTLEMENT", nm: "금융기관관리", type: "MENU" },

      # STD_CODE_HR (Level 4)
      "SYS_DEPT" => { parent: "STD_CODE_HR", nm: "부서관리", type: "MENU" },
      "SYS_USER" => { parent: "STD_CODE_HR", nm: "사원관리", type: "MENU" }, # Renamed from "사용자관리"
      "STD_CORPORATION" => { parent: "STD_CODE_HR", nm: "법인관리", type: "MENU" },
      "STD_HOLIDAY" => { parent: "STD_CODE_HR", nm: "공휴일관리", type: "MENU" },

      # STD_CODE_APPROVAL (Level 4)
      "STD_APPROVAL_HISTORY" => { parent: "STD_CODE_APPROVAL", nm: "결재이력관리", type: "MENU" },
      "STD_APPROVAL" => { parent: "STD_CODE_APPROVAL", nm: "결재관리", type: "MENU" },

      # STD_MAPPING (Level 3)
      "STD_CLIENT_ITEM" => { parent: "STD_MAPPING", nm: "거래처별아이템코드관리", type: "MENU" },
      "STD_CODE_MAPPING" => { parent: "STD_MAPPING", nm: "코드매핑관리", type: "MENU" },

      # SALES_CLIENT (Level 3)
      "STD_CLIENT" => { parent: "SALES_CLIENT", nm: "거래처관리", type: "MENU" },
      "SALES_CUST_CLIENT" => { parent: "SALES_CLIENT", nm: "고객거래처관리", type: "MENU" },

      # SALES_CONTRACT_BASE (Level 4)
      "STD_BIZ_CERT" => { parent: "SALES_CONTRACT_BASE", nm: "사업자등록증관리", type: "MENU" },

      # SALES_SB_CONTRACT (Level 4)
      "SALES_SELL_CONTRACT" => { parent: "SALES_SB_CONTRACT", nm: "매출계약관리", type: "MENU" },
      "STD_PUR_CONTRACT" => { parent: "SALES_SB_CONTRACT", nm: "매입계약관리", type: "MENU" }
    }

    mappings.each_with_index do |(cd, info), index|
      menu = AdmMenu.find_or_initialize_by(menu_cd: cd)

      if menu.new_record?
        menu.menu_url = "\#"
      end

      menu.menu_nm = info[:nm]
      menu.parent_cd = info[:parent]
      parent_lv = AdmMenu.find_by(menu_cd: info[:parent])&.menu_level || 1
      menu.menu_level = parent_lv + 1
      menu.menu_type = info[:type]
      menu.use_yn = 'Y'
      menu.sort_order = (index + 1) * 10
      menu.save!
    end
  end

  def down
  end
end
