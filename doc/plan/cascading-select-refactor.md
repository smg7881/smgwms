# 계층형 의존 SELECT 공통화 리팩터링 계획

## 1. 현재 문제점

### JS 측 (`location_grid_controller.js`)

```
controller
  ├── loadAreaOptions(workplCd, selectedAreaCd)   ← 화면별 개별 메서드
  ├── loadZoneOptions(workplCd, areaCd, selectedZoneCd) ← 화면별 개별 메서드
  └── #dependentSelectConfig()
        ├── fields: [...]
        ├── onChange: [ 함수A, 함수B ]   ← clearOptions 호출 순서, 조건 분기 직접 작성
        └── hydrate: 함수C               ← 초기화 로직 직접 작성
```

**문제:**
- 새 화면마다 `loadXxxOptions()` 메서드를 반복 구현해야 함
- `onChange` 배열 안에 "몇 번째 하위를 clear할지"를 직접 계산해야 함
- `hydrate`도 순서대로 await 체인을 직접 짜야 함
- 3단(workpl → area → zone) 외에 2단, 4단으로 바뀌면 코드 대폭 수정 필요

---

### Ruby 측 (`wm/location/page_component.rb`)

```
PageComponent
  ├── workplace_search_options          ← 화면별 개별 구현
  ├── area_search_options               ← 화면별 개별 구현 (selected_workpl_cd 의존)
  ├── zone_search_options               ← 화면별 개별 구현 (selected_area_cd 의존)
  ├── selected_workpl_cd                ← 화면별 개별 구현
  └── selected_area_cd                  ← 화면별 개별 구현
```

**문제:**
- zone 화면, area 화면 등 동일 패턴의 화면 추가 시 동일 코드 반복
- 조건 체인(`selected_workpl_cd.blank? || selected_area_cd.blank?`)을 매번 작성

---

## 2. 목표: 선언형 Config 방식으로 단순화

### 변경 전 (현재)

```js
// controller: 메서드 3개 + 복잡한 config
async loadAreaOptions(workplCd, selectedAreaCd) { ... }
async loadZoneOptions(workplCd, areaCd, selectedZoneCd) { ... }

#dependentSelectConfig() {
  return {
    fields: ["workpl_cd", "area_cd", "zone_cd"],
    onChange: [
      async (controller, fields) => {
        const workplCd = controller.workplKeywordFromSearch()
        clearSelectOptions(fields[1])
        clearSelectOptions(fields[2])
        if (!workplCd) return
        await controller.loadAreaOptions(workplCd, "")
      },
      async (controller, fields) => { ... }
    ],
    hydrate: async (controller, fields) => { ... }
  }
}
```

### 변경 후 (목표)

```js
// controller: 선언형 체인만 선언, 나머지는 유틸리티가 처리
dependentSelectChain() {
  return [
    {
      field:       "workpl_cd",
      childField:  "area_cd",
      url:         this.areasUrlValue,
      params:      (vals) => ({ workpl_cd: vals.workpl_cd }),
      valueField:  "area_cd",
      labelFields: ["area_cd", "area_nm"],
    },
    {
      field:       "area_cd",
      childField:  "zone_cd",
      url:         this.zonesUrlValue,
      params:      (vals) => ({ workpl_cd: vals.workpl_cd, area_cd: vals.area_cd }),
      valueField:  "zone_cd",
      labelFields: ["zone_cd", "zone_nm"],
    }
  ]
}
```

`loadAreaOptions`, `loadZoneOptions` 메서드 완전 제거.
`bindDependentSelects` / `unbindDependentSelects` 호출은 그대로 유지.

---

## 3. 구현 계획

### Step 1 — JS 유틸리티 확장 (`grid_dependent_select_utils.js`)

#### 1-1. 선언형 체인 → 기존 Config 변환 함수 추가

```js
/**
 * 선언형 체인 배열을 기존 { fields, onChange, hydrate } config로 변환합니다.
 * 컨트롤러는 이 변환 결과를 bindDependentSelects에 그대로 전달합니다.
 */
export function buildChainConfig(controller, chain) {
  // ...구현 (아래 설명 참조)
}
```

**내부 동작 원칙:**

1. `fields` 배열 = chain의 모든 `field` + 마지막 `childField`
   - 예: `["workpl_cd", "area_cd", "zone_cd"]`

2. `onChange[i]` = chain[i]가 변경될 때:
   - chain[i].childField ~ 마지막 필드까지 `clearSelectOptions`
   - 자신(chain[i])의 부모들 값을 `params()` 함수로 수집
   - `chain[i].url` 호출 → options 빌드 → `setSelectOptions(childField)`

3. `hydrate` = 페이지 진입 시:
   - chain을 순서대로 실행
   - 현재 선택값이 있으면 로드 + 선택값 복원
   - 없으면 하위 전체 clear

#### 1-2. params 값 수집 헬퍼

각 체인 링크의 `params(vals)` 함수에 `vals` 객체를 전달.
`vals`는 `{ 필드명: 현재선택값 }` 형태로 `getSearchFormValue(field)`로 수집.

#### 1-3. label 조합 헬퍼

```js
function buildLabel(row, labelFields) {
  return labelFields.map((f) => row[f] || "").filter(Boolean).join(" - ")
}
```

---

### Step 2 — JS 컨트롤러 단순화 (`location_grid_controller.js`)

**제거 대상:**
- `import { setSelectOptions as setSelectOptionsUtil, clearSelectOptions }` (직접 사용 없음)
- `loadAreaOptions()` 메서드
- `loadZoneOptions()` 메서드
- `#dependentSelectConfig()` (→ `dependentSelectChain()`으로 교체)

