menus = AdmMenu.all
counts = menus.group_by(&:menu_nm).transform_values(&:count)
duplicates = counts.select { |_, count| count > 1 }.keys

duplicates.each do |name|
  puts "--- #{name} ---"
  AdmMenu.where(menu_nm: name).order(:created_at).each do |m|
    puts "  cd: #{m.menu_cd}, parent: #{m.parent_cd}, level: #{m.menu_level}, type: #{m.menu_type}, id: #{m.id}, use_yn: #{m.use_yn}"
  end
end
