# AG Grid 관련 JavaScript 코드 중복 분석 보고서

> 분석 대상 경로:
> - `app/javascript/controllers/ag_grid/` (6개 파일)
> - `app/javascript/controllers/grid/` (11개 파일)
> - `app/javascript/controllers/ag_grid_controller.js`
> - `app/javascript/controllers/base_grid_controller.js`
> - `app/javascript/controllers/grid_actions_controller.js`
> - `app/javascript/controllers/lookup_popup_modal.js`

---

## 1. 파일별 역할 현황

| 파일 | 현재 역할 | 문제점 |
|------|-----------|--------|
| `ag_grid/grid_defaults.js` | AG Grid 테마, Locale, 포매터, 모듈 등록 | 단일 책임, 적절함 |
| `ag_grid/column_builder.js` | 컬럼 정의 빌더 | 단일 책임, 적절함 |
| `ag_grid/renderers.js` | 렌더러 레지스트리 통합 | 단일 책임, 적절함 |
| `ag_grid/renderers/common.js` | 공통 렌더러 | 단일 책임, 적절함 |
| `ag_grid/renderers/actions.js` | 액션 렌더러 | 단일 책임, 적절함 |
| `ag_grid/data_loader.js` | 그리드 데이터 로딩 | `grid/core/http_client.js` 직접 의존 |
| `grid/core/api_guard.js` | `isApiAlive` 원본 정의 | 단일 책임, 적절함 |
| `grid/core/http_client.js` | `requestJson`, `fetchJson`, `getCsrfToken` 원본 | 단일 책임, 적절함 |
| `grid/core/search_form_bridge.js` | 검색폼 bridge | 단일 책임, 적절함 |
| `grid/core/resource_form_bridge.js` | 리소스폼 bridge | 단일 책임, 적절함 |
| `grid/request_tracker.js` | 중복 요청 방지 AbortController 래퍼 | 단일 책임, 적절함 |
| `grid/grid_event_manager.js` | AG Grid 이벤트 바인딩/해제 관리 | 단일 책임, 적절함 |
| `grid/grid_utils.js` | **HTTP re-export + 그리드 유틸 + DOM 유틸 혼재** | **책임 혼재 (핵심 문제)** |
| `grid/grid_crud_manager.js` | CRUD 상태 추적 클래스 | `grid_utils`에 과도 의존 |
| `grid/grid_form_utils.js` | 마스터-디테일 폼 동기화 유틸 | `grid_utils`에서 `isApiAlive` re-import |
| `grid/grid_popup_utils.js` | 팝업 DOM 조작 유틸 | 단일 책임, 적절함 |
| `grid/grid_dependent_select_utils.js` | 계층형 SELECT 연동 유틸 | `grid_utils`에서 `fetchJson` re-import |
| `ag_grid_controller.js` | AG Grid 메인 Stimulus 컨트롤러 | `#showToast` 독자 구현 |
| `base_grid_controller.js` | CRUD 공통 Stimulus 베이스 컨트롤러 | `requestJson`/`postJson` 중복 사용 |
| `grid_actions_controller.js` | 그리드 툴바 버튼 위임 컨트롤러 | 단일 책임, 적절함 |
| `lookup_popup_modal.js` | 팝업 열기 래퍼 | 단일 책임, 적절함 |

---

## 2. 중복 및 문제 목록

### [중복-01] `fetchJson` 3중 정의

**가장 심각한 중복.**

| 위치 | 코드 | 비고 |
|------|------|------|
| `grid/core/http_client.js:33` | `export async function fetchJson(url, { signal } = {})` | **원본 (정답)** |
| `grid/grid_utils.js:26` | `export async function fetchJson(url, { signal } = {})` | `http_client.js`의 `fetchJsonCore`를 1:1 래핑하여 re-export |
| `ag_grid/data_loader.js:1` | `import { fetchJson } from "controllers/grid/core/http_client"` | 원본 직접 사용 |
| `grid/grid_dependent_select_utils.js:21` | `import { fetchJson } from "controllers/grid/grid_utils"` | re-export 경유 사용 |

