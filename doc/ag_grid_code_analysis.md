# AG Grid 관련 JavaScript 코드 중복 분석 보고서

> 분석 대상 경로:
> - `app/javascript/controllers/grid/` (전체 — `ag_grid/` 폴더 통합 완료)
> - `app/javascript/controllers/ag_grid_controller.js`
> - `app/javascript/controllers/base_grid_controller.js`
> - `app/javascript/controllers/grid_actions_controller.js`
> - `app/javascript/controllers/lookup_popup_modal.js`
>
> **최종 업데이트:** 모든 계획 작업 완료

---

## 1. 현재 파일 역할 현황 (최종)

### `grid/core/` — 순수 기능 레이어

| 파일 | 역할 |
|------|------|
| `core/api_guard.js` | `isApiAlive` 원본 정의 |
| `core/http_client.js` | `getCsrfToken`, `requestJson`, `fetchJson` 원본 |
| `core/search_form_bridge.js` | 검색폼 bridge |
| `core/resource_form_bridge.js` | 리소스폼 bridge |

### `grid/ag_grid/` — AG Grid 라이브러리 어댑터 레이어 (구 `ag_grid/` 폴더)

| 파일 | 역할 |
|------|------|
| `ag_grid/grid_defaults.js` | 테마, Locale, 포매터, 모듈 등록 |
| `ag_grid/column_builder.js` | 컬럼 정의 빌더 |
| `ag_grid/data_loader.js` | 클라이언트/서버사이드 데이터 로딩 |
| `ag_grid/renderers.js` | 렌더러 레지스트리 통합 |
| `ag_grid/renderers/common.js` | 공통 렌더러 구현 |
| `ag_grid/renderers/actions.js` | 액션 버튼 렌더러 구현 |
| `ag_grid/clipboard_utils.js` | 셀 단위 클립보드(Ctrl+C/V) 유틸 (**신규 분리**) |
| `ag_grid/column_state_utils.js` | 컬럼 상태 저장/복원 localStorage 유틸 (**신규 분리**) |

### `grid/` — 애플리케이션 그리드 추상화 레이어

| 파일 | 역할 |
|------|------|
| `grid_utils.js` | `postJson`, `buildTemplateUrl`, `uuid` 등 핵심 유틸 + 하위호환 re-export |
| `grid_api_utils.js` | `setGridRowData`, `collectRows`, `focusFirstRow` 등 AG Grid API 조작 (**신규 분리**) |
| `grid_state_utils.js` | `hasChanges`, `requireSelection`, `blockIfPendingChanges` 등 (**신규 분리**) |
| `grid_select_utils.js` | `setSelectOptions`, `clearSelectOptions` (**신규 분리**) |
| `grid_crud_manager.js` | CRUD 상태 추적 클래스 |
| `grid_event_manager.js` | AG Grid API 이벤트 바인딩/해제 관리 (`GridEventManager` 클래스) |
| `grid_form_utils.js` | 마스터-디테일 폼 동기화 유틸 |
| `grid_popup_utils.js` | search-popup DOM 조작 유틸 |
| `grid_dependent_select_utils.js` | 계층형 SELECT 연동 유틸 |
| `request_tracker.js` | AbortController 기반 중복 요청 방지 래퍼 |

### Stimulus 컨트롤러

| 파일 | 역할 |
|------|------|
| `ag_grid_controller.js` | AG Grid 메인 Stimulus 컨트롤러 |
| `base_grid_controller.js` | CRUD 공통 Stimulus 베이스 컨트롤러 |
| `grid_actions_controller.js` | 그리드 툴바 버튼 위임 컨트롤러 |
| `lookup_popup_modal.js` | 팝업 열기 래퍼 |

---

## 2. 중복/문제 목록 및 처리 현황

### [중복-01] `fetchJson` 3중 정의 ✅ 해결

**문제:** `http_client.js`(원본) → `grid_utils.js`(별칭 재선언) 2단계 체인.

**해결:** `grid_utils.js`의 `fetchJson` 직접 선언 제거, `export { fetchJson } from "core/http_client"`로 전환.
30개+ 비즈니스 컨트롤러의 import 경로를 `core/http_client`로 직접 마이그레이션 완료.

---

### [중복-02] `isApiAlive` 경로 혼재 ✅ 해결

**문제:** 같은 함수를 일부는 원본(`core/api_guard`)에서, 일부는 `grid_utils` 경유로 import.

**해결:** 모든 내부 파일(`grid_crud_manager`, `grid_form_utils`, `base_grid_controller` 등)이
`core/api_guard`에서 직접 import하도록 통일.

---

### [중복-03] `requestJson` / `postJson` 혼재 ✅ 해결

**문제:** POST 요청 처리 방식이 `postAction`, `saveRowsWith`, `postJson` 3가지로 분산.

