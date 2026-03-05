---
name: master-detail-screen-pattern
description: Build Rails WMS master-detail screens by reusing the `system/code` implementation pattern (ViewComponent + Stimulus BaseGridController + master/detail batch_save controllers). Use when creating a new 1:N management screen with two AG Grids, parent selection driven detail loading, and separate master/detail save flows.
---

# Master-Detail Screen Pattern

공통코드관리(`system/code`)의 마스터-디테일 구현을 기준으로 새 화면을 만든다.
항상 3레이어(`PageComponent` + `Stimulus` + `Rails Controller`)를 동시에 맞춘다.

## Quick Start
1. 기준 구현을 먼저 읽는다.
- `app/components/system/code/page_component.rb`
- `app/components/system/code/page_component.html.erb`
- `app/javascript/controllers/system/code_grid_controller.js`
- `app/controllers/system/code_controller.rb`
- `app/controllers/system/code_details_controller.rb`
2. 새 도메인 파일을 만든다.
- `<ns>/<module>/page_component.rb`
- `<ns>/<module>/page_component.html.erb`
- `<ns>_<module>_grid_controller.js`
- `<ns>/<plural_controller>.rb` (master)
- `<ns>/<detail_controller>.rb` (detail)
3. [master-detail-scaffold.md](references/master-detail-scaffold.md)를 복사해 뼈대를 채운다.
4. [master-detail-checklist.md](references/master-detail-checklist.md) 순서대로 빠진 항목을 점검한다.

## Workflow

### 1. Route를 먼저 고정한다
- master 리소스에 `batch_save`를 둔다.
- master 하위 detail 리소스에도 `batch_save`를 둔다.
- detail URL 템플릿 치환 키를 한 가지로 통일한다 (`:code`, `:id` 등).

### 2. PageComponent에 master/detail 계약을 선언한다
- `collection_path`, `member_path`를 정의한다.
- `detail_collection_path`와 `detail_grid_url`을 분리한다.
- `master_batch_save_url`, `detail_batch_save_url_template`를 분리한다.
- `selected_*_label` 메서드로 우측(또는 하단) 디테일 컨텍스트 문구를 만든다.
- `search_fields`, `master_columns`, `detail_columns`를 독립 관리한다.

### 3. ERB에서 Stimulus value 계약을 맞춘다
- 최상위 래퍼에 `data-controller="<name>-grid"`를 둔다.
- `ag-grid:ready->...#registerGrid`를 연결한다.
- master/detial URL value를 모두 주입한다.
- `selected` value를 주입해 첫 렌더 상태와 JS 상태를 맞춘다.
- AG Grid target 이름을 `masterGrid`, `detailGrid`로 고정한다.

### 4. Stimulus를 `BaseGridController + gridRoles()` 기반으로 작성한다
- `static targets`에 `masterGrid`, `detailGrid`, `selected...Label`을 등록한다.
- `static values`에 `masterBatchUrl`, `detailBatchUrlTemplate`, `detailListUrlTemplate`, `selected...`를 등록한다.
- `gridRoles()`에서 `master`, `detail` 역할을 선언한다.
- detail role에 `parentGrid`, `onMasterRowChange`, `detailLoader`를 반드시 둔다.
- `masterManagerConfig()`와 `detailManagerConfig()`를 분리한다.
- 디테일 액션 전에 `blockIfPendingChanges(masterManager, "...")`로 마스터 미저장 변경을 차단한다.
- 디테일 저장 URL은 `buildTemplateUrl()`로 치환한다.

### 5. Rails Controller를 master/detail로 분리한다
- master controller:
- `index` HTML/JSON 분기
- `batch_save`에서 insert/update/delete를 트랜잭션으로 처리
- 상세 조건 검색이 있으면 `joins(:details)` + `distinct` 적용
- detail controller:
- `index`는 master 기준 detail 목록만 반환
- `batch_save`는 master를 먼저 찾고 그 범위에서만 CRUD 처리
- FK는 서버에서 강제 주입한다 (`detail.code = header.code`)

### 6. 저장/검증 규칙을 통일한다
- Grid manager의 `blankCheckFields`, `validationRules`, `comparableFields`를 명시한다.
- `use_yn`은 enum(`Y`, `N`) 검증을 넣는다.
- 신규 기본값(`defaultRow`)을 명시한다.
- 성공 후 `refreshGrid("master")`로 재동기화한다.

## Guardrails

- 컨트롤러를 두껍게 만들지 않는다. 저장 규칙은 모델 검증과 컨트롤러 트랜잭션으로 분리한다.
- `private` 아래 메서드 들여쓰기를 프로젝트 스타일에 맞춘다.
- 메서드 상단의 짧은 early return 외에는 guard clause 남발을 피한다.
- 마스터 저장 전에는 디테일 저장/추가/삭제를 허용하지 않는다.
- 디테일 API에서 master scope 밖의 데이터 접근을 허용하지 않는다.

## Done Criteria
- 라우트가 `master` + nested `details` + 각 `batch_save` 구조를 갖는다.
- 화면 첫 진입, master 선택 변경, master 신규행 선택의 3상태에서 디테일 동작이 안전하다.
- master 저장 후 detail 목록과 선택 라벨이 최신 상태다.
- detail 저장 시 URL 템플릿 치환이 정확하다.
- 검색, 추가, 삭제, 저장을 각각 수동 검증한다.

## Resources
- [master-detail-scaffold.md](references/master-detail-scaffold.md): 바로 시작 가능한 파일 템플릿
- [master-detail-checklist.md](references/master-detail-checklist.md): 구현 누락 방지 체크리스트