**문제:** 동일 함수가 `http_client.js`(원본) → `grid_utils.js`(별칭 재선언) 2단계 체인을 형성.
`grid_utils.js`에서 `fetchJson`을 직접 선언하는 것은 의미 없는 래핑임.

---

### [중복-02] `isApiAlive` 임포트 경로 혼재

| 위치 | import 경로 |
|------|-------------|
| `ag_grid/data_loader.js` | `controllers/grid/core/api_guard` (원본) |
| `grid/grid_event_manager.js` | `controllers/grid/core/api_guard` (원본) |
| `grid/grid_crud_manager.js` | `controllers/grid/grid_utils` (re-export) |
| `base_grid_controller.js` | `controllers/grid/grid_utils` (re-export) |
| `grid/grid_form_utils.js` | `controllers/grid/grid_utils` (re-export) |

**문제:** 같은 함수를 어떤 파일은 원본에서, 어떤 파일은 `grid_utils` 경유로 import.
`grid_utils.js`가 `api_guard.js`를 re-export하는 중간 허브 역할을 하면서 경로가 두 갈래로 나뉨.

---

### [중복-03] `requestJson` / `postJson` 혼재

**HTTP POST 요청을 처리하는 방식이 3가지로 분산.**

```
[원본] grid/core/http_client.js
  └─ requestJson(url, { method, body, signal, headers, isMultipart })
       → { response, result } 반환

[래핑-1] grid/grid_utils.js
  └─ postJson(url, body)
       → requestJson 호출 + 실패 시 showAlert 처리
       → result 또는 false 반환

[래핑-2] base_grid_controller.js::postAction()
  └─ requestJsonCore 직접 호출 (http_client.js에서 import)
       + confirmAction + onSuccess/onFail 콜백 처리
       → boolean 반환
```

**문제:**
- `postJson`은 에러 메시지를 내부에서 고정 처리 (`"저장 실패: ..."`)
- `postAction`은 외부 콜백으로 에러 처리
- `base_grid_controller.js`에서 `postJson`(grid_utils 경유)과 `requestJsonCore`(http_client 경유)를 **모두 import**하여 사용

```js
// base_grid_controller.js:32,40-41 — 두 경로 동시 사용
import { ..., postJson, ... } from "controllers/grid/grid_utils"
import { requestJson as requestJsonCore } from "controllers/grid/core/http_client"
```

---

### [중복-04] `getCsrfToken` re-export 불필요

| 위치 | 코드 |
|------|------|
| `grid/core/http_client.js:1` | `export function getCsrfToken()` — **원본** |
| `grid/grid_utils.js:5` | `export { isApiAlive, getCsrfToken }` — **re-export만 함** |

`getCsrfToken`은 `http_client.js`가 자체적으로 사용하는 내부 헬퍼인데
`grid_utils.js`에서 재노출하여 외부에서 직접 사용할 수 있는 공개 API처럼 혼동 유발.

---

### [중복-05] Validation 에러 포맷 함수 중복

**거의 동일한 로직이 두 곳에 존재.**

```js
// base_grid_controller.js:745-749
#formatValidationLine(error) {
  const scopeLabel = error?.scope === "insert" ? "추가" : "수정"
  const rowLabel = Number.isInteger(error?.rowIndex) ? `${error.rowIndex + 1}행` : "행"
  const message = (error?.message || "입력값을 확인해주세요.").toString()
  return `[${scopeLabel} ${rowLabel}] ${message}`
}

// grid/grid_crud_manager.js:615-620
#formatSingleValidationError(error) {
  const scopeLabel = error?.scope === "insert" ? "추가" : "수정"
  const rowLabel = Number.isInteger(error?.rowIndex) ? `${error.rowIndex + 1}행` : "행"
  const fieldLabel = error?.fieldLabel || error?.field || "입력값"
  const message = error?.message || `${fieldLabel} 입력값을 확인하세요.`
  return `[${scopeLabel} ${rowLabel}] ${message}`
}
```

`GridCrudManager.formatValidationSummary()`가 내부적으로 `#formatSingleValidationError`를 사용하며
`base_grid_controller.js`도 비슷한 포맷으로 재구현.

---

### [중복-06] `#showToast` — `showAlert`와 기능 분리된 독자 Toast

