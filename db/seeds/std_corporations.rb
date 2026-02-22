corporation_rows = [
  {
    corp_cd: "CP100001",
    corp_nm: "에스엠지홀딩스",
    indstype_cd: "물류업",
    bizcond_cd: "창고 운영업",
    rptr_nm_cd: "김민수",
    compreg_slip_cd: "110111-1000001",
    zip_cd: "04524",
    addr_cd: "서울특별시 중구 샘플로 1",
    dtl_addr_cd: "10F",
    vat_sctn_cd: "일반과세",
    use_yn_cd: "Y"
  },
  {
    corp_cd: "CP100002",
    corp_nm: "에스엠지리테일",
    indstype_cd: "도소매업",
    bizcond_cd: "유통업",
    rptr_nm_cd: "이지은",
    compreg_slip_cd: "110111-1000002",
    upper_corp_cd: "CP100001",
    zip_cd: "06164",
    addr_cd: "서울특별시 강남구 샘플로 20",
    dtl_addr_cd: "5F",
    vat_sctn_cd: "일반과세",
    use_yn_cd: "Y"
  },
  {
    corp_cd: "CP100003",
    corp_nm: "에스엠지글로벌",
    indstype_cd: "무역업",
    bizcond_cd: "수출입업",
    rptr_nm_cd: "박태훈",
    compreg_slip_cd: "110111-1000003",
    upper_corp_cd: "CP100001",
    zip_cd: "07325",
    addr_cd: "서울특별시 영등포구 샘플로 100",
    dtl_addr_cd: "12F",
    vat_sctn_cd: "면세",
    use_yn_cd: "Y"
  }
]

corporation_rows.each do |attrs|
  row = StdCorporation.find_or_initialize_by(corp_cd: attrs[:corp_cd])
  row.assign_attributes(attrs)
  row.save!
end

if defined?(StdCorporationCountry) && ActiveRecord::Base.connection.data_source_exists?(:std_corporation_countries)
  country_rows = [
    {
      corp_cd: "CP100001",
      seq: 1,
      ctry_cd: "KR",
      aply_mon_unit_cd: "MONTH",
      timezone_cd: "Asia/Seoul",
      std_time: "UTC+09:00",
      summer_time: "N",
      sys_lang_slc: "KO",
      vat_rt: 10.000,
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    },
    {
      corp_cd: "CP100001",
      seq: 2,
      ctry_cd: "US",
      aply_mon_unit_cd: "MONTH",
      timezone_cd: "America/Los_Angeles",
      std_time: "UTC-08:00",
      summer_time: "Y",
      sys_lang_slc: "EN",
      vat_rt: 0.000,
      rpt_yn_cd: "N",
      use_yn_cd: "Y"
    },
    {
      corp_cd: "CP100002",
      seq: 1,
      ctry_cd: "KR",
      aply_mon_unit_cd: "MONTH",
      timezone_cd: "Asia/Seoul",
      std_time: "UTC+09:00",
      summer_time: "N",
      sys_lang_slc: "KO",
      vat_rt: 10.000,
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    },
    {
      corp_cd: "CP100003",
      seq: 1,
      ctry_cd: "VN",
      aply_mon_unit_cd: "MONTH",
      timezone_cd: "Asia/Ho_Chi_Minh",
      std_time: "UTC+07:00",
      summer_time: "N",
      sys_lang_slc: "EN",
      vat_rt: 8.000,
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    }
  ]

  country_rows.each do |attrs|
    next unless StdCorporation.exists?(corp_cd: attrs[:corp_cd])

    row = StdCorporationCountry.find_or_initialize_by(corp_cd: attrs[:corp_cd], seq: attrs[:seq])
    row.assign_attributes(attrs)
    row.save!
  end
end
