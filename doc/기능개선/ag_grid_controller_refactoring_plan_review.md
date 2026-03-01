# AG Grid 리팩토링 계획 검토 및 보완안

## 1) 검토 결론 요약
- 기존 계획서(`ag_grid_controller_refactoring_plan.md`)는 **방향은 적절**합니다.
- 다만 현재 코드 기준으로는 **즉시 반영 시 누락/리스크가 있는 항목**이 있습니다.
- 따라서 아래 보완 항목을 반영한 뒤 개발을 시작하는 것이 안전합니다.

---

## 2) 요구사항 반영 점검표

| 요청 항목 | 반영도 | 검토 결과 |
|---|---|---|
| 중복 소스 통합/분리, 유지보수 단순화 | 부분 반영 | `MasterDetailGridController` 통합 방향은 적절. 다만 `ag_grid/data_loader.js` 계열 조회 공통화 계획이 구체적으로 빠짐 |
| `grid_dependent_select_utils.js`, `grid_event_manager.js`, `grid_registration.js` 필요성 검증 | 반영 | 필요성 판단은 했으나, `grid_registration.js` 삭제 전 선행 전환 범위가 실제 코드와 일부 불일치 |
| 다른 소스 필요성 검증 | 부분 반영 | 주요 파일은 점검했으나 의존도 수치와 삭제 가능 시점(즉시/후속) 구분이 더 필요 |
| AG Grid API 중심으로 마스터-디테일 자동 조회 | 반영 | `rowDataUpdated` + `cellFocused` 기반 제안은 방향 일치 |
| 초기 설정 객체 1회 세팅으로 자동 구성 | 부분 반영 | `gridRoles()` 확장 제안은 적절. 다만 기본값 자동 세팅/규약(필수/선택 키) 정의가 더 필요 |
| `master_detail_grid_controller.js` 삭제 검토 | 반영 | 삭제 목표 타당. 단, 전환 완료 전 삭제는 불가 |
| 최종 목표(BaseGrid에 기본 기능/상하위 관계/자동 연동) | 반영 | 핵심 방향 일치. “상위 그리드 없으면 master로 간주해 조회 버튼 시 자동 조회” 명세를 더 명확히 해야 함 |

---

## 3) 추가 보완이 필요한 핵심 포인트

### A. `registerGridInstance` 직접 사용 컨트롤러 수 보정 필요
- 기존 계획서에는 6개로 되어 있으나, 실제는 **7개 + MasterDetail 계열**입니다.
- 직접 사용 파일:
  - `om_pre_order_file_upload_controller.js`
  - `role_user_grid_controller.js`
  - `search_popup_grid_controller.js`
  - `std_favorite_grid_controller.js`
  - `std_region_zip_grid_controller.js`
  - `user_menu_role_grid_controller.js`
  - `zone_grid_controller.js`
- 의미: `grid_registration.js`는 이 전환이 끝나기 전까지 삭제 불가입니다.

### B. `ag_grid/data_loader.js` 중복(조회) 공통화 항목이 빠져 있음
- 실제 코드에서 `await fetchJson(...)` 패턴이 다수(컨트롤러 전역)이며, 조회 후 `rowData` 적용/오류처리 패턴이 반복됩니다.
- 기존 계획은 `grid_utils` pass-through 제거는 다루지만, **조회 흐름 통합 대상/단계**가 부족합니다.
- 보완 필요:
  - `ag_grid` 전용 로더(오버레이 포함)와 `GridCrudManager` 기반 로더(트래킹 리셋 포함)를 구분 설계
  - 공통 에러 핸들링/취소(AbortSignal) 규약 통일

### C. `grid:before-search` 처리 주체 이전 명시 필요
- 현재는 `MasterDetailGridController`가 `grid:before-search`를 수신해 마스터/디테일 clear 수행.
- 삭제 목표라면 동일 기능을 `BaseGridController`로 이전해야 합니다.
- 누락 시: 조회 버튼 클릭 전 초기화 동작이 일부 화면에서 사라질 위험이 있습니다.

### D. 이벤트 선택 기준 구체화 필요 (`cellFocused` vs `ag-grid:rowFocused`)
- 현재 `ag_grid_controller.js`는 `onCellFocused`에서 필터링(액션/체크박스 제외) 후 `ag-grid:rowFocused`를 발행합니다.
- Master-Detail 연동을 raw `cellFocused`에 바로 붙이면 불필요 트리거 가능성이 있습니다.
- 보완 권장:
  - 우선순위: `ag-grid:rowFocused` 사용
  - fallback: `cellFocused` 직접 사용 시 컬럼 필터링 로직 포함