```js
// ag_grid_controller.js:832-852
#showToast(message) {
  const toast = document.createElement("div")
  toast.textContent = message
  // 우하단 고정 포지션, 2초 자동 소멸
  ...
}
```

`components/ui/alert.js`의 `showAlert()`와 별개로 독자 Toast DOM을 생성.
기능적 역할(짧은 알림)은 동일하나 위치, 스타일이 다름.

**현재 `#showToast`는 다음 상황에 사용:**
- `saveColumnState` / `resetColumnState` — "컬럼 상태가 저장/초기화되었습니다"
- `clearFilter` — "필터가 초기화되었습니다"
- 클립보드 복사/붙여넣기 피드백

---

### [중복-07] `grid_utils.js` 책임 과부하

`grid_utils.js` 한 파일 안에 성격이 다른 4가지 역할이 혼재:

```
grid_utils.js
 ├─ [HTTP 레이어 re-export]
 │    isApiAlive, getCsrfToken, fetchJson
 │
 ├─ [HTTP 래핑]
 │    postJson(url, body) → requestJson 래핑
 │
 ├─ [AG Grid 데이터 조작]
 │    setGridRowData, setManagerRowData, collectRows
 │    refreshStatusCells, hideNoRowsOverlay
 │
 ├─ [비즈니스 로직 / 상태 체크]
 │    hasChanges, hasPendingChanges
 │    blockIfPendingChanges, requireSelection
 │    isLoadableMasterRow, focusFirstRow
 │
 ├─ [URL 빌더]
 │    buildTemplateUrl
 │
 ├─ [DOM 조작 (SELECT)]
 │    setSelectOptions, clearSelectOptions
 │
 └─ [기타 유틸]
      uuid, numberOrNull, refreshSelectionLabel
      resolveNameFromMap, buildCompositeKey
```

**문제:** 어떤 파일이 어떤 기능만 필요해도 전체 `grid_utils`를 import해야 함.
Tree-shaking이 되더라도 import 경로의 의미가 불명확해짐.

---

### [중복-08] `postAction` vs `saveRowsWith` — HTTP 에러 처리 이원화

```js
// base_grid_controller.js::postAction (단건 커스텀 액션용)
async postAction(url, body, { confirmMessage, onSuccess, onFail } = {}) {
  const { response, result } = await requestJsonCore(url, { method: "POST", body })
  // 성공/실패를 onSuccess/onFail 콜백으로 위임
}

// base_grid_controller.js::saveRowsWith (일괄저장용)
const ok = await postJson(batchUrl, operations)  // grid_utils.postJson 사용
// postJson 내부에서 showAlert 고정 처리
```

동일한 컨트롤러에서 POST 요청 처리 방식이 두 가지로 분리됨.

---

## 3. import 의존 관계도

```
[http 원본 레이어]
  grid/core/api_guard.js      → isApiAlive
  grid/core/http_client.js    → getCsrfToken, requestJson, fetchJson

         ↓ (re-export + 추가 구현)
[혼합 유틸 레이어]
  grid/grid_utils.js          → isApiAlive(re), getCsrfToken(re), fetchJson(re)
                                 postJson, setGridRowData, uuid, hasChanges, ...

         ↓ (각각 직접 또는 grid_utils 경유)
[사용 레이어]
  ag_grid/data_loader.js      → http_client 직접 + api_guard 직접
  grid/grid_crud_manager.js   → grid_utils 경유
  grid/grid_form_utils.js     → grid_utils 경유 (isApiAlive만)
  grid/grid_dependent_select_utils.js → grid_utils 경유 (fetchJson만)
  grid/grid_event_manager.js  → api_guard 직접
  base_grid_controller.js     → grid_utils 경유 + http_client 직접 (혼용!)
```

**핵심 문제:** `grid_utils.js`가 "만능 통합 파일"처럼 사용되면서
- 일부 파일은 원본(core/)에서 직접 import
- 일부 파일은 `grid_utils` 경유로 import
- `base_grid_controller.js`는 **양쪽을 동시에** import

---

## 4. 통합 아키텍처 제안

### 4-1. 레이어 재편 목표

