# AG Grid 리팩토링 작업 결과 보고서 (2026-03-01)

## 1. 작업 기준
- 기준 문서:
  - `doc/기능개선/ag_grid_controller_refactoring_plan.md`
- 참조 문서:
  - `doc/기능개선/ag_grid_refactor_phase1_spec.md`
  - `doc/기능개선/ag_grid_controller_refactoring_execution_plan.md`

## 2. 이번 작업 범위
- Phase 1: `BaseGridController` 공통화 구현
- Phase 2(파일럿): `code_grid_controller.js` 전환

## 3. 변경 파일
- `app/javascript/controllers/base_grid_controller.js`
- `app/javascript/controllers/code_grid_controller.js`

## 4. 구현 내용

### 4.1 BaseGridController 공통화
- `gridRoles()` 확장 지원
  - `manager`, `parentGrid`, `detailLoader`, `onMasterRowChange`, `masterKeyField` 사용 가능
- 다중 그리드 등록 시 role별 `GridCrudManager` 자동 attach 지원
- 마스터-디테일 관계 자동 인식
  - `parentGrid` 기반 parent-child 매핑
- 마스터 이벤트 연동 추가
  - `ag-grid:rowFocused` 우선 사용
  - `rowDataUpdated` 시:
    - 자식 그리드 clear/resetTracking
    - 첫 행 자동 포커스(`selectFirstMasterRow`)
    - 디테일 자동 조회 dispatch
- 중복 조회 방지
  - `masterKeyField` 기반 dedupe key 추적
- 비동기 조회 역전 방지
  - master dispatch token으로 stale 응답 적용 차단
- 조회 전 초기화 공통화
  - `grid:before-search` 수신
  - 다중/단일 그리드 rowData clear + tracking reset
  - 훅 추가: `beforeSearchReset()`
- 공용 메서드 추가
  - `gridManager(name)`
  - `selectFirstRow(name, options)`
  - `selectFirstMasterRow(masterRole = "master")`

### 4.2 code_grid_controller 파일럿 전환
- 상속 변경
  - `MasterDetailGridController` -> `BaseGridController`
- 구조 변경
  - `configureManager/configureDetailManager` 중심 -> `gridRoles()` 중심
- 마스터-디테일 연동
  - `detail.parentGrid = "master"`
  - `onMasterRowChange`: 선택 코드/라벨 갱신 + 디테일 clear
  - `detailLoader`: 마스터 코드 기준 상세 조회
- 액션 메서드 유지
  - `addMasterRow`, `deleteMasterRows`, `saveMasterRows`
  - `addDetailRow`, `deleteDetailRows`, `saveDetailRows`
- 내부 참조 정리
  - `this.manager` 의존 -> `this.gridManager("master")/("detail")`로 전환
- 조회 전 라벨 초기화
  - `beforeSearchReset()` 오버라이드

## 5. 검증 결과
- 문법 검증:
  - `node --check app/javascript/controllers/base_grid_controller.js` 통과
  - `node --check app/javascript/controllers/code_grid_controller.js` 통과
- `pnpm typecheck`는 실행 불가
  - 사유: 저장소 루트에 `package.json` 없음

## 6. 미완료(다음 단계)
- Phase 3: Master-Detail 나머지 6개 컨트롤러 전환
  - `std_corporation_grid_controller.js`
  - `wm_pur_fee_rt_grid_controller.js`
  - `client_grid_controller.js`
  - `sell_contract_grid_controller.js`
  - `purchase_contract_grid_controller.js`
  - `wm_gr_prar_grid_controller.js`
- Phase 4: `registerGridInstance` 직접 사용 7개 컨트롤러 전환
- Phase 5: `ag_grid/data_loader.js` 포함 조회 로직 공통화
- Phase 6~7: `grid_utils` 슬림화 및 `master_detail/grid_registration` 제거

## 7. 참고
- 이번 변경은 기존 화면 호환성을 우선하여 공통 베이스 + 파일럿만 반영했습니다.
- 후속 Phase는 화면 단위 회귀 테스트를 병행하면서 순차 적용이 필요합니다.
