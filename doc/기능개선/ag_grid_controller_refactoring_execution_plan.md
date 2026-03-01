# AG Grid 리팩토링 상세 실행계획서 (파일별 작업 단위)

## 1. 목적
- `BaseGridController` 중심으로 마스터-디테일 공통화
- `MasterDetailGridController` 제거
- `grid_registration` 의존 제거
- AG Grid 이벤트/API를 활용한 자동 연동(첫 행 자동 포커스, 디테일 자동 조회)

---

## 2. 범위와 원칙
- 1차 목표: 동작 보존 + 구조 단순화
- 2차 목표: 조회 로직 공통화(`data_loader` 계열 정리)
- 원칙:
  - 삭제는 “참조 0건” 확인 후 진행
  - 대규모 import 교체는 단계적 진행
  - 화면 단위 검증 후 다음 Phase 진행

---

## 3. Phase별 상세 계획

## Phase 0. 기준선 확보
### 작업 파일
- `doc/기능개선/ag_grid_refactor_checklist.md` (신규)

### 작업 내용
- 화면별 현행 동작 체크리스트 작성
  - 조회 전 마스터/디테일 clear
  - 마스터 조회 후 첫 행 자동 선택/포커스
  - 첫 행 기준 디테일 자동 조회
  - 클릭/키보드 이동 시 디테일 재조회

### 영향도
- 코드 영향 없음(문서만)

---

## Phase 1. BaseGridController 확장 (핵심)
### 작업 파일
- `app/javascript/controllers/base_grid_controller.js`
- 필요 시: `app/javascript/controllers/ag_grid_controller.js` (이벤트 연동 확인)

### 작업 내용
- `gridRoles()` 스키마 확장
  - `parentGrid`, `detailLoader`, `onMasterRowChange`, `masterKeyField`, `autoLoadOnReady`
- 다중 그리드 등록 시 role 메타 저장 확장
- `grid:before-search` 수신/처리 로직을 Base로 이동
  - 마스터/디테일 데이터 clear 공통 처리
- 마스터 포커스 이벤트 처리 공통화
  - 우선 `ag-grid:rowFocused` 경로 사용
  - 중복 요청 방지 키(`masterKeyField`) 비교
- `rowDataUpdated` 시 자동 첫 행 포커스 + 디테일 조회 트리거

### 영향도
- 매우 높음(공통 베이스)
- 영향 범위: `BaseGridController` 상속 화면 전체

### 검증
- 단일 그리드 화면 3개 샘플 회귀
- 마스터-디테일 파일럿 화면 1개 선검증

---

## Phase 2. 파일럿 전환 (`code_grid_controller.js`)
### 작업 파일
- `app/javascript/controllers/code_grid_controller.js`

### 작업 내용
- 상속 변경: `MasterDetailGridController` -> `BaseGridController`
- `configureManager`/`configureDetailManager` 중심 구조를 `gridRoles()` 중심으로 이관
- 마스터 변경 처리(`handleMasterRowChange`)를
  - `detailLoader`
  - `onMasterRowChange`
  로 분리
- 초기 설정 객체 1회 구성으로 동작하도록 정리

### 영향도
- 중간(단일 도메인)
- 성공 시 이후 전환 패턴 확정 가능

### 검증
- 코드 조회 -> 첫 행 자동 포커스 -> 상세 자동 조회
- 마스터 행 이동 시 상세 재조회
- 마스터/상세 CRUD 저장 정상

---

## Phase 3. MasterDetail 계열 6개 전환
### 작업 파일
- `app/javascript/controllers/client_grid_controller.js`
- `app/javascript/controllers/purchase_contract_grid_controller.js`
- `app/javascript/controllers/sell_contract_grid_controller.js`
- `app/javascript/controllers/std_corporation_grid_controller.js`
- `app/javascript/controllers/wm_pur_fee_rt_grid_controller.js`
- `app/javascript/controllers/wm_gr_prar_grid_controller.js`

### 작업 내용
- 공통 패턴으로 `gridRoles()` 이관
- 중복된 `handleMasterRowChange`, `onRowDataUpdated` 수동 체인 제거
- 화면별 특이사항만 `onMasterRowChange`에 최소화

### 영향도
- 높음(핵심 업무 화면)

### 검증
- 화면별 조회/행추가/삭제/저장 회귀
- 키보드 이동 시 상세 연동 확인

---

