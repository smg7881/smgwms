import { application } from "controllers/application"

import SidebarController from "controllers/sidebar_controller"
import TabsController from "controllers/tabs_controller"
import ResourceFormController from "controllers/resource_form_controller"
import SearchPopupController from "controllers/search_popup_controller"
import SearchPopupGridController from "controllers/search_popup_grid_controller"

application.register("sidebar", SidebarController)
application.register("tabs", TabsController)
application.register("resource-form", ResourceFormController)
application.register("search-popup", SearchPopupController)
application.register("search-popup-grid", SearchPopupGridController)

function registerController(identifier, modulePath) {
  import(modulePath)
    .then((module) => {
      if (module?.default) {
        application.register(identifier, module.default)
      } else {
        console.error(`[stimulus] controller has no default export: ${identifier} (${modulePath})`)
      }
    })
    .catch((error) => {
      console.error(`[stimulus] failed to load controller "${identifier}" from "${modulePath}"`, error)
    })
}

const CONTROLLERS = [
  ["ag-grid", "controllers/ag_grid_controller"],
  ["grid-actions", "controllers/grid_actions_controller"],
  ["menu-crud", "controllers/menu_crud_controller"],
  ["user-crud", "controllers/user_crud_controller"],
  ["dept-crud", "controllers/dept_crud_controller"],
  ["notice-crud", "controllers/notice_crud_controller"],
  ["code-grid", "controllers/code_grid_controller"],
  ["role-grid", "controllers/role_grid_controller"],
  ["workplace-grid", "controllers/workplace_grid_controller"],
  ["area-grid", "controllers/area_grid_controller"],
  ["zone-grid", "controllers/zone_grid_controller"],
  ["location-grid", "controllers/location_grid_controller"],
  ["role-user-grid", "controllers/role_user_grid_controller"],
  ["user-menu-role-grid", "controllers/user_menu_role_grid_controller"],
  ["lucide", "controllers/lucide_controller"],
  ["client-grid", "controllers/client_grid_controller"],
  ["std-workplace-grid", "controllers/std_workplace_grid_controller"],
  ["std-region-grid", "controllers/std_region_grid_controller"],
  ["std-region-zip-grid", "controllers/std_region_zip_grid_controller"],
  ["std-country-grid", "controllers/std_country_grid_controller"],
  ["std-holiday-grid", "controllers/std_holiday_grid_controller"],
  ["std-approval-grid", "controllers/std_approval_grid_controller"],
  ["std-approval-request-grid", "controllers/std_approval_request_grid_controller"],
  ["std-approval-history-grid", "controllers/std_approval_history_grid_controller"],
  ["std-corporation-grid", "controllers/std_corporation_grid_controller"],
  ["std-business-certificate-grid", "controllers/std_business_certificate_grid_controller"],
  ["std-good-grid", "controllers/std_good_grid_controller"],
  ["std-favorite-grid", "controllers/std_favorite_grid_controller"],
  ["std-interface-info-grid", "controllers/std_interface_info_grid_controller"],
  ["std-reserved-job-grid", "controllers/std_reserved_job_grid_controller"],
  ["std-exchange-rate-grid", "controllers/std_exchange_rate_grid_controller"],
  ["header-favorites", "controllers/header_favorites_controller"]
]

CONTROLLERS.forEach(([identifier, modulePath]) => {
  registerController(identifier, modulePath)
})

