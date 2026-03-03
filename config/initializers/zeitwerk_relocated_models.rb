std_and_system_model_dirs = [
  Rails.root.join("app/models/std"),
  Rails.root.join("app/models/system")
]

prefixed_model_files = Dir.glob(Rails.root.join("app/models/om/om_*.rb")).map { |path| Pathname.new(path) } +
  Dir.glob(Rails.root.join("app/models/wm/wm_*.rb")).map { |path| Pathname.new(path) }

Rails.autoloaders.main.ignore(*(std_and_system_model_dirs + prefixed_model_files))

Rails.application.config.to_prepare do
  relocated_model_files = Dir.glob(Rails.root.join("app/models/std/std_*.rb")) +
    Dir.glob(Rails.root.join("app/models/system/adm_*.rb")) +
    Dir.glob(Rails.root.join("app/models/om/om_*.rb")) +
    Dir.glob(Rails.root.join("app/models/wm/wm_*.rb"))

  relocated_model_files.sort.each do |file_path|
    require_dependency file_path
  end
end