## Phase 4. `registerGridInstance` 직접 사용 7개 전환
### 작업 파일
- `app/javascript/controllers/om_pre_order_file_upload_controller.js`
- `app/javascript/controllers/role_user_grid_controller.js`
- `app/javascript/controllers/search_popup_grid_controller.js`
- `app/javascript/controllers/std_favorite_grid_controller.js`
- `app/javascript/controllers/std_region_zip_grid_controller.js`
- `app/javascript/controllers/user_menu_role_grid_controller.js`
- `app/javascript/controllers/zone_grid_controller.js`

### 작업 내용
- `registerGrid(event)`를 Base 패턴 또는 직접 API 캡처 패턴으로 단순화
- `resolveAgGridRegistration` 의존 제거 방향으로 순차 정리
- 이벤트 바인딩은 `GridEventManager` 유지 사용

### 영향도
- 중간~높음(다중 그리드 화면 다수)

### 검증
- 각 화면 그리드 등록 완료 시점 동작 확인
- 수동 API 할당 fallback 제거 후 정상 동작 확인

---

## Phase 5. 조회 로직 공통화 (`data_loader` 포함)
### 작업 파일
- `app/javascript/controllers/ag_grid/data_loader.js`
- `app/javascript/controllers/grid/grid_utils.js`
- 필요 시 신규: `app/javascript/controllers/grid/core/grid_data_loader.js`

### 작업 내용
- 조회 패턴 공통화
  - 성공 시 rowData 반영
  - 실패 시 공통 에러 처리
  - stale 응답 무시 규약
  - AbortSignal 지원 통일
- `grid_utils.fetchJson` pass-through 축소/정리

### 영향도
- 높음(조회 동작 전반)

### 검증
- 검색 반복 클릭/빠른 전환 시 데이터 역전(stale) 미발생
- 에러 오버레이/알림 일관성 확인

---

## Phase 6. 삭제 및 정리
### 삭제 대상(조건 충족 시)
- `app/javascript/controllers/master_detail_grid_controller.js`
- `app/javascript/controllers/grid/core/grid_registration.js`

### 축소 대상
- `app/javascript/controllers/grid/grid_utils.js`
  - 재export 제거
  - 순수 유틸만 유지

### 영향도
- 중간(참조 정리 단계)

### 사전 조건
- `rg` 기준 import 0건 확인
  - `controllers/master_detail_grid_controller`
  - `controllers/grid/core/grid_registration`

---

## 4. 파일별 영향도 매트릭스

| 파일 | 영향도 | 이유 |
|---|---|---|
| `base_grid_controller.js` | 매우 높음 | 공통 베이스, 대부분 화면 영향 |
| `ag_grid_controller.js` | 높음 | 포커스/이벤트 발행의 기준점 |
| `code_grid_controller.js` | 중간 | 파일럿 전환 기준 화면 |
| `client/sell/purchase/std_corporation/wm_*` | 높음 | 업무 핵심 마스터-디테일 |
| `zone/role_user/user_menu_role/std_region_zip/search_popup/std_favorite/om_pre_order_file_upload` | 중간 | 등록 메커니즘 전환 핵심 |
| `grid_utils.js` | 높음 | 사용처 광범위 |
| `grid_event_manager.js` | 중간 | 이벤트 바인딩 공통 |
| `grid_registration.js` | 높음 | 제거 타깃, 참조 정리 필요 |
| `grid_dependent_select_utils.js` | 낮음 | 현재 1개 화면 전용 |

---

## 5. 완료 기준 (DoD)
- 구조 기준
  - `MasterDetailGridController` 참조 0건
  - `registerGridInstance` 참조 0건
- 기능 기준
  - 마스터 조회 결과 1건 이상 시 첫 행 자동 포커스
  - 첫 행 기준 디테일 자동 조회
  - 마스터 행 이동(클릭/키보드) 시 디테일 자동 재조회
  - 조회 버튼 시 마스터/디테일 초기화 후 재조회
- 품질 기준
  - 주요 화면 수동 회귀 완료
  - JavaScript 오류/콘솔 에러 없음

---

## 6. 권장 작업 순서 (실행 우선순위)
1. Phase 1 (`BaseGridController`)  
2. Phase 2 (`code_grid_controller` 파일럿)  
3. Phase 3 (MasterDetail 6개 확장)  
4. Phase 4 (`registerGridInstance` 7개 전환)  
5. Phase 5 (조회 공통화)  
6. Phase 6 (삭제/정리)

---

