File.write('tmp/menus.json', AdmMenu.where("menu_cd LIKE 'OM%' OR menu_url LIKE '/om/%'").map { |m| { menu_cd: m.menu_cd, menu_nm: m.menu_nm, menu_url: m.menu_url, parent_cd: m.parent_cd } }.to_json)