```
[core/ 레이어] — 순수 기능, 외부 의존 없음
  grid/core/api_guard.js      → isApiAlive (현행 유지)
  grid/core/http_client.js    → getCsrfToken, requestJson, fetchJson (현행 유지)
  grid/core/search_form_bridge.js  (현행 유지)
  grid/core/resource_form_bridge.js (현행 유지)

[grid/ 레이어] — AG Grid 전용 유틸
  grid/grid_api_utils.js      (신규 분리) → setGridRowData, setManagerRowData,
                                            collectRows, refreshStatusCells,
                                            hideNoRowsOverlay, focusFirstRow
  grid/grid_state_utils.js    (신규 분리) → hasChanges, hasPendingChanges,
                                            blockIfPendingChanges, requireSelection,
                                            isLoadableMasterRow
  grid/grid_select_utils.js   (신규 분리) → setSelectOptions, clearSelectOptions,
                                            resolveNameFromMap
  grid/grid_utils.js          (슬림화)   → uuid, numberOrNull, buildTemplateUrl,
                                            refreshSelectionLabel, buildCompositeKey
                                            + 하위호환 re-export 제거

  grid/grid_crud_manager.js   (현행 유지, import 경로 정리)
  grid/grid_event_manager.js  (현행 유지)
  grid/grid_form_utils.js     (현행 유지, import 경로 정리)
  grid/grid_popup_utils.js    (현행 유지)
  grid/grid_dependent_select_utils.js (현행 유지, fetchJson 직접 import로 변경)
  grid/request_tracker.js     (현행 유지)

[ag_grid/ 레이어] — AG Grid 컨트롤러 전용
  ag_grid/grid_defaults.js    (현행 유지)
  ag_grid/column_builder.js   (현행 유지)
  ag_grid/data_loader.js      (현행 유지)
  ag_grid/renderers.js        (현행 유지)
  ag_grid/renderers/common.js (현행 유지)
  ag_grid/renderers/actions.js (현행 유지)

[controllers/ 레이어] — Stimulus 컨트롤러
  ag_grid_controller.js       (#showToast 정리)
  base_grid_controller.js     (import 경로 단일화)
  grid_actions_controller.js  (현행 유지)
  lookup_popup_modal.js       (현행 유지)
```

---

### 4-2. 중복별 통합 방향

#### [중복-01, 02] fetchJson / isApiAlive — import 경로 단일화

**원칙:** `core/` 파일에서만 직접 import. `grid_utils.js`의 re-export 제거.

```js
// 변경 전 (grid_utils.js)
export { isApiAlive, getCsrfToken }          // api_guard, http_client re-export
export async function fetchJson(url, ...) {  // 불필요한 래핑
  return fetchJsonCore(url, ...)
}

// 변경 후 (grid_utils.js에서 위 코드 삭제)
// 각 파일에서 직접 import
import { isApiAlive } from "controllers/grid/core/api_guard"
import { fetchJson } from "controllers/grid/core/http_client"
```

**영향 파일:** `grid_crud_manager.js`, `grid_form_utils.js`, `base_grid_controller.js`,
`grid_dependent_select_utils.js`의 import 경로 수정 필요.

---

#### [중복-03] requestJson / postJson — 단일 HTTP 헬퍼로 통합

**현행 `postJson` (grid_utils.js):**
```js
// 저장 실패 메시지가 고정 하드코딩 → 재사용성 제한
export async function postJson(url, body) {
  ...
  showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
}
```

**제안:** `postJson`의 에러 처리를 외부로 위임 가능하도록 옵션 추가,
또는 `base_grid_controller.js::postAction`과 통합.

```js
// grid/core/http_client.js 또는 grid/grid_utils.js
export async function postJson(url, body, {
  onError = null  // null이면 기본 showAlert 사용
} = {}) {
  try {
    const { response, result } = await requestJson(url, { method: "POST", body })
    if (!response.ok || !result.success) {
      const msg = "저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", ")
      if (onError) onError(msg, result)
      else showAlert(msg)
      return false
    }
    return result
  } catch {
    const msg = "저장 실패: 네트워크 오류"
    if (onError) onError(msg)
    else showAlert(msg)
    return false
  }
}
```

---

#### [중복-05] Validation 에러 포맷 — GridCrudManager에 위임