### E. `grid_utils.js` 제거 범위는 단계 분리 필요
- `grid_utils` import 사용 파일이 광범위하여 즉시 대체는 리스크 큼.
- 보완 권장:
  - 1차: 재export(`fetchJson`, `registerGridInstance`)만 deprecate
  - 2차: 사용처를 원본 모듈로 점진 이전 후 최종 슬림화

---

## 4) 요청하신 3개 파일 필요성 재검증

### 4.1 `grid/grid_dependent_select_utils.js`
- 현재 사용처: `location_grid_controller.js` 1곳
- 판단: **즉시 필수는 아님(선택)**  
  - 단기 유지: 컨트롤러 가독성 유지 장점
  - 단기 삭제: `location_grid_controller` 내부로 인라인해 파일 수 감소 가능
- 권장: 이번 1차 리팩토링에서는 기능 변경 범위가 커서 유지, 2차에서 인라인/공통화 재판단

### 4.2 `grid/grid_event_manager.js`
- 다수 컨트롤러가 이벤트 bind/unbind 안전 해제를 위해 사용
- 판단: **필수 유지**
- 단, `resolveAgGridRegistration`은 `grid_registration` 제거 후 필요성 재평가 가능

### 4.3 `grid/core/grid_registration.js`
- 다중 컨트롤러가 직접 의존
- 판단: **현재는 필수, 최종적으로 삭제 대상**
- 삭제 조건: 위 7개 컨트롤러 + MasterDetail 계열 전환 완료

---

## 5) 보완된 실행 계획(수정안)

### Phase 0. 기준선 확보
- 화면별 현재 동작 체크리스트 작성:
  - 조회 시 마스터/디테일 clear
  - 마스터 조회 후 첫 행 자동 포커스
  - 첫 행 기준 디테일 자동 조회
  - 클릭/키보드 이동 시 디테일 재조회

### Phase 1. `BaseGridController` 확장
- `gridRoles()` 스키마 확장:
  - `parentGrid`, `detailLoader`, `onMasterRowChange`, `masterKeyField`
- `grid:before-search` 수신을 `BaseGridController`로 이전
- 마스터 행 변경 감지는 AG Grid 이벤트 중심으로 통합
  - 우선 `ag-grid:rowFocused` 활용
  - 최초 로드(`rowDataUpdated`) 시 첫 행 포커스 후 동일 경로로 디테일 로드

### Phase 2. 파일럿 전환 (`code_grid_controller.js`)
- `MasterDetailGridController` 의존 제거
- `configureManager/configureDetailManager + handleMasterRowChange`를 `gridRoles()` 중심으로 통합
- “초기 설정 1회 객체로 자동 구성” 규약 검증

### Phase 3. 나머지 Master-Detail 6개 전환
- 대상:
  - `client_grid_controller.js`
  - `purchase_contract_grid_controller.js`
  - `sell_contract_grid_controller.js`
  - `std_corporation_grid_controller.js`
  - `wm_pur_fee_rt_grid_controller.js`
  - `wm_gr_prar_grid_controller.js`

### Phase 4. `registerGridInstance` 직접 사용 컨트롤러 7개 전환
- 대상:
  - `om_pre_order_file_upload_controller.js`
  - `role_user_grid_controller.js`
  - `search_popup_grid_controller.js`
  - `std_favorite_grid_controller.js`
  - `std_region_zip_grid_controller.js`
  - `user_menu_role_grid_controller.js`
  - `zone_grid_controller.js`
- 전환 후 `resolveAgGridRegistration` 사용처 축소

### Phase 5. 조회 로직 공통화(`data_loader` 포함)
- `ag_grid` 일반 조회와 `GridCrudManager` 조회를 공통 인터페이스로 정리
- 공통 항목:
  - 에러 처리
  - stale 응답 무시
  - 로딩/오버레이 처리 규약

### Phase 6. 삭제/정리
- 삭제 후보(조건 충족 시):
  - `master_detail_grid_controller.js`
  - `grid/core/grid_registration.js`
- 축소:
  - `grid/grid_utils.js`의 pass-through, 재export 제거

---

## 6) 완료 기준(DoD)
- `master_detail_grid_controller` import 0건
- `grid/core/grid_registration` import 0건
- 마스터-디테일 화면에서 다음이 모두 만족:
  - 조회 버튼 클릭 시 마스터/디테일 초기화
  - 마스터 조회 결과 1건 이상이면 첫 행 자동 포커스
  - 첫 행 기준 디테일 자동 조회
  - 마스터 행 이동(클릭/키보드) 시 디테일 자동 재조회
- 단일 그리드 화면 기존 동작 회귀 없음

---

