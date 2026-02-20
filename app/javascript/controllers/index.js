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

import UserCrudController from "controllers/user_crud_controller"
application.register("user-crud", UserCrudController)

import DeptCrudController from "controllers/dept_crud_controller"
application.register("dept-crud", DeptCrudController)

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

import RoleUserGridController from "controllers/role_user_grid_controller"
application.register("role-user-grid", RoleUserGridController)

import UserMenuRoleGridController from "controllers/user_menu_role_grid_controller"
application.register("user-menu-role-grid", UserMenuRoleGridController)

import LucideController from "controllers/lucide_controller"
application.register("lucide", LucideController)
