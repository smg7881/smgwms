class SeedStdOperationCodesAndZipcodes < ActiveRecord::Migration[8.1]
  class MigrationAdmCodeHeader < ApplicationRecord
    self.table_name = "adm_code_headers"
  end

  class MigrationAdmCodeDetail < ApplicationRecord
    self.table_name = "adm_code_details"
  end

  class MigrationStdCountry < ApplicationRecord
    self.table_name = "std_countries"
  end

  class MigrationStdZipCode < ApplicationRecord
    self.table_name = "std_zip_codes"
  end

  CODE_DEFINITIONS = [
    {
      code: "STD_WORKPL_SCTN",
      code_name: "작업장구분",
      details: [
        { detail_code: "WH", detail_code_name: "창고", sort_order: 1 },
        { detail_code: "OFFICE", detail_code_name: "사무소", sort_order: 2 },
        { detail_code: "YARD", detail_code_name: "야드", sort_order: 3 }
      ]
    },
    {
      code: "STD_CAPA_UNIT",
      code_name: "용량단위",
      details: [
        { detail_code: "CBM", detail_code_name: "CBM", sort_order: 1 },
        { detail_code: "PLT", detail_code_name: "PLT", sort_order: 2 },
        { detail_code: "EA", detail_code_name: "EA", sort_order: 3 }
      ]
    },
    {
      code: "STD_DIMEM_UNIT",
      code_name: "면적단위",
      details: [
        { detail_code: "M2", detail_code_name: "m2", sort_order: 1 },
        { detail_code: "FT2", detail_code_name: "ft2", sort_order: 2 },
        { detail_code: "PY", detail_code_name: "평", sort_order: 3 }
      ]
    },
    {
      code: "STD_CTRY_AREA",
      code_name: "국가지역코드",
      details: [
        { detail_code: "ASIA", detail_code_name: "아시아", sort_order: 1 },
        { detail_code: "AMER", detail_code_name: "미주", sort_order: 2 },
        { detail_code: "EURO", detail_code_name: "유럽", sort_order: 3 }
      ]
    },
    {
      code: "STD_APV_TYPE",
      code_name: "결재유형",
      details: [
        { detail_code: "CODE", detail_code_name: "코드승인", sort_order: 1 },
        { detail_code: "DATA", detail_code_name: "데이터승인", sort_order: 2 },
        { detail_code: "PAYMENT", detail_code_name: "결재승인", sort_order: 3 }
      ]
    },
    {
      code: "STD_APV_STATUS",
      code_name: "결재상태",
      details: [
        { detail_code: "REQUESTED", detail_code_name: "요청", sort_order: 1 },
        { detail_code: "APPROVED", detail_code_name: "승인", sort_order: 2 },
        { detail_code: "REJECTED", detail_code_name: "반려", sort_order: 3 },
        { detail_code: "CANCELED", detail_code_name: "취소", sort_order: 4 }
      ]
    },
    {
      code: "STD_APV_POSITION",
      code_name: "결재직책",
      details: [
        { detail_code: "TEAM_LEAD", detail_code_name: "팀장", sort_order: 1 },
        { detail_code: "MANAGER", detail_code_name: "관리자", sort_order: 2 },
        { detail_code: "DIRECTOR", detail_code_name: "부서장", sort_order: 3 }
      ]
    }
  ].freeze

  COUNTRY_ROWS = [
    { ctry_cd: "KR", ctry_nm: "대한민국", ctry_eng_nm: "Korea", ctry_ar_cd: "ASIA", ctry_telno: "82" },
    { ctry_cd: "US", ctry_nm: "미국", ctry_eng_nm: "United States", ctry_ar_cd: "AMER", ctry_telno: "1" },
    { ctry_cd: "JP", ctry_nm: "일본", ctry_eng_nm: "Japan", ctry_ar_cd: "ASIA", ctry_telno: "81" },
    { ctry_cd: "CN", ctry_nm: "중국", ctry_eng_nm: "China", ctry_ar_cd: "ASIA", ctry_telno: "86" }
  ].freeze

  ZIP_ROWS = [
    { ctry_cd: "KR", zipcd: "04524", seq_no: 1, zipaddr: "서울특별시 중구 세종대로 110", sido: "서울특별시", sgng: "중구", eupdiv: "태평로1가" },
    { ctry_cd: "KR", zipcd: "06164", seq_no: 1, zipaddr: "서울특별시 강남구 테헤란로 521", sido: "서울특별시", sgng: "강남구", eupdiv: "삼성동" },
    { ctry_cd: "KR", zipcd: "46725", seq_no: 1, zipaddr: "부산광역시 강서구 녹산산업중로 333", sido: "부산광역시", sgng: "강서구", eupdiv: "송정동" },
    { ctry_cd: "US", zipcd: "10001", seq_no: 1, zipaddr: "350 5th Ave, New York, NY", sido: "NY", sgng: "New York", eupdiv: "Manhattan" },
    { ctry_cd: "US", zipcd: "90013", seq_no: 1, zipaddr: "200 N Spring St, Los Angeles, CA", sido: "CA", sgng: "Los Angeles", eupdiv: "Downtown" }
  ].freeze

  def up
    seed_codes!
    seed_countries!
    seed_zip_codes!
  end

  def down
    if table_exists?(:adm_code_headers) && table_exists?(:adm_code_details)
      codes = CODE_DEFINITIONS.map { |definition| definition[:code] }
      MigrationAdmCodeDetail.where(code: codes).delete_all
      MigrationAdmCodeHeader.where(code: codes).delete_all
    end

    if table_exists?(:std_countries)
      MigrationStdCountry.where(ctry_cd: COUNTRY_ROWS.map { |row| row[:ctry_cd] }).delete_all
    end

    if table_exists?(:std_zip_codes)
      ZIP_ROWS.each do |row|
        MigrationStdZipCode.where(ctry_cd: row[:ctry_cd], zipcd: row[:zipcd], seq_no: row[:seq_no]).delete_all
      end
    end
  end

  private
    def seed_codes!
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

    def seed_countries!
      return unless table_exists?(:std_countries)

      now = Time.current
      COUNTRY_ROWS.each do |row|
        country = MigrationStdCountry.find_or_initialize_by(ctry_cd: row[:ctry_cd])
        country.assign_attributes(
          ctry_nm: row[:ctry_nm],
          ctry_eng_nm: row[:ctry_eng_nm],
          ctry_ar_cd: row[:ctry_ar_cd],
          ctry_telno: row[:ctry_telno],
          use_yn_cd: "Y",
          update_by: "system",
          update_time: now
        )
        if country.new_record?
          country.create_by = "system"
          country.create_time = now
        end
        country.save!
      end
    end

    def seed_zip_codes!
      return unless table_exists?(:std_zip_codes)

      now = Time.current
      ZIP_ROWS.each do |row|
        zip_code = MigrationStdZipCode.find_or_initialize_by(
          ctry_cd: row[:ctry_cd],
          zipcd: row[:zipcd],
          seq_no: row[:seq_no]
        )
        zip_code.assign_attributes(
          zipaddr: row[:zipaddr],
          sido: row[:sido],
          sgng: row[:sgng],
          eupdiv: row[:eupdiv],
          use_yn_cd: "Y",
          update_by: "system",
          update_time: now
        )
        if zip_code.new_record?
          zip_code.create_by = "system"
          zip_code.create_time = now
        end
        zip_code.save!
      end
    end
end
