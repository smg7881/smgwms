relocated_model_dirs = [
  Rails.root.join("app/models/std"),
  Rails.root.join("app/models/system"),
  Rails.root.join("app/models/om")
]

wm_mismatched_model_files = %w[area location workplace zone].map do |name|
  Rails.root.join("app/models/wm/#{name}.rb")
end

Rails.autoloaders.main.ignore(*(relocated_model_dirs + wm_mismatched_model_files))

Rails.application.config.to_prepare do
  relocated_model_files = relocated_model_dirs.flat_map do |dir|
    Dir.glob(dir.join("*.rb"))
  end + wm_mismatched_model_files.map(&:to_s)

  relocated_model_files.sort.each do |file_path|
    require_dependency file_path
  end
end
