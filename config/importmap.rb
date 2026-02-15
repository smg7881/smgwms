pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "lucide", to: "https://cdn.jsdelivr.net/npm/lucide@latest/dist/esm/lucide.js"

# AG Grid Community (ESM 엔트리로 pin)
pin "ag-grid-community",
  to: "https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/package/main.esm.mjs",
  preload: true
