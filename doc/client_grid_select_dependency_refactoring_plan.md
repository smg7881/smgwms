# client_grid_controller.js — Select 의존 연동 + 상세폼 이벤트 공통화 작업계획

작성일: 2026-03-02

---

## 1. 현황 분석

### 1-1. 문제

`client_grid_controller.js`에 **검색폼 Select 연동**, **상세폼 Select 연동**, **상세폼 입력 이벤트 바인딩** 로직이 컨트롤러에 직접 구현되어 있다.

| 구분 | 관련 메서드 | 역할 |
|---|---|---|
| 검색폼 연동 | `bindSearchFields` | 이벤트 바인딩 |
| | `unbindSearchFields` | 이벤트 해제 |
| | `hydrateSearchSectionSelect` | 초기 옵션 채우기 |
| | `handleSearchGroupChange` | 그룹 변경 시 구분 옵션 교체 |
| | `groupKeywordFromSearch` | 그룹 현재 값 읽기 |
| | `sectionKeywordFromSearch` | 구분 현재 값 읽기 |
| 상세폼 연동 | `handleDetailGroupChange` | 그룹 변경 시 구분 옵션/값 동기화 |
| | `updateDetailSectionOptions` | 구분 select 옵션 갱신 |
| 공통 계산 | `resolveSectionOptions` | sectionMap → 옵션 배열 계산 |
| 상세폼 이벤트 | `bindDetailFieldEvents` | 상세폼 input/change 이벤트 바인딩 |
| | `unbindDetailFieldEvents` | 이벤트 해제 |
| | `detailFieldKey` | 필드 DOM → 데이터 키 추출 |

총 **12개 메서드**가 이 화면 전용 또는 중복 구현 상태이다.

### 1-2. 기존 공통 인프라 (재활용 대상)

| 파일 | 공통 함수 | 현재 사용처 |
|---|---|---|
| `grid/grid_dependent_select_utils.js` | `bindDependentSelects` | `location_grid_controller.js` (API 기반) |
| | `unbindDependentSelects` | `location_grid_controller.js` |
| `grid/core/search_form_bridge.js` | `getSearchFieldElement(name)` | `base_grid_controller.js` → `getSearchFieldElement` |
| `grid/grid_utils.js` | `setSelectOptions` | `client_grid_controller.js` 등 다수 |
| `grid/grid_form_utils.js` | `bindDetailFieldEvents` | **현재 미사용** (중복 구현 존재) |
| | `unbindDetailFieldEvents` | **현재 미사용** (중복 구현 존재) |
| | `detailFieldKey` | **현재 미사용** (중복 구현 존재) |
| | `syncDetailField` | **현재 미사용** (중복 구현 존재) |

### 1-3. 핵심 확인 사항

- `getSearchFieldElement("bzac_sctn_grp_cd")`는 내부적으로
  `formEl.querySelector('[name="q[bzac_sctn_grp_cd]"]')`와 **완전히 동일** →
  기존 `bindDependentSelects`를 그대로 활용 가능

- 현재 `bindSearchFields`가 `this.element.addEventListener("change", ...)` (루트 이벤트 위임) 방식인 반면
  `bindDependentSelects`는 **필드에 직접 바인딩** 방식 → 동작 동등, 직접 바인딩이 더 명확

- `resolveSectionOptions`는 **순수 계산 로직** → 공통 유틸로 추출 가능

- `client_grid_controller.js`의 `bindDetailFieldEvents` / `unbindDetailFieldEvents` / `detailFieldKey` 3개는
  `grid_form_utils.js`에 **완전히 동일한 함수가 이미 공통 유틸로 존재** → 중복 구현 상태
  - `client_grid_controller.js` 버전은 `_onDetailChange`에서 `handleDetailGroupChange` 직접 호출
  - `grid_form_utils.js` 버전은 `onDetailChangeExt` 훅을 통해 동일 역할 지원 → **완전 교체 가능**

- `resource_form_controller.js`는 **설계 목적이 근본적으로 다름** → 공통화 대상 아님
  - `client_grid_controller.js`: 그리드 행(`currentMasterRow`) 실시간 동기화 목적, 수동 바인딩/해제
  - `resource_form_controller.js`: Stimulus `data-action` 방식, 유효성 검사 + 의존 select 필터링 목적
  - 두 컨트롤러가 같은 유틸을 공유하는 것은 의미 없으며 `resource_form_controller.js` 변경 불필요

---

## 2. 목표