## 7) 결론
- 기존 계획서는 **핵심 방향은 맞습니다**.
- 위 보완 항목(A~E)만 반영하면, 요청하신 최종 목표(`BaseGridController` 중심 통합, `MasterDetailGridController` 삭제, AG Grid API 기반 자동 연동)에 맞는 실행 계획으로 사용할 수 있습니다.

---

## 8) 현재 구조 문제점 상세

### 8.1 이중 그리드 등록 메커니즘
- `BaseGridController`의 `gridRoles()` (target → role 매핑)
- `MasterDetailGridController`의 `registerGridInstance()` (grid_registration.js, 프로토타입 체인 탐색)
- 같은 문제를 다른 방식으로 해결 → 혼란

### 8.2 중복 코드 상세
| 중복 | 내용 |
|------|------|
| `grid_utils.js::fetchJson` | `http_client.js::fetchJson`의 단순 pass-through |
| `grid_utils.js::isApiAlive` | `api_guard.js::isApiAlive`의 재export |
| `grid_utils.js::registerGridInstance` | `grid_registration.js`의 재export |
| 7개 도메인 컨트롤러의 `handleMasterRowChange` | 모두 동일 패턴 (코드저장 → 라벨갱신 → clear → load) |
| 7개 도메인 컨트롤러의 `onRowDataUpdated` | 모두 `selectFirstMasterRow()` 호출 |

### 8.3 AG Grid API 미활용
- `cellFocused` 이벤트 하나로 행 클릭 + 키보드 이동을 모두 커버할 수 있는데, `rowClicked` + `cellFocused` 두 이벤트를 별도 바인딩
- `rowDataUpdated` 후 수동으로 `selectFirstMasterRow()` → `handleMasterRowChange()` 콜백 체인

---

## 9) 새로운 아키텍처 설계 — gridRoles() 목표 형태

```javascript
// 목표: BaseGridController를 직접 상속, gridRoles() 하나로 모든 설정 완료
gridRoles() {
  return {
    master: {
      target: "masterGrid",
      manager: { pkFields: ["code"], fields: {...}, defaultRow: {...}, ... },
      masterKeyField: "code"
    },
    detail: {
      target: "detailGrid",
      manager: { pkFields: ["detail_code"], ... },  // null이면 읽기전용
      parentGrid: "master",                          // ← 핵심: 상위 그리드 지정
      detailLoader: async (masterRow) => {           // 마스터 행 변경 시 데이터 로드
        return fetchJson(`/api/details?code=${masterRow.code}`)
      },
      onMasterRowChange: (rowData) => {              // 추가 사이드이펙트 (선택사항)
        this.selectedCodeValue = rowData?.code || ""
      }
    }
  }
}
```

---

## 10) 파일 유지/삭제 판단 최종 정리

### 삭제 대상
| 파일 | 이유 |
|------|------|
| `controllers/master_detail_grid_controller.js` | 기능이 BaseGridController에 통합 |
| `controllers/grid/core/grid_registration.js` | BaseGridController의 `#registerRoleGrid()`가 대체 |

### 유지 (변경 없음)
| 파일 | 이유 |
|------|------|
| `ag_grid/` 폴더 전체 | 프레젠테이션 계층, 잘 분리됨 |
| `grid/grid_crud_manager.js` | 독립적이고 잘 설계된 CRUD 상태 추적 |
| `grid/core/api_guard.js` | 순수 유틸, 원본 |
| `grid/core/http_client.js` | 순수 유틸, 원본 |
| `grid/core/search_form_bridge.js` | 순수 유틸 |
| `grid/core/resource_form_bridge.js` | 순수 유틸 |
| `grid/grid_form_utils.js` | 3개 파일에서 사용 |
| `grid/grid_dependent_select_utils.js` | 향후 재사용 가능 |
| `grid/request_tracker.js` | 독립적 유틸 |

---

## 11) 리스크 추가 항목

| 리스크 | 대응 |
|--------|------|
| `cellFocused`가 초기 로드 시 발생하지 않을 수 있음 | `selectFirstMasterRow()`에서 `setFocusedCell` 호출 후 fallback으로 `#dispatchMasterRowChange` 직접 호출 |
| 디테일 비동기 로딩 중 마스터 행 재변경 | `#masterLastKey` 비교로 stale 응답 무시. 필요 시 `AbortableRequestTracker` 적용 |
| `wm_pur_fee_rt`의 `selectFirstMasterRow` 오버라이드 | `selectFirstMasterRow()`를 public으로 유지, 오버라이드 허용 |
| 대규모 import 경로 변경 (~33개 파일) | Phase 7에서 기계적 find-and-replace로 일괄 처리 |
