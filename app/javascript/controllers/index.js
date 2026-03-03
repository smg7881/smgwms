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
  ["std-workplace-grid", "controllers/std/std_workplace_grid_controller"],
  ["std-workplace-crud", "controllers/std/std_workplace_crud_controller"],
  ["std-region-grid", "controllers/std/std_region_grid_controller"],
  ["std-region-zip-grid", "controllers/std/std_region_zip_grid_controller"],
  ["std-country-grid", "controllers/std/std_country_grid_controller"],
  ["std-holiday-grid", "controllers/std/std_holiday_grid_controller"],
  ["std-approval-grid", "controllers/std/std_approval_grid_controller"],
  ["std-approval-request-grid", "controllers/std/std_approval_request_grid_controller"],
  ["std-approval-history-grid", "controllers/std/std_approval_history_grid_controller"],
  ["std-corporation-grid", "controllers/std/std_corporation_grid_controller"],
  ["std-business-certificate-grid", "controllers/std/std_business_certificate_grid_controller"],
  ["std-good-grid", "controllers/std/std_good_grid_controller"],
  ["std-favorite-grid", "controllers/std/std_favorite_grid_controller"],
  ["std-interface-info-grid", "controllers/std/std_interface_info_grid_controller"],
  ["std-reserved-job-grid", "controllers/std/std_reserved_job_grid_controller"],
  ["std-exchange-rate-grid", "controllers/std/std_exchange_rate_grid_controller"],
  ["purchase-contract-grid", "controllers/std/purchase_contract_grid_controller"],
  ["std-financial-institution-grid", "controllers/std/std_financial_institution_grid_controller"],
  ["std-client-item-code-crud", "controllers/std/std_client_item_code_crud_controller"],
  ["std-sellbuy-attribute-crud", "controllers/std/std_sellbuy_attribute_crud_controller"],
  ["sell-contract-grid", "controllers/std/sell_contract_grid_controller"],
  ["header-favorites", "controllers/header_favorites_controller"],
  ["om-customer-system-config-grid", "controllers/om/om_customer_system_config_grid_controller"],
  ["om-customer-order-officer-grid", "controllers/om/om_customer_order_officer_grid_controller"],
  ["om-order-officer-grid", "controllers/om/om_order_officer_grid_controller"],
  ["om-pre-order-file-upload", "controllers/om/om_pre_order_file_upload_controller"],
  ["om-pre-order-reception-error", "controllers/om/om_pre_order_reception_error_controller"],
  ["om-pre-order-reception", "controllers/om/om_pre_order_reception_controller"],
  ["om-internal-order", "controllers/om/om_internal_order_controller"],
  ["om-order-manual-completion", "controllers/om/om_order_manual_completion_controller"],
  ["wm-cust-rule-grid", "controllers/wm/wm_cust_rule_grid_controller"],
  ["wm-pur-fee-rt-grid", "controllers/wm/wm_pur_fee_rt_grid_controller"],
  ["wm-gr-prar-grid", "controllers/wm/wm_gr_prar_grid_controller"],
  ["flatpickr", "controllers/flatpickr_controller"],
  ["tom-select", "controllers/tom_select_controller"]
]

CONTROLLERS.forEach(([identifier, modulePath]) => {
  registerController(identifier, modulePath)
})
