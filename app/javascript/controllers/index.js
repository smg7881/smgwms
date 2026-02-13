import { application } from "controllers/application"

import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)

import TabsController from "controllers/tabs_controller"
application.register("tabs", TabsController)

import AgGridController from "controllers/ag_grid_controller"
application.register("ag-grid", AgGridController)