`base_grid_controller.js`의 `#formatValidationLine`을 삭제하고
`manager.formatValidationSummary()`를 호출하는 방식으로 통일.

```js
// base_grid_controller.js::showValidationErrors 내부
// 변경 전
item.textContent = this.#formatValidationLine(error)

// 변경 후 (manager가 있을 때 위임)
item.textContent = manager?.formatValidationSummary?.([error]) ?? this.#formatValidationLine(error)
```

또는 `formatValidationLine`을 `grid_utils.js`에 공개 함수로 추출하여 양쪽에서 import.

---

#### [중복-06] `#showToast` — `showAlert`와 통합 또는 분리 유지

현재 `#showToast`는 **우하단 toast 스타일**이고 `showAlert`는 **모달/인라인** 스타일.
UX 차이가 의도적이라면 분리 유지. 통합하려면:

**옵션 A:** `showAlert`에 `position: "toast"` 옵션 추가
**옵션 B:** `components/ui/alert.js`에 별도 `showToast()` export 추가 (현재 `#showToast` 로직 이전)

---

#### [중복-07] `grid_utils.js` 분리

| 분리 대상 함수 | 이동 위치 |
|---------------|-----------|
| `setGridRowData`, `setManagerRowData`, `collectRows`, `refreshStatusCells`, `hideNoRowsOverlay`, `focusFirstRow` | `grid/grid_api_utils.js` (신규) |
| `hasChanges`, `hasPendingChanges`, `blockIfPendingChanges`, `requireSelection`, `isLoadableMasterRow` | `grid/grid_state_utils.js` (신규) |
| `setSelectOptions`, `clearSelectOptions` | `grid/grid_select_utils.js` (신규) |
| `uuid`, `numberOrNull`, `buildTemplateUrl`, `refreshSelectionLabel`, `resolveNameFromMap`, `buildCompositeKey` | `grid/grid_utils.js` (잔류, 슬림화) |

---

## 5. 폴더 구조 분석 (`ag_grid/` vs `grid/`)

### 현재 폴더 구조

```
controllers/
├── ag_grid/                   ← AG Grid 라이브러리 어댑터
│   ├── grid_defaults.js       (테마, Locale, 포매터, 모듈 등록)
│   ├── column_builder.js      (컬럼 정의 빌더)
│   ├── data_loader.js         (데이터 로딩 — core/http_client 직접 의존)
│   ├── renderers.js           (렌더러 레지스트리 통합)
│   └── renderers/
│       ├── common.js
│       └── actions.js
│
├── grid/                      ← 애플리케이션 그리드 추상화
│   ├── core/
│   │   ├── api_guard.js
│   │   ├── http_client.js
│   │   ├── search_form_bridge.js
│   │   └── resource_form_bridge.js
│   ├── grid_crud_manager.js
│   ├── grid_utils.js
│   ├── grid_event_manager.js
│   ├── grid_form_utils.js
│   ├── grid_popup_utils.js
│   ├── grid_dependent_select_utils.js
│   └── request_tracker.js
│
├── ag_grid_controller.js      ← ag_grid/ 만 import
├── base_grid_controller.js    ← grid/ 만 import
└── ...
```

### 문제점: 폴더 분리의 경계가 불명확

- `ag_grid/data_loader.js`가 `grid/core/http_client.js`를 직접 import → **폴더 간 의존 발생**
- `ag_grid/`는 오직 `ag_grid_controller.js`만 사용 → 실질적으로 `ag_grid_controller.js`의 내부 모듈
- 두 폴더 모두 AG Grid와 관련된 코드인데 분리 기준이 모호

### 폴더 통합 권장

`ag_grid/` 폴더를 `grid/ag_grid/`로 이동하여 전체를 `grid/` 하위에 통합:

