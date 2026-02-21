/**
 * index.js
 * 
 * Stimulus 애플리케이션의 엔트리 포인트입니다.
 * 이곳에서 모든 Stimulus 컨트롤러들을 import 하고, application.register를 통해 등록합니다.
 * 등록된 이름(예: "sidebar")은 HTML의 data-controller="sidebar" 형태로 사용됩니다.
 */
import { application } from "controllers/application"

// 사이드바 토글 및 상태 관리를 담당하는 컨트롤러
import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)

// 상단 탭(메뉴 열기/닫기/전환) 관련 상태와 UI 관리를 담당
import TabsController from "controllers/tabs_controller"
application.register("tabs", TabsController)

// AG Grid 초기화, 설정 적용, 이벤트 바인딩 등을 총괄하는 핵심 컨트롤러
import AgGridController from "controllers/ag_grid_controller"
application.register("ag-grid", AgGridController)

// 그리드 상단의 공통 액션(추가, 삭제, 엑셀 다운로드 등) 버튼 이벤트를 처리
import GridActionsController from "controllers/grid_actions_controller"
application.register("grid-actions", GridActionsController)

// 메뉴 관리 CRUD 폼 처리를 담당하는 컨트롤러
import MenuCrudController from "controllers/menu_crud_controller"
application.register("menu-crud", MenuCrudController)

// 공통 리소스 폼(모달/서브밋 폼 등)의 이벤트 처리
import ResourceFormController from "controllers/resource_form_controller"
application.register("resource-form", ResourceFormController)

// 사용자 관리 CRUD 로직 처리
import UserCrudController from "controllers/user_crud_controller"
application.register("user-crud", UserCrudController)

// 부서 관리 CRUD 로직 처리
import DeptCrudController from "controllers/dept_crud_controller"
application.register("dept-crud", DeptCrudController)

// 공지사항 관리 CRUD 로직 처리
import NoticeCrudController from "controllers/notice_crud_controller"
application.register("notice-crud", NoticeCrudController)

// 공통코드/상세코드 관리를 위한 단일 그리드 제어 컨트롤러
import CodeGridController from "controllers/code_grid_controller"
application.register("code-grid", CodeGridController)

// 권한 관리를 위한 그리드 제어 컨트롤러
import RoleGridController from "controllers/role_grid_controller"
application.register("role-grid", RoleGridController)

// 작업장 관리를 위한 그리드 제어 컨트롤러
import WorkplaceGridController from "controllers/workplace_grid_controller"
application.register("workplace-grid", WorkplaceGridController)

// 권역 관리를 위한 그리드 제어 컨트롤러
import AreaGridController from "controllers/area_grid_controller"
application.register("area-grid", AreaGridController)

// 존(Zone) 관리를 위한 그리드 제어 컨트롤러
import ZoneGridController from "controllers/zone_grid_controller"
application.register("zone-grid", ZoneGridController)

// 로케이션(Location) 관리를 위한 그리드 제어 컨트롤러
import LocationGridController from "controllers/location_grid_controller"
application.register("location-grid", LocationGridController)

// 권한별 사용자 할당 관리를 위한 그리드 제어 컨트롤러
import RoleUserGridController from "controllers/role_user_grid_controller"
application.register("role-user-grid", RoleUserGridController)

// 사용자-메뉴-권한 연결 관리를 위한 복합 그리드 제어 컨트롤러
import UserMenuRoleGridController from "controllers/user_menu_role_grid_controller"
application.register("user-menu-role-grid", UserMenuRoleGridController)

// Lucide 아이콘 렌더링/업데이트 관리 컨트롤러
import LucideController from "controllers/lucide_controller"
application.register("lucide", LucideController)