> `bindDependentSelects` / `unbindDependentSelects` 인프라를 그대로 활용하여
> 컨트롤러에서 9개 메서드를 제거하고, 공통 유틸에 `resolveMapOptions` 1개 함수만 추가한다.
> 추가로 상세폼 이벤트 3개 메서드(중복 구현)도 `grid_form_utils.js` 유틸로 교체하여
> 컨트롤러에서 총 **12개 메서드를 제거** → **1개 메서드(`#searchDependentConfig`)만 남긴다**.

---

## 3. 작업 범위

### Step 1. `grid_dependent_select_utils.js` — `resolveMapOptions` 추가

**파일:** `app/javascript/controllers/grid/grid_dependent_select_utils.js`

아래 순수 함수를 추가한다.

```javascript
/**
 * sectionMap(그룹코드 → 옵션배열) 기반 옵션 계산 순수 함수
 *
 * @param {Object} map   - { "INTERNAL": [{label, value}, ...], ... } 형태
 * @param {string} groupCode - 선택된 그룹 코드 (없으면 전체 dedupe 반환)
 * @returns {Array} { label, value } 옵션 배열
 */
export function resolveMapOptions(map, groupCode) {
  const normalized = (groupCode || "").toString().trim().toUpperCase()
  if (normalized && map[normalized]) return map[normalized]

  const all = Object.values(map).flat()
  const seen = new Set()
  return all.filter((item) => {
    if (!item?.value || seen.has(item.value)) return false
    seen.add(item.value)
    return true
  })
}
```

---

### Step 2. `client_grid_controller.js` — import 수정

**추가:**
```javascript
import {
  bindDependentSelects,
  unbindDependentSelects,
  resolveMapOptions
} from "controllers/grid/grid_dependent_select_utils"
```

**제거:** `setSelectOptions as setSelectOptionsUtil` import는 상세폼에서 여전히 직접 사용하므로 유지.

---

### Step 3. `client_grid_controller.js` — 검색폼 연동 교체

#### 3-1. `connect()` 수정

```javascript
// 변경 전
this.bindSearchFields()

// 변경 후
bindDependentSelects(this, this.#searchDependentConfig())
```

#### 3-2. `disconnect()` 수정

```javascript
// 변경 전
this.unbindSearchFields()

// 변경 후
unbindDependentSelects(this)
```

#### 3-3. `#searchDependentConfig()` private 메서드 추가

```javascript
#searchDependentConfig() {
  return {
    fields: ["bzac_sctn_grp_cd", "bzac_sctn_cd"],
    onChange: [
      (controller, fields) => {
        const options = resolveMapOptions(controller.sectionMapValue, fields[0]?.value)
        setSelectOptionsUtil(fields[1], options, "")
      }
    ],
    hydrate: (controller, fields) => {
      const options = resolveMapOptions(controller.sectionMapValue, fields[0]?.value)
      setSelectOptionsUtil(fields[1], options, fields[1]?.value || "")
    }
  }
}
```

#### 3-4. 제거 대상 메서드 (6개)

```
bindSearchFields
unbindSearchFields
hydrateSearchSectionSelect
handleSearchGroupChange
groupKeywordFromSearch
sectionKeywordFromSearch
```

---

### Step 4. `client_grid_controller.js` — 상세폼 연동 단순화

#### 4-1. `updateDetailSectionOptions` 수정

```javascript
// 변경 전
updateDetailSectionOptions(groupCode, selectedCode = "") {
  if (!this.hasDetailSectionFieldTarget) return
  const options = this.resolveSectionOptions(groupCode)
  setSelectOptionsUtil(this.detailSectionFieldTarget, options, selectedCode, "")
}

// 변경 후
updateDetailSectionOptions(groupCode, selectedCode = "") {
  if (!this.hasDetailSectionFieldTarget) return
  const options = resolveMapOptions(this.sectionMapValue, groupCode)
  setSelectOptionsUtil(this.detailSectionFieldTarget, options, selectedCode, "")
}
```

#### 4-2. 제거 대상 메서드 (1개)

```
resolveSectionOptions  → resolveMapOptions(this.sectionMapValue, groupCode) 인라인으로 대체
```

---

### Step 5. `client_grid_controller.js` — 상세폼 이벤트 바인딩 교체

> `grid_form_utils.js`에 이미 동일한 유틸이 존재하므로 중복 구현을 제거한다.

#### 5-1. import 추가

```javascript
import {
  bindDetailFieldEvents,
  unbindDetailFieldEvents
} from "controllers/grid/grid_form_utils"
```

#### 5-2. `connect()` 수정

