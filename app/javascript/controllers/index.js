import { application } from "controllers/application"

import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)

import TabsController from "controllers/tabs_controller"
application.register("tabs", TabsController)

import AgGridController from "controllers/ag_grid_controller"
application.register("ag-grid", AgGridController)

import GridActionsController from "controllers/grid_actions_controller"
application.register("grid-actions", GridActionsController)

import MenuCrudController from "controllers/menu_crud_controller"
application.register("menu-crud", MenuCrudController)

import ResourceFormController from "controllers/resource_form_controller"
application.register("resource-form", ResourceFormController)

import SearchPopupController from "controllers/search_popup_controller"
application.register("search-popup", SearchPopupController)

import UserCrudController from "controllers/user_crud_controller"
application.register("user-crud", UserCrudController)

import DeptCrudController from "controllers/dept_crud_controller"
application.register("dept-crud", DeptCrudController)

import NoticeCrudController from "controllers/notice_crud_controller"
application.register("notice-crud", NoticeCrudController)

import CodeGridController from "controllers/code_grid_controller"
application.register("code-grid", CodeGridController)

import RoleGridController from "controllers/role_grid_controller"
application.register("role-grid", RoleGridController)

import WorkplaceGridController from "controllers/workplace_grid_controller"
application.register("workplace-grid", WorkplaceGridController)

import AreaGridController from "controllers/area_grid_controller"
application.register("area-grid", AreaGridController)

import ZoneGridController from "controllers/zone_grid_controller"
application.register("zone-grid", ZoneGridController)

import LocationGridController from "controllers/location_grid_controller"
application.register("location-grid", LocationGridController)

import RoleUserGridController from "controllers/role_user_grid_controller"
application.register("role-user-grid", RoleUserGridController)

import UserMenuRoleGridController from "controllers/user_menu_role_grid_controller"
application.register("user-menu-role-grid", UserMenuRoleGridController)

import LucideController from "controllers/lucide_controller"
application.register("lucide", LucideController)

import ClientGridController from "controllers/client_grid_controller"
application.register("client-grid", ClientGridController)

import StdWorkplaceGridController from "controllers/std_workplace_grid_controller"
application.register("std-workplace-grid", StdWorkplaceGridController)

import StdRegionGridController from "controllers/std_region_grid_controller"
application.register("std-region-grid", StdRegionGridController)

import StdRegionZipGridController from "controllers/std_region_zip_grid_controller"
application.register("std-region-zip-grid", StdRegionZipGridController)

import StdCountryGridController from "controllers/std_country_grid_controller"
application.register("std-country-grid", StdCountryGridController)

import StdHolidayGridController from "controllers/std_holiday_grid_controller"
application.register("std-holiday-grid", StdHolidayGridController)

import StdApprovalGridController from "controllers/std_approval_grid_controller"
application.register("std-approval-grid", StdApprovalGridController)

import StdApprovalRequestGridController from "controllers/std_approval_request_grid_controller"
application.register("std-approval-request-grid", StdApprovalRequestGridController)

import StdApprovalHistoryGridController from "controllers/std_approval_history_grid_controller"
application.register("std-approval-history-grid", StdApprovalHistoryGridController)
