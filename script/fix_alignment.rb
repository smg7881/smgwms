Dir.glob("app/components/**/*.html.erb").each do |f|
  text = File.read(f)
  if text.gsub!('<div class="page-header-wrapper">', '<div class="flex items-center justify-between gap-3 mb-3 mt-6">')
    File.write(f, text)
    puts "Fixed #{f}"
  end
end