```
controllers/
├── grid/
│   ├── core/                  (현행 유지)
│   ├── ag_grid/               (현행 ag_grid/ 이동)
│   │   ├── grid_defaults.js
│   │   ├── column_builder.js
│   │   ├── data_loader.js
│   │   ├── renderers.js
│   │   └── renderers/
│   │       ├── common.js
│   │       └── actions.js
│   ├── grid_crud_manager.js   (현행 유지)
│   ├── grid_utils.js          (현행 유지, 슬림화)
│   ├── grid_event_manager.js  (현행 유지)
│   ├── grid_form_utils.js     (현행 유지)
│   ├── grid_popup_utils.js    (현행 유지)
│   ├── grid_dependent_select_utils.js (현행 유지)
│   └── request_tracker.js    (현행 유지)
│
├── ag_grid_controller.js      (import 경로 수정 필요)
├── base_grid_controller.js    (변경 없음)
└── ...
```

**통합 시 변경되는 import 경로:**

| 파일 | 현행 경로 | 변경 후 경로 |
|------|-----------|-------------|
| `ag_grid_controller.js` | `controllers/ag_grid/grid_defaults` | `controllers/grid/ag_grid/grid_defaults` |
| `ag_grid_controller.js` | `controllers/ag_grid/column_builder` | `controllers/grid/ag_grid/column_builder` |
| `ag_grid_controller.js` | `controllers/ag_grid/data_loader` | `controllers/grid/ag_grid/data_loader` |
| `ag_grid_controller.js` | `controllers/ag_grid/renderers` | `controllers/grid/ag_grid/renderers` |
| `ag_grid/renderers.js` | `controllers/ag_grid/renderers/common` | `controllers/grid/ag_grid/renderers/common` |
| `ag_grid/renderers.js` | `controllers/ag_grid/renderers/actions` | `controllers/grid/ag_grid/renderers/actions` |
| `ag_grid/renderers/actions.js` | `controllers/ag_grid/renderers/common` | `controllers/grid/ag_grid/renderers/common` |

→ **총 7개 경로 변경, 외부 비즈니스 컨트롤러는 영향 없음**

---

## 6. 우선순위별 작업 계획

### Phase 1 — 무위험 정리 (import 경로 통일, 즉시 가능)

1. `grid_utils.js`에서 `isApiAlive`, `getCsrfToken`, `fetchJson` re-export 제거
2. 각 사용 파일의 import 경로를 `core/` 원본으로 직접 변경
   - `grid_crud_manager.js`: `grid_utils` → `core/api_guard`
   - `grid_form_utils.js`: `grid_utils` → `core/api_guard`
   - `grid_dependent_select_utils.js`: `grid_utils` → `core/http_client`
   - `base_grid_controller.js`: `requestJsonCore` import 제거, `http_client`에서 직접

### Phase 2 — 유틸 파일 분리 (리팩토링)

3. `grid/grid_api_utils.js` 신규 생성 (AG Grid 조작 함수 이전)
4. `grid/grid_state_utils.js` 신규 생성 (상태 체크 함수 이전)
5. `grid_utils.js` 슬림화, 각 사용처 import 경로 업데이트

### Phase 3 — 논리 통합 (설계 변경)

6. `#showToast` → `components/ui/alert.js`로 이전 또는 공식 Toast 함수 추출
7. `postJson` 에러 처리 옵션화 또는 `postAction`과 통합
8. `#formatValidationLine` 제거 후 `GridCrudManager` 위임

---

## 7. 요약

| 중복 번호 | 항목 | 심각도 | 난이도 |
|-----------|------|--------|--------|
| 중복-01 | `fetchJson` 3중 정의 | 높음 | 낮음 |
| 중복-02 | `isApiAlive` 경로 혼재 | 중간 | 낮음 |
| 중복-03 | `requestJson`/`postJson` 혼재 | 높음 | 중간 |
| 중복-04 | `getCsrfToken` 불필요 re-export | 낮음 | 낮음 |
| 중복-05 | Validation 포맷 함수 중복 | 중간 | 낮음 |
| 중복-06 | `#showToast` 독자 구현 | 낮음 | 중간 |
| 중복-07 | `grid_utils.js` 책임 과부하 | 높음 | 높음 |
| 중복-08 | POST 에러 처리 이원화 | 중간 | 중간 |

**가장 먼저 해야 할 작업:** Phase 1 (import 경로 통일) — 코드 동작 변경 없이 구조만 정리.
**가장 효과 큰 작업:** 중복-07 `grid_utils.js` 분리 — 향후 유지보수성 대폭 향상.
