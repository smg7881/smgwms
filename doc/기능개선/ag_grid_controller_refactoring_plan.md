# AG Grid 컨트롤러 구조 리팩토링 계획서 (보완 반영본)

## 1. Context

현재 WMS 프로젝트 AG Grid JavaScript 컨트롤러 구조는 다음 이유로 유지보수가 어렵습니다.
- 3단계 상속 구조: `BaseGridController` → `MasterDetailGridController` → 도메인 컨트롤러
- 다중 그리드 등록 방식 이원화: `gridRoles` vs `registerGridInstance`
- 중복 래핑/재export: `grid_utils.js`의 `fetchJson`, `registerGridInstance`
- 마스터-디테일 수동 체인: `onRowDataUpdated -> selectFirstMasterRow -> handleMasterRowChange`

**핵심 목표**
- `MasterDetailGridController`를 제거하고 `BaseGridController`에 마스터-디테일 공통 기능 통합
- `gridRoles()` 1회 설정으로 그리드 관계/CRUD/연동 자동화
- AG Grid 이벤트/API 중심으로 첫 행 자동 포커스 + 디테일 자동 조회

---

## 2. 현재 구조 문제점

### 2.1 등록 메커니즘 이중화
- `BaseGridController`: `gridRoles()` 기반 role-target 매핑
- `MasterDetailGridController`: `registerGridInstance()` 기반 별도 등록 체계
- 동일 목적을 서로 다른 방식으로 해결해 코드 복잡도 증가

### 2.2 중복 코드
- `grid_utils.js::fetchJson` -> `http_client.js::fetchJson` 단순 pass-through
- `grid_utils.js::isApiAlive` -> `api_guard.js` 재export
- `grid_utils.js::registerGridInstance` -> `grid_registration.js` 재export
- 여러 도메인 컨트롤러에 동일한 마스터 변경/디테일 로드 패턴 중복

### 2.3 AG Grid 이벤트 활용 일관성 부족
- 일부 화면은 `rowClicked + cellFocused` 병행 바인딩
- 초기 로드/행 이동/디테일 조회 흐름이 화면마다 다르게 구현됨

---

## 3. 목표 아키텍처

### 3.1 `gridRoles()` 확장 스키마

```javascript
gridRoles() {
  return {
    master: {
      target: "masterGrid",
      manager: { pkFields: ["code"], fields: { ... }, defaultRow: { ... } },
      masterKeyField: "code"
    },
    detail: {
      target: "detailGrid",
      manager: { pkFields: ["detail_code"], fields: { ... } }, // 읽기전용이면 null 가능
      parentGrid: "master",
      detailLoader: async (masterRow) => fetchJson(`/api/details?code=${masterRow.code}`),
      onMasterRowChange: (rowData) => {
        this.selectedCodeValue = rowData?.code || ""
      }
    }
  }
}
```

### 3.2 이벤트 연동 기준
- 우선순위: `ag-grid:rowFocused` 사용 (클릭/키보드 이동 공통, 액션/체크박스 제외 필터와 정합)
- fallback: 필요 시 `cellFocused` 직접 처리
- `rowDataUpdated` 시 첫 행 포커스 후 동일 연동 경로로 디테일 조회

### 3.3 조회 버튼 연동
- `grid:before-search` 처리 책임을 `BaseGridController`로 이전
- 조회 직전 마스터/디테일 rowData 및 추적 상태(clear/resetTracking) 공통 초기화

---

## 4. 파일 정리 계획 (필요성 재검증 반영)

### 4.1 최종 삭제 대상 (전제 조건 충족 시)
| 파일 | 조건 |
|------|------|
| `controllers/master_detail_grid_controller.js` | Master-Detail 컨트롤러 전환 완료 후 |
| `controllers/grid/core/grid_registration.js` | 직접 사용 컨트롤러 전환 완료 후 |

### 4.2 유지 대상
| 파일 | 판단 |
|------|------|
| `controllers/grid/grid_event_manager.js` | 유지 필요 (이벤트 bind/unbind 공통). 단, `resolveAgGridRegistration`은 후속 축소 가능 |
| `controllers/grid/grid_dependent_select_utils.js` | 현재 1곳(`location_grid_controller`) 사용. 1차는 유지, 2차에 인라인 여부 재판단 |
| `controllers/ag_grid/*` | 프레젠테이션 계층 유지 |
| `controllers/grid/grid_crud_manager.js` | CRUD 추적 핵심 모듈 유지 |

### 4.3 `grid_utils.js` 정리 원칙
- 1차: `fetchJson`, `registerGridInstance` 재export/패스스루 사용을 deprecated 처리
- 2차: 사용처를 원본 모듈로 이전 후 최종 슬림화

---

## 5. 마이그레이션 대상

### 5.1 Master-Detail 계열 7개
- `code_grid_controller.js`
- `std_corporation_grid_controller.js`
- `wm_pur_fee_rt_grid_controller.js`
- `client_grid_controller.js`
- `sell_contract_grid_controller.js`
- `purchase_contract_grid_controller.js`
- `wm_gr_prar_grid_controller.js`

