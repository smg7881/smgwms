class LocalizeStdMasterDataLabelsToKorean < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  class MigrationAdmMenu < ApplicationRecord
    self.table_name = "adm_menus"
  end

  CODE_HEADER_NAMES = {
    "STD_VAT_SCTN" => "부가세구분",
    "STD_SYS_LANG" => "시스템언어",
    "STD_MON_CODE" => "통화",
    "STD_TIMEZONE" => "시간대",
    "STD_BIZMAN_YN" => "사업자구분",
    "STD_IF_SCTN" => "인터페이스구분",
    "STD_IF_METHOD" => "인터페이스방식",
    "STD_SYS_SCTN" => "시스템구분",
    "STD_SEND_RECV_SCTN" => "송수신구분",
    "STD_RSV_WORK_CYCLE" => "예약작업주기",
    "STD_PGM_SCTN" => "프로그램구분",
    "STD_ANNO_DGRCNT" => "고시회차",
    "STD_FIN_ORG" => "금융기관",
    "STD_HATAE" => "품명유형",
    "STD_ITEM_GRP" => "품목그룹",
    "STD_ITEM" => "품목",
    "STD_HWAJONG" => "화종",
    "STD_HWAJONG_GRP" => "화종그룹"
  }.freeze

  CODE_DETAIL_NAMES = {
    "STD_VAT_SCTN" => {
      "GENERAL" => "일반과세자",
      "SIMPLIFIED" => "간이과세자",
      "EXEMPT" => "면세"
    },
    "STD_SYS_LANG" => {
      "KO" => "한국어",
      "EN" => "영어",
      "ZH" => "중국어"
    },
    "STD_MON_CODE" => {
      "KRW" => "원화(KRW)",
      "USD" => "미국달러(USD)",
      "EUR" => "유로(EUR)",
      "JPY" => "엔화(JPY)",
      "CNY" => "위안화(CNY)"
    },
    "STD_TIMEZONE" => {
      "ASIA_SEOUL" => "서울 (UTC+09:00)",
      "ASIA_TOKYO" => "도쿄 (UTC+09:00)",
      "ASIA_SHANGHAI" => "상하이 (UTC+08:00)",
      "AMERICA_NEW_YORK" => "뉴욕 (UTC-05:00)"
    },
    "STD_BIZMAN_YN" => {
      "BUSINESS" => "사업자",
      "INDIVIDUAL" => "개인"
    },
    "STD_IF_SCTN" => {
      "INTERNAL" => "내부",
      "EXTERNAL" => "외부"
    },
    "STD_IF_METHOD" => {
      "API" => "API",
      "FILE" => "파일",
      "BATCH" => "배치"
    },
    "STD_SEND_RECV_SCTN" => {
      "SEND" => "송신",
      "RECV" => "수신",
      "BOTH" => "송수신"
    },
    "STD_RSV_WORK_CYCLE" => {
      "MINUTE" => "분",
      "HOURLY" => "시간",
      "DAILY" => "일",
      "WEEKLY" => "주",
      "MONTHLY" => "월"
    },
    "STD_PGM_SCTN" => {
      "BATCH" => "배치",
      "SERVICE" => "서비스",
      "WORKER" => "워커"
    },
    "STD_ANNO_DGRCNT" => {
      "FIRST" => "1차",
      "FINAL" => "최종"
    },
    "STD_FIN_ORG" => {
      "KDB" => "산업은행",
      "KOOKMIN" => "국민은행",
      "HANA" => "하나은행",
      "WOORI" => "우리은행"
    },
    "STD_HATAE" => {
      "GENERAL" => "일반",
      "COLD" => "냉장",
      "DANGEROUS" => "위험물"
    },
    "STD_ITEM_GRP" => {
      "RAW" => "원자재",
      "FINISH" => "완제품",
      "ETC" => "기타"
    },
    "STD_ITEM" => {
      "ITEM_A" => "품목 A",
      "ITEM_B" => "품목 B",
      "ITEM_C" => "품목 C"
    },
    "STD_HWAJONG" => {
      "DRY" => "건화물",
      "REEFER" => "냉동",
      "BULK" => "벌크"
    },
    "STD_HWAJONG_GRP" => {
      "SOLID" => "고체",
      "LIQUID" => "액체",
      "MIXED" => "혼합"
    }
  }.freeze

  MENU_NAMES = {
    "STD" => "기준정보",
    "STD_CORPORATION" => "법인관리",
    "STD_BIZ_CERT" => "사업자등록증관리",
    "STD_GOODS" => "품명관리",
    "STD_FAVORITE" => "즐겨찾기관리",
    "STD_INTERFACE_INFO" => "인터페이스정보관리",
    "STD_RESERVED_JOB" => "예약작업관리",
    "STD_EXCHANGE_RATE" => "환율관리"
  }.freeze

  def up
    localize_code_headers
    localize_code_details
    localize_menus
  end

  def down
  end

  private
    def localize_code_headers
      return unless table_exists?(:adm_code_headers)

      CODE_HEADER_NAMES.each do |code, code_name|
        scope = MigrationAdmCodeHeader.where(code: code)
        if scope.exists?
          scope.update_all(update_attrs_for(MigrationAdmCodeHeader).merge(code_name: code_name))
        end
      end
    end

    def localize_code_details
      return unless table_exists?(:adm_code_details)

      CODE_DETAIL_NAMES.each do |code, definitions|
        definitions.each do |detail_code, detail_code_name|
          scope = MigrationAdmCodeDetail.where(code: code, detail_code: detail_code)
          if scope.exists?
            scope.update_all(
              update_attrs_for(MigrationAdmCodeDetail).merge(
                detail_code_name: detail_code_name,
                short_name: detail_code_name
              )
            )
          end
        end
      end
    end

    def localize_menus
      return unless table_exists?(:adm_menus)

      MENU_NAMES.each do |menu_cd, menu_name|
        scope = MigrationAdmMenu.where(menu_cd: menu_cd)
        if scope.exists?
          scope.update_all(update_attrs_for(MigrationAdmMenu).merge(menu_nm: menu_name))
        end
      end
    end

    def update_attrs_for(klass)
      attrs = {}
      if klass.column_names.include?("update_by")
        attrs[:update_by] = "system"
      end
      if klass.column_names.include?("update_time")
        attrs[:update_time] = Time.current
      end
      attrs
    end
end
