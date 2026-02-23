puts "Seeding sample data for StdGood..."

sample_goods = [
  { goods_cd: "SAM00001", goods_nm: "샘플 냉동 해산물", hatae_cd: "COLD", item_grp_cd: "RAW", item_cd: "ITEM_A", hwajong_cd: "REEFER", hwajong_grp_cd: "SOLID", rmk_cd: "냉동 해산물 샘플입니다." },
  { goods_cd: "SAM00002", goods_nm: "산업용 기계부품", hatae_cd: "GENERAL", item_grp_cd: "FINISH", item_cd: "ITEM_B", hwajong_cd: "DRY", hwajong_grp_cd: "SOLID", rmk_cd: "박스 포장" },
  { goods_cd: "SAM00003", goods_nm: "화학 용재", hatae_cd: "DANGEROUS", item_grp_cd: "RAW", item_cd: "ITEM_C", hwajong_cd: "BULK", hwajong_grp_cd: "LIQUID", rmk_cd: "위험물 취급 주의" },
  { goods_cd: "SAM00004", goods_nm: "과일 농축액", hatae_cd: "COLD", item_grp_cd: "RAW", item_cd: "ITEM_A", hwajong_cd: "REEFER", hwajong_grp_cd: "LIQUID", rmk_cd: "온도 유지 필수" },
  { goods_cd: "SAM00005", goods_nm: "포장용 무지박스", hatae_cd: "GENERAL", item_grp_cd: "ETC", item_cd: "ITEM_B", hwajong_cd: "DRY", hwajong_grp_cd: "SOLID", rmk_cd: "일반 건화물" },
  { goods_cd: "SAM00006", goods_nm: "혼합 곡물", hatae_cd: "GENERAL", item_grp_cd: "RAW", item_cd: "ITEM_C", hwajong_cd: "BULK", hwajong_grp_cd: "MIXED", rmk_cd: "마대 포장" },
  { goods_cd: "SAM00007", goods_nm: "냉장 신선육", hatae_cd: "COLD", item_grp_cd: "RAW", item_cd: "ITEM_A", hwajong_cd: "REEFER", hwajong_grp_cd: "SOLID", rmk_cd: "당일 출고 요망" },
  { goods_cd: "SAM00008", goods_nm: "플라스틱 수지", hatae_cd: "GENERAL", item_grp_cd: "RAW", item_cd: "ITEM_B", hwajong_cd: "DRY", hwajong_grp_cd: "SOLID", rmk_cd: "팔레트 적재" },
  { goods_cd: "SAM00009", goods_nm: "공업용 윤활유", hatae_cd: "DANGEROUS", item_grp_cd: "FINISH", item_cd: "ITEM_C", hwajong_cd: "BULK", hwajong_grp_cd: "LIQUID", rmk_cd: "드럼 포장" },
  { goods_cd: "SAM00010", goods_nm: "수출용 전자제품", hatae_cd: "GENERAL", item_grp_cd: "FINISH", item_cd: "ITEM_A", hwajong_cd: "DRY", hwajong_grp_cd: "SOLID", rmk_cd: "충격 주의" }
]

sample_goods.each do |attrs|
  good = StdGood.find_or_initialize_by(goods_cd: attrs[:goods_cd])
  good.assign_attributes(attrs.merge(use_yn_cd: "Y"))
  if good.save
    puts "Saved: #{good.goods_cd} - #{good.goods_nm}"
  else
    puts "Failed: #{good.goods_cd} - #{good.errors.full_messages.join(', ')}"
  end
end

puts "Done!"
