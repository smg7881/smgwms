# AG Grid 리팩토링 전체 작업 보고서 (2026-03-01)

## 1. 작업 기준
- 기준 문서: `doc/기능개선/ag_grid_controller_refactoring_plan.md`
- 참조 문서:
  - `doc/기능개선/ag_grid_refactor_phase1_spec.md`
  - `doc/기능개선/ag_grid_controller_refactoring_execution_plan.md`

## 2. 완료 범위 요약
- `BaseGridController` 중심 마스터-디테일 공통화 적용
- `MasterDetailGridController` 상속 컨트롤러 전부 전환
- `registerGridInstance` 직접 사용 컨트롤러 전부 전환
- `master_detail_grid_controller.js`, `grid/core/grid_registration.js` 삭제
- `grid_utils.js`의 `registerGridInstance` 의존 제거
- `grid_event_manager.js`의 `resolveAgGridRegistration` 제거

## 3. 주요 구현 내용

### 3.1 BaseGridController 확장
- `gridRoles` 스키마 확장 지원:
  - `manager`, `parentGrid`, `detailLoader`, `onMasterRowChange`, `masterKeyField`
- 다중 그리드에서 role별 manager 자동 attach
- parent-child 관계 자동 인식 후 마스터 이벤트 기반 디테일 자동 연동
- `ag-grid:rowFocused` + `rowDataUpdated` 기반 자동 조회 흐름 적용
- `grid:before-search` 공통 초기화 처리 추가
- 공용 메서드 추가:
  - `gridManager(name)`
  - `selectFirstRow(name, options)`
  - `selectFirstMasterRow(masterRole)`
  - `beforeSearchReset()` 훅

### 3.2 Master-Detail 컨트롤러 전환 완료
- 전환 대상:
  - `code_grid_controller.js`
  - `std_corporation_grid_controller.js`
  - `wm_pur_fee_rt_grid_controller.js`
  - `client_grid_controller.js`
  - `sell_contract_grid_controller.js`
  - `purchase_contract_grid_controller.js`
  - `wm_gr_prar_grid_controller.js`
- 공통 변경:
  - `MasterDetailGridController` -> `BaseGridController`
  - `gridRoles(parentGrid)` 기반 마스터-디테일 연동
  - `onAllGridsReady`에서 manager/controller alias 초기화
  - `beforeSearchReset` 적용(선택 상태/라벨/상세 초기화)

### 3.3 registerGridInstance 직접 사용 컨트롤러 전환 완료
- 전환 대상:
  - `om_pre_order_file_upload_controller.js`
  - `role_user_grid_controller.js`
  - `search_popup_grid_controller.js`
  - `std_favorite_grid_controller.js`
  - `std_region_zip_grid_controller.js`
  - `user_menu_role_grid_controller.js`
  - `zone_grid_controller.js`
- 공통 변경:
  - `registerGridInstance`, `resolveAgGridRegistration` 제거
  - `BaseGridController + gridRoles` 또는 직접 `ag-grid:ready` 매핑으로 단순화

### 3.4 파일 정리
- 삭제:
  - `app/javascript/controllers/master_detail_grid_controller.js`
  - `app/javascript/controllers/grid/core/grid_registration.js`
- 정리:
  - `app/javascript/controllers/grid/grid_utils.js`
    - `registerGridInstance` import/export 제거
  - `app/javascript/controllers/grid/grid_event_manager.js`
    - `resolveAgGridRegistration` 제거

## 4. 변경 파일 목록
- `app/javascript/controllers/base_grid_controller.js`
- `app/javascript/controllers/code_grid_controller.js`
- `app/javascript/controllers/client_grid_controller.js`
- `app/javascript/controllers/sell_contract_grid_controller.js`
- `app/javascript/controllers/purchase_contract_grid_controller.js`
- `app/javascript/controllers/std_corporation_grid_controller.js`
- `app/javascript/controllers/wm_pur_fee_rt_grid_controller.js`
- `app/javascript/controllers/wm_gr_prar_grid_controller.js`
- `app/javascript/controllers/zone_grid_controller.js`
- `app/javascript/controllers/role_user_grid_controller.js`
- `app/javascript/controllers/user_menu_role_grid_controller.js`
- `app/javascript/controllers/search_popup_grid_controller.js`
- `app/javascript/controllers/std_region_zip_grid_controller.js`
- `app/javascript/controllers/std_favorite_grid_controller.js`
- `app/javascript/controllers/om_pre_order_file_upload_controller.js`
- `app/javascript/controllers/grid/grid_utils.js`
- `app/javascript/controllers/grid/grid_event_manager.js`
- `app/javascript/controllers/master_detail_grid_controller.js` (삭제)
- `app/javascript/controllers/grid/core/grid_registration.js` (삭제)

## 5. 검증 결과
- 정적 참조 검증:
  - `master_detail_grid_controller` 참조 0건 확인
  - `grid/core/grid_registration` 참조 0건 확인
  - `registerGridInstance`/`resolveAgGridRegistration` 참조 0건 확인
- 문법 검증:
  - 변경된 JS 파일 전체 `node --check` 통과
- 참고:
  - `pnpm typecheck`는 저장소 루트에 `package.json`이 없어 실행 불가

## 6. 비고
- 조회 로직(`ag_grid/data_loader`)은 기존 구조가 이미 공통 함수(`loadClientGridData`, `loadServerGridPage`)로 분리되어 있어 추가 구조 변경 없이 유지했습니다.
- 이후 필요 시 `fetchJson` 경로 정리(`grid_utils` -> `core/http_client`)를 단계적으로 진행할 수 있습니다.
