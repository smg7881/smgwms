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
      code_name: "부가세구분",
      details: [
        { detail_code: "GENERAL", detail_code_name: "일반과세자", sort_order: 1 },
        { detail_code: "SIMPLIFIED", detail_code_name: "간이과세자", sort_order: 2 },
        { detail_code: "EXEMPT", detail_code_name: "면세", sort_order: 3 }
      ]
    },
    {
      code: "STD_SYS_LANG",
      code_name: "시스템언어",
      details: [
        { detail_code: "KO", detail_code_name: "한국어", sort_order: 1 },
        { detail_code: "EN", detail_code_name: "영어", sort_order: 2 },
        { detail_code: "ZH", detail_code_name: "중국어", sort_order: 3 }
      ]
    },
    {
      code: "STD_MON_CODE",
      code_name: "통화",
      details: [
        { detail_code: "KRW", detail_code_name: "원화(KRW)", sort_order: 1 },
        { detail_code: "USD", detail_code_name: "미국달러(USD)", sort_order: 2 },
        { detail_code: "EUR", detail_code_name: "유로(EUR)", sort_order: 3 },
        { detail_code: "JPY", detail_code_name: "엔화(JPY)", sort_order: 4 },
        { detail_code: "CNY", detail_code_name: "위안화(CNY)", sort_order: 5 }
      ]
    },
    {
      code: "STD_TIMEZONE",
      code_name: "시간대",
      details: [
        { detail_code: "ASIA_SEOUL", detail_code_name: "서울 (UTC+09:00)", sort_order: 1, ref_code: "KR" },
        { detail_code: "ASIA_TOKYO", detail_code_name: "도쿄 (UTC+09:00)", sort_order: 2, ref_code: "JP" },
        { detail_code: "ASIA_SHANGHAI", detail_code_name: "상하이 (UTC+08:00)", sort_order: 3, ref_code: "CN" },
        { detail_code: "AMERICA_NEW_YORK", detail_code_name: "뉴욕 (UTC-05:00)", sort_order: 4, ref_code: "US" }
      ]
    },
    {
      code: "STD_BIZMAN_YN",
      code_name: "사업자구분",
      details: [
        { detail_code: "BUSINESS", detail_code_name: "사업자", sort_order: 1 },
        { detail_code: "INDIVIDUAL", detail_code_name: "개인", sort_order: 2 }
      ]
    },
    {
      code: "STD_IF_SCTN",
      code_name: "인터페이스구분",
      details: [
        { detail_code: "INTERNAL", detail_code_name: "내부", sort_order: 1 },
        { detail_code: "EXTERNAL", detail_code_name: "외부", sort_order: 2 }
      ]
    },
    {
      code: "STD_IF_METHOD",
      code_name: "인터페이스방식",
      details: [
        { detail_code: "API", detail_code_name: "API", sort_order: 1 },
        { detail_code: "FILE", detail_code_name: "파일", sort_order: 2 },
        { detail_code: "BATCH", detail_code_name: "배치", sort_order: 3 }
      ]
    },
    {
      code: "STD_SYS_SCTN",
      code_name: "시스템구분",
      details: [
        { detail_code: "WMS", detail_code_name: "WMS", sort_order: 1 },
        { detail_code: "ERP", detail_code_name: "ERP", sort_order: 2 },
        { detail_code: "MES", detail_code_name: "MES", sort_order: 3 }
      ]
    },
    {
      code: "STD_SEND_RECV_SCTN",
      code_name: "송수신구분",
      details: [
        { detail_code: "SEND", detail_code_name: "송신", sort_order: 1 },
        { detail_code: "RECV", detail_code_name: "수신", sort_order: 2 },
        { detail_code: "BOTH", detail_code_name: "송수신", sort_order: 3 }
      ]
    },
    {
      code: "STD_RSV_WORK_CYCLE",
      code_name: "예약작업주기",
      details: [
        { detail_code: "MINUTE", detail_code_name: "분", sort_order: 1 },
        { detail_code: "HOURLY", detail_code_name: "시간", sort_order: 2 },
        { detail_code: "DAILY", detail_code_name: "일", sort_order: 3 },
        { detail_code: "WEEKLY", detail_code_name: "주", sort_order: 4 },
        { detail_code: "MONTHLY", detail_code_name: "월", sort_order: 5 }
      ]
    },
    {
      code: "STD_PGM_SCTN",
      code_name: "프로그램구분",
      details: [
        { detail_code: "BATCH", detail_code_name: "배치", sort_order: 1 },
        { detail_code: "SERVICE", detail_code_name: "서비스", sort_order: 2 },
        { detail_code: "WORKER", detail_code_name: "워커", sort_order: 3 }
      ]
    },
    {
      code: "STD_ANNO_DGRCNT",
      code_name: "고시회차",
      details: [
        { detail_code: "FIRST", detail_code_name: "1차", sort_order: 1 },
        { detail_code: "FINAL", detail_code_name: "최종", sort_order: 2 }
      ]
    },
    {
      code: "STD_FIN_ORG",
      code_name: "금융기관",
      details: [
        { detail_code: "KDB", detail_code_name: "산업은행", sort_order: 1 },
        { detail_code: "KOOKMIN", detail_code_name: "국민은행", sort_order: 2 },
        { detail_code: "HANA", detail_code_name: "하나은행", sort_order: 3 },
        { detail_code: "WOORI", detail_code_name: "우리은행", sort_order: 4 }
      ]
    },
    {
      code: "STD_HATAE",
      code_name: "품명유형",
      details: [
        { detail_code: "GENERAL", detail_code_name: "일반", sort_order: 1 },
        { detail_code: "COLD", detail_code_name: "냉장", sort_order: 2 },
        { detail_code: "DANGEROUS", detail_code_name: "위험물", sort_order: 3 }
      ]
    },
    {
      code: "STD_ITEM_GRP",
      code_name: "품목그룹",
      details: [
        { detail_code: "RAW", detail_code_name: "원자재", sort_order: 1 },
        { detail_code: "FINISH", detail_code_name: "완제품", sort_order: 2 },
        { detail_code: "ETC", detail_code_name: "기타", sort_order: 3 }
      ]
    },
    {
      code: "STD_ITEM",
      code_name: "품목",
      details: [
        { detail_code: "ITEM_A", detail_code_name: "품목 A", sort_order: 1 },
        { detail_code: "ITEM_B", detail_code_name: "품목 B", sort_order: 2 },
        { detail_code: "ITEM_C", detail_code_name: "품목 C", sort_order: 3 }
      ]
    },
    {
      code: "STD_HWAJONG",
      code_name: "화종",
      details: [
        { detail_code: "DRY", detail_code_name: "건화물", sort_order: 1 },
        { detail_code: "REEFER", detail_code_name: "냉동", sort_order: 2 },
        { detail_code: "BULK", detail_code_name: "벌크", sort_order: 3 }
      ]
    },
    {
      code: "STD_HWAJONG_GRP",
      code_name: "화종그룹",
      details: [
        { detail_code: "SOLID", detail_code_name: "고체", sort_order: 1 },
        { detail_code: "LIQUID", detail_code_name: "액체", sort_order: 2 },
        { detail_code: "MIXED", detail_code_name: "혼합", sort_order: 3 }
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
