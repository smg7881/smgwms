import { application } from "controllers/application"

import SidebarController from "controllers/sidebar_controller"
import TabsController from "controllers/tabs_controller"
import ResourceFormController from "controllers/resource_form_controller"
import SearchFormController from "controllers/search_form_controller"
import SearchPopupController from "controllers/search_popup_controller"
import SearchPopupGridController from "controllers/search_popup_grid_controller"

application.register("sidebar", SidebarController)
application.register("tabs", TabsController)
application.register("resource-form", ResourceFormController)
application.register("search-form", SearchFormController)
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
  ["menu-crud", "controllers/system/menu_crud_controller"],
  ["user-crud", "controllers/system/user_crud_controller"],
  ["dept-crud", "controllers/system/dept_crud_controller"],
  ["notice-crud", "controllers/system/notice_crud_controller"],
  ["code-grid", "controllers/system/code_grid_controller"],
  ["role-grid", "controllers/system/role_grid_controller"],
  ["workplace-grid", "controllers/wm/workplace_grid_controller"],
  ["area-grid", "controllers/wm/area_grid_controller"],
  ["zone-grid", "controllers/wm/zone_grid_controller"],
  ["location-grid", "controllers/wm/location_grid_controller"],
  ["role-user-grid", "controllers/system/role_user_grid_controller"],
  ["user-menu-role-grid", "controllers/system/user_menu_role_grid_controller"],
  ["lucide", "controllers/lucide_controller"],
  ["client-grid", "controllers/std/client_grid_controller"],
  ["std-customer-client-grid", "controllers/std/customer_client_grid_controller"],
  ["std-workplace-grid", "controllers/std/workplace_grid_controller"],
  ["std-workplace-crud", "controllers/std/workplace_crud_controller"],
  ["std-work-step-crud", "controllers/std/work_step_crud_controller"],
  ["std-region-grid", "controllers/std/region_grid_controller"],
  ["std-zipcode-crud", "controllers/std/zipcode_crud_controller"],
  ["std-region-zip-grid", "controllers/std/region_zip_grid_controller"],
  ["std-country-grid", "controllers/std/country_grid_controller"],
  ["std-holiday-grid", "controllers/std/holiday_grid_controller"],
  ["std-approval-grid", "controllers/std/approval_grid_controller"],
  ["std-approval-request-grid", "controllers/std/approval_request_grid_controller"],
  ["std-approval-history-grid", "controllers/std/approval_history_grid_controller"],
  ["std-corporation-grid", "controllers/std/corporation_grid_controller"],
  ["std-business-certificate-crud", "controllers/std/business_certificate_crud_controller"],
  ["std-good-grid", "controllers/std/good_grid_controller"],
  ["std-favorite-grid", "controllers/std/favorite_grid_controller"],
  ["std-interface-info-grid", "controllers/std/interface_info_grid_controller"],
  ["std-reserved-job-grid", "controllers/std/reserved_job_grid_controller"],
  ["std-exchange-rate-grid", "controllers/std/exchange_rate_grid_controller"],
  ["std-work-routing-step-grid", "controllers/std/work_routing_step_grid_controller"],
  ["purchase-contract-grid", "controllers/std/purchase_contract_grid_controller"],
  ["std-financial-institution-grid", "controllers/std/financial_institution_grid_controller"],
  ["std-client-item-code-crud", "controllers/std/client_item_code_crud_controller"],
  ["std-sellbuy-attribute-crud", "controllers/std/sellbuy_attribute_crud_controller"],
  ["sell-contract-grid", "controllers/std/sell_contract_grid_controller"],
  ["header-favorites", "controllers/header_favorites_controller"],
  ["om-customer-system-config-grid", "controllers/om/customer_system_config_grid_controller"],
  ["om-customer-order-officer-grid", "controllers/om/customer_order_officer_grid_controller"],
  ["om-order-officer-grid", "controllers/om/order_officer_grid_controller"],
  ["om-waiting-order-grid", "controllers/om/waiting_order_grid_controller"],
  ["om-pre-order-file-upload", "controllers/om/pre_order_file_upload_controller"],
  ["om-pre-order-reception-error", "controllers/om/pre_order_reception_error_controller"],
  ["om-pre-order-reception", "controllers/om/pre_order_reception_controller"],
  ["om-internal-order", "controllers/om/internal_order_controller"],
  ["om-order-manual-completion", "controllers/om/order_manual_completion_controller"],
  ["wm-cust-rule-grid", "controllers/wm/cust_rule_grid_controller"],
  ["wm-pur-fee-rt-grid", "controllers/wm/pur_fee_rt_grid_controller"],
  ["wm-gr-prar-grid", "controllers/wm/gr_prar_grid_controller"],
  ["flatpickr", "controllers/flatpickr_controller"],
  ["tom-select", "controllers/tom_select_controller"]
]

CONTROLLERS.forEach(([identifier, modulePath]) => {
  registerController(identifier, modulePath)
})