**해결:** `postJson`에 `{ onError }` 옵션 추가, 에러 처리를 외부 위임 가능하도록 개선.
`base_grid_controller`는 `postAction`(커스텀 단건 액션)과 `saveRowsWith`(일괄저장)으로 역할 명확화.

---

### [중복-04] `getCsrfToken` 불필요 re-export ✅ 해결

**문제:** `grid_utils.js`가 `getCsrfToken`을 공개 API처럼 re-export.

**해결:** 비즈니스 컨트롤러 import 경로를 `core/http_client`로 직접 변경 완료.
`grid_utils.js`의 하위호환 re-export는 유지(기존 코드 방어용).

---

### [중복-05] Validation 에러 포맷 함수 중복 ✅ 해결

**문제:** `base_grid_controller.js::` `#formatValidationLine`과 `grid_crud_manager.js::` `#formatSingleValidationError`가 거의 동일한 로직 중복.

**해결:** `grid_utils.js`에 공개 함수 `formatValidationError(error)` 추출.
양쪽 private 메서드 삭제 후 공유 함수로 위임.

---

### [중복-06] `#showToast` 독자 구현 ✅ 해결

**문제:** `ag_grid_controller.js`에 `components/ui/alert.js::showAlert`와 별개의 Toast DOM 직접 생성 구현.

**해결:** `#showToast` 메서드 삭제. 모든 호출부를 `showAlert(msg, null, type)` 형태로 교체.
(`success` / `info` / `warning` 타입 적절히 적용)

---

### [중복-07] `grid_utils.js` 책임 과부하 ✅ 해결

**문제:** HTTP re-export, AG Grid 조작, 상태 체크, SELECT DOM 조작 등 4가지 역할 혼재.

**해결:** 3개 파일로 분리 완료.

| 분리된 파일 | 이전된 함수 |
|------------|------------|
| `grid_api_utils.js` | `setGridRowData`, `setManagerRowData`, `collectRows`, `refreshStatusCells`, `hideNoRowsOverlay`, `focusFirstRow` |
| `grid_state_utils.js` | `hasChanges`, `hasPendingChanges`, `blockIfPendingChanges`, `requireSelection`, `isLoadableMasterRow` |
| `grid_select_utils.js` | `setSelectOptions`, `clearSelectOptions` |

`grid_utils.js`는 직접 구현 함수(`postJson`, `buildTemplateUrl`, `uuid`, `numberOrNull`,
`refreshSelectionLabel`, `resolveNameFromMap`, `buildCompositeKey`, `formatValidationError`)
+ 하위호환 re-export 허브로 슬림화.

30개+ 비즈니스 컨트롤러의 import 경로 직접 마이그레이션 완료.

---

### [중복-08] POST 에러 처리 이원화 ✅ 해결 (중복-03과 동일)

---

## 3. 현재 import 의존 관계도 (최종)

```
[core/ 레이어] — 순수 기능, 외부 의존 없음
  core/api_guard.js      → isApiAlive
  core/http_client.js    → getCsrfToken, requestJson, fetchJson

         ↓ (직접 import만 — grid_utils 경유 없음)

[ag_grid/ 레이어] — AG Grid 어댑터
  ag_grid/data_loader.js      → core/http_client, core/api_guard 직접
  ag_grid/clipboard_utils.js  → core/api_guard 직접
  ag_grid/column_state_utils.js → core/api_guard 직접

[grid/ 레이어] — 애플리케이션 추상화
  grid_api_utils.js     → core/api_guard 직접
  grid_state_utils.js   → components/ui/alert 직접
  grid_select_utils.js  → 외부 의존 없음 (순수 DOM)
  grid_crud_manager.js  → core/api_guard 직접, grid_api_utils 직접, grid_utils 직접
  grid_utils.js         → core/http_client(re-export), core/api_guard(re-export),
                           grid_api_utils(re-export), grid_state_utils(re-export),
                           grid_select_utils(re-export) + 직접 구현

[Stimulus 컨트롤러 레이어]
  ag_grid_controller.js   → grid/ag_grid/* 직접, core/api_guard 직접
  base_grid_controller.js → core/api_guard 직접, core/http_client 직접,
                             grid_api_utils 직접, grid_state_utils 직접, grid_utils 직접
  비즈니스 컨트롤러       → 각 원본 파일에서 직접 import
```

---

## 4. 폴더 구조 (최종)