## 7. 리스크와 대응
- 리스크: 공통 베이스 수정으로 광범위 회귀 가능
  - 대응: Phase별 샘플 화면 회귀 후 확장
- 리스크: 이벤트 중복 바인딩으로 상세 중복 조회
  - 대응: `GridEventManager.unbindAll()` + 키 중복 방지 로직
- 리스크: 대규모 import 교체 중 누락
  - 대응: Phase 종료마다 `rg`로 참조 건수 점검
- 리스크: `cellFocused`가 초기 로드 시 발생하지 않을 수 있음
  - 대응: `selectFirstMasterRow()`에서 `setFocusedCell` 호출 후 fallback으로 `#dispatchMasterRowChange` 직접 호출
- 리스크: 디테일 비동기 로딩 중 마스터 행 재변경
  - 대응: `#masterLastKey` 비교로 stale 응답 무시. 필요 시 `AbortableRequestTracker` 적용
- 리스크: `wm_pur_fee_rt`의 `selectFirstMasterRow` 오버라이드
  - 대응: `selectFirstMasterRow()`를 public으로 유지, 오버라이드 허용

---

## 8. AG Grid 이벤트 기반 자동 연동 흐름 (상세)

```
[마스터 데이터 로드] → AG Grid rowDataUpdated
  → BaseGridController: 모든 디테일 manager.resetTracking()
  → BaseGridController: api.setFocusedCell(0, firstCol) → 첫 행 포커스
    → AG Grid cellFocused 이벤트 발생
      → BaseGridController #onMasterCellFocused()
        → masterKeyField로 중복 조회 방지 (이전 키와 동일하면 skip)
        → 각 디테일 role: onMasterRowChange?.(rowData) + detailLoader(rowData)

[사용자 마스터 행 클릭/키보드 이동] → AG Grid cellFocused
  → 동일한 #onMasterCellFocused() 로직 실행
```

**rowClicked 이벤트는 더 이상 바인딩하지 않음** — `cellFocused`가 클릭과 키보드를 모두 커버

---

## 9. 마이그레이션 유형별 분류

### 유형 A: 단순 1:1 마스터-디테일
| 컨트롤러 | 구조 |
|----------|------|
| `code_grid_controller.js` | 그룹코드 + 상세코드 |
| `std_corporation_grid_controller.js` | 법인 + 국가 |
| `wm_pur_fee_rt_grid_controller.js` | 매입요율 + 상세 |

### 유형 B: 마스터 + 다중 디테일 (CRUD + 읽기전용)
| 컨트롤러 | 구조 |
|----------|------|
| `client_grid_controller.js` | 거래처 + (담당자 + 작업장) |
| `sell_contract_grid_controller.js` | 매출계약 + (정산 + 이력) |
| `purchase_contract_grid_controller.js` | 매입계약 + (정산 + 이력) |

### 유형 C: 마스터 + 읽기전용 디테일 (탭 기반)
| 컨트롤러 | 구조 |
|----------|------|
| `wm_gr_prar_grid_controller.js` | 입고예정 + (입고상세 + 실행이력) |

---

## 10. 단일 그리드 / 기존 gridRoles 호환성

### 단일 그리드 모드 (기존 ~30개 컨트롤러)
`gridRoles()`가 null 반환 → 기존과 100% 동일하게 동작. **변경 불필요**

### 기존 gridRoles 다중 그리드 (OM 모듈 ~6개)
`parentGrid` 없는 role → 기존처럼 읽기전용 다중 그리드. **변경 불필요**

---

## 11. 파일 유지/삭제 판단 상세

### 유지 (변경 없음)
| 파일 | 이유 |
|------|------|
| `ag_grid/` 폴더 전체 | 프레젠테이션 계층, 잘 분리됨 |
| `grid/grid_crud_manager.js` | 독립적이고 잘 설계된 CRUD 상태 추적 |
| `grid/core/api_guard.js` | 순수 유틸, 원본 |
| `grid/core/http_client.js` | 순수 유틸, 원본 |
| `grid/core/search_form_bridge.js` | 순수 유틸 |
| `grid/core/resource_form_bridge.js` | 순수 유틸 |
| `grid/grid_form_utils.js` | 3개 파일에서 사용 (client, sell/purchase_contract) |
| `grid/grid_dependent_select_utils.js` | 1곳 사용이지만 WMS 특성상 향후 재사용 가능 |
| `grid/request_tracker.js` | 1곳 사용이지만 독립적 유틸 |