**변경 후 코드 크기:** 약 60줄 감소 예상

```js
// connect / disconnect
connect() {
  super.connect()
  this.bindSearchFields()
}
disconnect() {
  this.unbindSearchFields()
  super.disconnect()
}

// 바인딩 (유틸리티에 위임)
async bindSearchFields() {
  const config = buildChainConfig(this, this.dependentSelectChain())
  await bindDependentSelects(this, config)
}

unbindSearchFields() {
  unbindDependentSelects(this)
}

// 선언형 체인
dependentSelectChain() {
  return [
    {
      field: "workpl_cd", childField: "area_cd",
      url: this.areasUrlValue,
      params: (vals) => ({ workpl_cd: vals.workpl_cd }),
      valueField: "area_cd", labelFields: ["area_cd", "area_nm"],
    },
    {
      field: "area_cd", childField: "zone_cd",
      url: this.zonesUrlValue,
      params: (vals) => ({ workpl_cd: vals.workpl_cd, area_cd: vals.area_cd }),
      valueField: "zone_cd", labelFields: ["zone_cd", "zone_nm"],
    }
  ]
}
```

---

### Step 3 — Ruby Concern 추출

#### 3-1. Concern 파일 생성

**파일:** `app/components/concerns/wm/cascading_workplace_select.rb`

```ruby
module Wm
  module CascadingWorkplaceSelect
    # search_fields에서 직접 사용할 options 메서드들

    def workplace_search_options(include_blank: false)
      opts = include_blank ? [ { label: "전체", value: "" } ] : []
      opts + workplace_records.map do |w|
        { label: "#{w.workpl_cd} - #{w.workpl_nm}", value: w.workpl_cd }
      end
    end

    def area_search_options
      opts = [ { label: "전체", value: "" } ]
      return opts if selected_workpl_cd.blank?
      opts + WmArea.where(workpl_cd: selected_workpl_cd, use_yn: "Y").ordered.map do |a|
        { label: "#{a.area_cd} - #{a.area_nm}", value: a.area_cd }
      end
    end

    def zone_search_options
      opts = [ { label: "전체", value: "" } ]
      return opts if selected_workpl_cd.blank? || selected_area_cd.blank?
      opts + WmZone.where(workpl_cd: selected_workpl_cd, area_cd: selected_area_cd, use_yn: "Y").ordered.map do |z|
        { label: "#{z.zone_cd} - #{z.zone_nm}", value: z.zone_cd }
      end
    end

    def selected_workpl_cd
      @selected_workpl_cd ||= begin
        value = query_params.dig("q", "workpl_cd").to_s.strip.upcase
        value.presence || workplace_records.first&.workpl_cd
      end
    end

    def selected_area_cd
      @selected_area_cd ||= query_params.dig("q", "area_cd").to_s.strip.upcase.presence
    end

    def selected_zone_cd
      @selected_zone_cd ||= query_params.dig("q", "zone_cd").to_s.strip.upcase.presence
    end

    private
      def workplace_records
        @workplace_records ||= WmWorkplace.where(use_yn: "Y").ordered.to_a
      end
  end
end
```

#### 3-2. PageComponent에서 include

```ruby
class Wm::Location::PageComponent < Wm::BasePageComponent
  include Wm::CascadingWorkplaceSelect

  # workplace_search_options, area_search_options, zone_search_options
  # selected_workpl_cd, selected_area_cd, selected_zone_cd
  # ↑ 모두 Concern에서 제공됨 → 아래 메서드들 전부 삭제
```

**제거 대상 메서드 (5개):**
- `workplace_search_options`
- `area_search_options`
- `zone_search_options`
- `selected_workpl_cd`
- `selected_area_cd`
- `workplace_records` (private)

---

## 4. 파일 변경 목록

| 파일 | 작업 |
|------|------|
| `app/javascript/controllers/grid/grid_dependent_select_utils.js` | `buildChainConfig()` 함수 추가 |
| `app/javascript/controllers/wm/location_grid_controller.js` | `loadAreaOptions`, `loadZoneOptions`, `#dependentSelectConfig` 제거 → `dependentSelectChain()` 추가 |
| `app/components/concerns/wm/cascading_workplace_select.rb` | 신규 생성 |
| `app/components/wm/location/page_component.rb` | Concern include + 중복 메서드 제거 |

---

## 5. 확장성

이후 `wm/zone`, `wm/area` 화면 등 동일 패턴 화면 추가 시:

**Ruby 측:** `include Wm::CascadingWorkplaceSelect` 한 줄만 추가
**JS 측:** `dependentSelectChain()` 선언만 추가 (2~3단계 선택 여부에 따라)

2단 체인(작업장 → AREA만) 예시:
```js
dependentSelectChain() {
  return [
    {
      field: "workpl_cd", childField: "area_cd",
      url: this.areasUrlValue,
      params: (vals) => ({ workpl_cd: vals.workpl_cd }),
      valueField: "area_cd", labelFields: ["area_cd", "area_nm"],
    }
  ]
}
```

---

## 6. 구현 순서 (권장)

1. `grid_dependent_select_utils.js`에 `buildChainConfig` 구현 및 단위 테스트
2. `location_grid_controller.js` 리팩터링 및 동작 확인
3. Ruby Concern 파일 생성
4. `wm/location/page_component.rb` include + 중복 제거
5. 화면 동작 전체 검증 (초기 진입, 작업장 변경, AREA 변경, 검색 후 재진입)