```javascript
// 변경 전
this.bindDetailFieldEvents()

// 변경 후
bindDetailFieldEvents(this, null, (event) => {
  this.syncDetailField(event)
  const key = detailFieldKey(event.currentTarget)   // detailFieldKey도 grid_form_utils에서 import
  if (key === "fnc_or_cd") {
    this.syncPopupFieldPresentation(event.currentTarget, key, event.currentTarget.value)
  }
  if (key === "bzac_sctn_grp_cd") {
    this.handleDetailGroupChange(event)
  }
})
```

> **참고:** `onChangeCallback`을 명시적으로 전달하면 `grid_form_utils.js` 내부의 기본 로직(`syncDetailField` 자동 호출)이
> 콜백으로 대체된다. 따라서 콜백 안에 `this.syncDetailField(event)` 호출을 직접 포함해야 한다.

#### 5-3. `disconnect()` 수정

```javascript
// 변경 전
this.unbindDetailFieldEvents()

// 변경 후
unbindDetailFieldEvents(this)
```

#### 5-4. 제거 대상 메서드 (3개)

```
bindDetailFieldEvents   → grid_form_utils.js 유틸로 대체
unbindDetailFieldEvents → grid_form_utils.js 유틸로 대체
detailFieldKey          → grid_form_utils.js 유틸을 직접 import하여 사용
```

#### 5-5. `resource_form_controller.js` 관계 정리

`resource_form_controller.js`와는 **공통화 불가**, **변경 불필요**.

| 비교 항목 | `client_grid_controller.js` | `resource_form_controller.js` |
|---|---|---|
| 이벤트 바인딩 방식 | 수동 `addEventListener` (bind/unbind) | Stimulus `data-action` 자동 연결 |
| 주요 목적 | 그리드 행(`currentMasterRow`) 실시간 동기화 | 폼 유효성 검사 + 의존 select 필터링 |
| 상태 관리 | 그리드 API + 행 노드 | 폼 DOM + 검증 상태 |
| Tom Select 처리 | `setSelectOptions` 유틸 | `#filterDependentOptions` 내부 처리 |

두 컨트롤러는 역할이 명확히 분리되어 있으므로 **각자 유지**가 올바른 설계다.

---

## 4. 변경 전후 비교

| 항목 | 변경 전 | 변경 후 |
|---|---|---|
| 제거 메서드 수 | — | **12개** 제거 |
| 남는 추가 메서드 | — | `#searchDependentConfig` 1개 |
| 공통 유틸 추가 | 없음 | `resolveMapOptions` 1개 |
| 검색폼 이벤트 방식 | 루트 이벤트 위임 | 필드 직접 바인딩 (기존 인프라) |
| 상세폼 이벤트 방식 | 인라인 중복 구현 | `grid_form_utils.js` 공통 유틸 재사용 |
| 새 화면 적용 방법 | 6개 메서드 복붙 | config 1개 정의 |
| `resource_form_controller.js` | — | **변경 없음** (역할이 다름) |

---

## 5. 영향 범위

| 파일 | 변경 종류 |
|---|---|
| `grid/grid_dependent_select_utils.js` | `resolveMapOptions` 함수 추가 |
| `client_grid_controller.js` | 12개 메서드 제거, config 메서드 1개 추가, import 수정 |

**그 외 파일 변경 없음.**
`location_grid_controller.js`, `resource_form_controller.js` 등 기존 사용처는
인터페이스가 동일하거나 별개이므로 영향 없다.

---

## 6. 검증 항목

- [ ] 검색폼: 거래처구분그룹 선택 시 거래처구분이 필터링되는지
- [ ] 검색폼: 페이지 초기 로드 시 hydrate 동작 (그룹 미선택 → 전체 옵션)
- [ ] 검색폼: 그룹 선택 해제 시 거래처구분 전체 복원되는지
- [ ] 상세폼: 행 선택 시 그룹에 맞는 구분 옵션이 표시되는지
- [ ] 상세폼: 그룹 변경 시 구분 옵션/값 동기화되는지
- [ ] 상세폼: 신규 행 추가 후 그룹 선택 → 구분 연동 동작하는지
- [ ] `disconnect()` 후 이벤트 누수 없는지 (Tom Select 포함)
- [ ] 상세폼: 필드 입력 시 `currentMasterRow` 동기화 정상 동작하는지 (Step 5 교체 후)
- [ ] 상세폼: `fnc_or_cd` popup 필드 변경 시 표시 동기화 정상 동작하는지
- [ ] 상세폼: `bzac_sctn_grp_cd` 변경 시 `handleDetailGroupChange` 정상 호출되는지
