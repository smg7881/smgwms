pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "trix", to: "https://cdn.jsdelivr.net/npm/trix@2.1.15/dist/trix.esm.min.js"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/controllers/grid", under: "controllers/grid"
pin_all_from "app/javascript/components", under: "components"
pin_all_from "app/javascript/components/ui", under: "components/ui"
pin "lucide", to: "https://cdn.jsdelivr.net/npm/lucide@0.468.0/dist/esm/lucide.js"

# AG Grid Community (ESM 엔트리로 pin)
pin "ag-grid-community",
  to: "https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/package/main.esm.mjs",
  preload: true

pin "@rails/request.js", to: "https://ga.jspm.io/npm:@rails/request.js@0.0.9/src/index.js"
