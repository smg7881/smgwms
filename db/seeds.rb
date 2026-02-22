# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
  user.role_cd = "ADMIN"
  user.user_id_code = "admin01"
  user.user_nm = "관리자"
end

admin_user = User.find_by(email_address: "admin@example.com")
if admin_user
  admin_user.update!(
    role_cd: "ADMIN",
    user_id_code: admin_user.user_id_code.presence || "admin01",
    user_nm: admin_user.user_nm.presence || "관리자"
  )
end

if defined?(AdmMenu) && ActiveRecord::Base.connection.data_source_exists?(:adm_menus)
  load Rails.root.join("db/seeds/adm_menus.rb")
end

if defined?(StdCorporation) && ActiveRecord::Base.connection.data_source_exists?(:std_corporations)
  load Rails.root.join("db/seeds/std_corporations.rb")
end

puts "기본 사용자 생성: admin@example.com / password"
