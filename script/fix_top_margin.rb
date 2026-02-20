Dir.glob("app/components/**/*.html.erb").each do |f|
  text = File.read(f)
  if text.gsub!('<div class="flex items-center justify-between gap-3 mb-3 mt-6">', '<div class="flex items-center justify-between gap-3 mb-3 mt-2">')
    File.write(f, text)
    puts "Fixed top margin in #{f}"
  end
end