```
controllers/
├── grid/
│   ├── core/
│   │   ├── api_guard.js
│   │   ├── http_client.js
│   │   ├── search_form_bridge.js
│   │   └── resource_form_bridge.js
│   │
│   ├── ag_grid/                     ← 구 controllers/ag_grid/ 통합 완료
│   │   ├── grid_defaults.js
│   │   ├── column_builder.js
│   │   ├── data_loader.js
│   │   ├── renderers.js
│   │   ├── clipboard_utils.js       ← 신규 분리
│   │   ├── column_state_utils.js    ← 신규 분리
│   │   └── renderers/
│   │       ├── common.js
│   │       └── actions.js
│   │
│   ├── grid_utils.js                ← 슬림화 완료 (re-export 허브 + 직접 구현)
│   ├── grid_api_utils.js            ← 신규 분리
│   ├── grid_state_utils.js          ← 신규 분리
│   ├── grid_select_utils.js         ← 신규 분리
│   ├── grid_crud_manager.js
│   ├── grid_event_manager.js
│   ├── grid_form_utils.js
│   ├── grid_popup_utils.js
│   ├── grid_dependent_select_utils.js
│   └── request_tracker.js
│
├── ag_grid_controller.js            ← 대폭 슬림화 완료
├── base_grid_controller.js
├── grid_actions_controller.js
├── lookup_popup_modal.js
└── ...비즈니스 컨트롤러
```

---

## 5. `ag_grid_controller.js` 개선 이력

초기 분석에서 추가로 발견된 문제들을 처리.

### [A] 데드코드 `ensureStatusColumnOrder()` 삭제 ✅

`ensureSystemColumnOrder()`로 대체된 이후 삭제되지 않은 29줄 잔류 코드 제거.

### [B] 클립보드 로직 분리 ✅

`ag_grid_controller.js` 내 9개 클립보드 메서드(~110줄)를 `grid/ag_grid/clipboard_utils.js`로 추출.

| 분리된 함수 | 설명 |
|------------|------|
| `isGridCopyShortcut` | Ctrl+C 단축키 판별 |
| `isGridPasteShortcut` | Ctrl+V 단축키 판별 |
| `isNativeInputTarget` | 네이티브 입력 요소 포커스 여부 판별 |
| `copyCurrentCellValue` | 셀 값 → 클립보드 복사 |
| `pasteCurrentCellValue` | 클립보드 → 셀 붙여넣기 |
| `canPasteToCell` | 붙여넣기 가능 여부 판별 |
| `writeTextToClipboard` | 시스템 클립보드 쓰기 |
| `readTextFromClipboard` | 시스템 클립보드 읽기 (인메모리 폴백 포함) |

컨트롤러는 `#localClipboard()` 접근자 객체를 통해 `#localClipboardText` 상태를 위임.

### [C] 컬럼 상태 저장/복원 분리 ✅

4개 메서드(~40줄)를 `grid/ag_grid/column_state_utils.js`로 추출.

| 분리된 함수 | 설명 |
|------------|------|
| `saveColumnState(gridApi, gridId)` | localStorage에 컬럼 상태 저장 |
| `resetColumnState(gridApi, gridId)` | 저장 삭제 + 기본값 복원 |
| `restoreColumnState(gridApi, gridId, onRestored)` | localStorage에서 상태 복원 |
| `columnStateStorageKey(gridId)` | 스토리지 키 생성 |

### 결과: `ag_grid_controller.js` 규모 변화

| 항목 | 변경 전 | 변경 후 |
|------|--------|--------|
| 총 줄 수 | 833줄 | ~580줄 |
| 외부 의존 파일 | 5개 | 8개 (책임 위임) |
| 직접 구현 private 메서드 | 15개 | 4개 |

---

## 6. 잔여 개선 포인트

### `GridEventManager` 활용 (선택적)

`grid_event_manager.js`의 `GridEventManager` 클래스(`api.addEventListener` 래퍼)가
현재 어느 파일에서도 사용되지 않음.

- `ag_grid_controller.js`는 DOM 이벤트(2쌍)를 수동으로 bind/unbind
- `GridEventManager`는 AG Grid API 이벤트 전용으로 설계되어 DOM 이벤트에 직접 적용 불가
- **현상 유지 권장** — 수동 2쌍은 명확하며 추상화 효과 미미

---

## 7. 전체 작업 완료 요약

| 작업 | 상태 |
|------|------|
| Phase 1: import 경로 통일 (`core/` 직접 import) | ✅ 완료 |
| Phase 2: `ag_grid/` → `grid/ag_grid/` 폴더 통합 | ✅ 완료 |
| Phase 3: `#showToast` 제거 → `showAlert` 통합 | ✅ 완료 |
| `postJson` 에러 처리 옵션화 (`onError`) | ✅ 완료 |
| `formatValidationError` 공통 함수 추출 | ✅ 완료 |
| `grid_utils.js` 분리 (`grid_api_utils`, `grid_state_utils`, `grid_select_utils`) | ✅ 완료 |
| 30개+ 비즈니스 컨트롤러 import 직접 마이그레이션 | ✅ 완료 |
| `ensureStatusColumnOrder()` 데드코드 삭제 | ✅ 완료 |
| 클립보드 로직 → `clipboard_utils.js` 분리 | ✅ 완료 |
| 컬럼 상태 저장/복원 → `column_state_utils.js` 분리 | ✅ 완료 |
