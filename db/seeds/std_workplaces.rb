if defined?(AdmDept) && ActiveRecord::Base.connection.data_source_exists?(:adm_depts)
  dept_rows = [
    { dept_code: "WH", dept_nm: "물류운영팀", dept_type: "TEAM", parent_dept_code: nil, dept_order: 10, use_yn: "Y" },
    { dept_code: "PK", dept_nm: "피킹팀", dept_type: "TEAM", parent_dept_code: "WH", dept_order: 11, use_yn: "Y" },
    { dept_code: "QA", dept_nm: "품질관리팀", dept_type: "TEAM", parent_dept_code: "WH", dept_order: 12, use_yn: "Y" },
    { dept_code: "RT", dept_nm: "소매운영팀", dept_type: "TEAM", parent_dept_code: nil, dept_order: 20, use_yn: "Y" },
    { dept_code: "GL", dept_nm: "글로벌운영팀", dept_type: "TEAM", parent_dept_code: nil, dept_order: 30, use_yn: "Y" }
  ]

  dept_rows.each do |attrs|
    row = AdmDept.find_or_initialize_by(dept_code: attrs[:dept_code])
    row.assign_attributes(attrs)
    row.save!
  end
end

workplace_rows = [
  {
    corp_cd: "CP100001",
    workpl_cd: "WP100001",
    upper_workpl_cd: nil,
    dept_cd: "WH",
    workpl_nm: "서울통합물류센터",
    workpl_sctn_cd: "WH",
    capa_spec_unit_cd: "M3",
    max_capa: 25000,
    adpt_capa: 20000,
    dimem_spec_unit_cd: "M2",
    dimem: 4200,
    wm_yn_cd: "Y",
    bzac_cd: nil,
    ctry_cd: "KR",
    zip_cd: "04524",
    addr_cd: "서울특별시 중구 샘플로 1",
    dtl_addr_cd: "B1~3F",
    use_yn_cd: "Y",
    remk_cd: "본사 권역 대표 물류센터"
  },
  {
    corp_cd: "CP100001",
    workpl_cd: "WP100002",
    upper_workpl_cd: "WP100001",
    dept_cd: "PK",
    workpl_nm: "서울피킹센터",
    workpl_sctn_cd: "PK",
    capa_spec_unit_cd: "EA",
    max_capa: 120000,
    adpt_capa: 100000,
    dimem_spec_unit_cd: "M2",
    dimem: 1800,
    wm_yn_cd: "Y",
    bzac_cd: nil,
    ctry_cd: "KR",
    zip_cd: "04524",
    addr_cd: "서울특별시 중구 샘플로 1",
    dtl_addr_cd: "2F",
    use_yn_cd: "Y",
    remk_cd: "소형/중형 상품 피킹 전용"
  },
  {
    corp_cd: "CP100001",
    workpl_cd: "WP100003",
    upper_workpl_cd: "WP100001",
    dept_cd: "QA",
    workpl_nm: "서울검품센터",
    workpl_sctn_cd: "QA",
    capa_spec_unit_cd: "EA",
    max_capa: 80000,
    adpt_capa: 70000,
    dimem_spec_unit_cd: "M2",
    dimem: 1500,
    wm_yn_cd: "Y",
    bzac_cd: nil,
    ctry_cd: "KR",
    zip_cd: "04524",
    addr_cd: "서울특별시 중구 샘플로 1",
    dtl_addr_cd: "3F",
    use_yn_cd: "Y",
    remk_cd: "입출고 검수 및 품질관리"
  },
  {
    corp_cd: "CP100002",
    workpl_cd: "WP200001",
    upper_workpl_cd: nil,
    dept_cd: "RT",
    workpl_nm: "강남리테일허브",
    workpl_sctn_cd: "STORE",
    capa_spec_unit_cd: "EA",
    max_capa: 50000,
    adpt_capa: 42000,
    dimem_spec_unit_cd: "M2",
    dimem: 2200,
    wm_yn_cd: "N",
    bzac_cd: nil,
    ctry_cd: "KR",
    zip_cd: "06164",
    addr_cd: "서울특별시 강남구 샘플로 20",
    dtl_addr_cd: "1~4F",
    use_yn_cd: "Y",
    remk_cd: "리테일 배송 허브"
  },
  {
    corp_cd: "CP100003",
    workpl_cd: "WP300001",
    upper_workpl_cd: nil,
    dept_cd: "GL",
    workpl_nm: "글로벌수출센터",
    workpl_sctn_cd: "EXPORT",
    capa_spec_unit_cd: "EA",
    max_capa: 90000,
    adpt_capa: 75000,
    dimem_spec_unit_cd: "M2",
    dimem: 2600,
    wm_yn_cd: "Y",
    bzac_cd: nil,
    ctry_cd: "VN",
    zip_cd: "07325",
    addr_cd: "서울특별시 영등포구 샘플로 100",
    dtl_addr_cd: "12F",
    use_yn_cd: "Y",
    remk_cd: "해외 출고/통관 연계"
  }
]

workplace_rows.each do |attrs|
  row = StdWorkplace.find_or_initialize_by(workpl_cd: attrs[:workpl_cd])
  row.assign_attributes(attrs)
  row.save!
end

puts "STD 작업장 샘플 데이터 #{workplace_rows.size}건 반영 완료"