### 5.2 `registerGridInstance` 직접 사용 컨트롤러 7개
- `om_pre_order_file_upload_controller.js`
- `role_user_grid_controller.js`
- `search_popup_grid_controller.js`
- `std_favorite_grid_controller.js`
- `std_region_zip_grid_controller.js`
- `user_menu_role_grid_controller.js`
- `zone_grid_controller.js`

---

## 6. 단계별 구현 순서

### Phase 0. 기준선 확보
- 화면별 체크리스트 작성
  - 조회 전 clear
  - 첫 행 자동 포커스
  - 첫 행 기준 디테일 자동 조회
  - 행 이동 시 디테일 재조회

### Phase 1. BaseGridController 마스터-디테일 통합
**파일**: `app/javascript/controllers/base_grid_controller.js`
1. `gridRoles()` 스키마 확장 (`parentGrid`, `detailLoader`, `onMasterRowChange`, `masterKeyField`)
2. role 등록 시 manager 자동 attach 지원
3. parent-child role 관계 자동 매핑
4. 이벤트 바인딩 통합 (`ag-grid:rowFocused` 우선)
5. `rowDataUpdated` 시 디테일 resetTracking + 첫 행 자동 포커스/연동
6. `grid:before-search` 수신/공통 clear 처리
7. `selectFirstMasterRow()` 공용 메서드 제공

### Phase 2. 파일럿 전환
**파일**: `app/javascript/controllers/code_grid_controller.js`
- `MasterDetailGridController` 의존 제거
- `gridRoles()` 기반으로 마스터-디테일 구성 전환
- 설정 객체 1회 구성으로 동작 완결 검증

### Phase 3. Master-Detail 나머지 6개 전환
- `std_corporation_grid_controller.js`
- `wm_pur_fee_rt_grid_controller.js`
- `client_grid_controller.js`
- `sell_contract_grid_controller.js`
- `purchase_contract_grid_controller.js`
- `wm_gr_prar_grid_controller.js`

### Phase 4. `registerGridInstance` 직접 사용 7개 전환
- `om_pre_order_file_upload_controller.js`
- `role_user_grid_controller.js`
- `search_popup_grid_controller.js`
- `std_favorite_grid_controller.js`
- `std_region_zip_grid_controller.js`
- `user_menu_role_grid_controller.js`
- `zone_grid_controller.js`

### Phase 5. 조회 로직 공통화 (`data_loader` 포함)
- `ag_grid/data_loader.js` 중심으로 조회 로직 정리
- 공통 규약
  - 성공/실패 처리 일관화
  - stale 응답 무시
  - 필요 시 AbortSignal 적용
  - 오버레이/로딩 상태 일관화

### Phase 6. `grid_utils.js` 단계적 슬림화
- 재export 경로 의존 제거
- import 경로 원본 모듈로 이동

### Phase 7. 삭제/정리
1. `master_detail_grid_controller.js` 삭제
2. `grid/core/grid_registration.js` 삭제
3. `grid/grid_event_manager.js`의 `resolveAgGridRegistration` 정리(참조 0건 후)
4. 잔여 import 정리

---

## 7. 검증 방법

1. 기능 검증
- 마스터 조회 -> 첫 행 자동 포커스 -> 디테일 자동 조회
- 마스터 행 이동(클릭/키보드) -> 디테일 재조회
- 행 추가/삭제/저장 정상 동작
- 조회 버튼 클릭 시 초기화 후 재조회

2. 회귀 검증
- 단일 그리드 컨트롤러 영향 없음 확인
- 기존 다중 그리드(읽기 전용 포함) 영향 없음 확인

3. 품질 검증
- `bin/rails test:system`
- JavaScript 콘솔 에러/경고 확인
- 필요 시 `bin/rubocop` 병행

---

## 8. 리스크 및 대응

| 리스크 | 대응 |
|--------|------|
| 초기 로드에서 포커스 이벤트 누락 가능 | `selectFirstMasterRow()`에서 fallback dispatch 보완 |
| 비동기 디테일 조회 중 마스터 재변경 | `masterKeyField` 기준 stale 응답 무시 |
| 대규모 import 교체 누락 | Phase 단위로 `rg` 참조 건수 점검 |
| 공통 베이스 변경으로 회귀 발생 | 파일럿(`code_grid`) 선반영 후 단계 확장 |

---

## 9. 완료 기준 (DoD)
- `controllers/master_detail_grid_controller` import 0건
- `controllers/grid/core/grid_registration` import 0건
- 마스터-디테일 자동 연동 요구사항 충족
  - 조회 후 첫 행 자동 포커스
  - 첫 행 기준 디테일 자동 조회
  - 행 이동 시 디테일 자동 재조회
- 단일 그리드 화면 회귀 없음
