---
name: master-detail-screen-pattern
description: Build Rails WMS master-detail screens by reusing the `system/code` implementation pattern (ViewComponent + Stimulus BaseGridController + master/detail batch_save controllers). Use when creating a new 1:N management screen with two AG Grids, parent selection driven detail loading, and separate master/detail save flows.
---

# Master-Detail Screen Pattern

## Goal
- master-detail 화면을 항상 동일한 구조로 구현합니다.
- 공통 계약: `PageComponent + ERB + Stimulus + master/detail Controller`
- Contract Registry와 Contract Test로 일관성을 강제합니다.

## Standard Terms
- `Contract Registry`: `config/master_detail_screen_contracts.yml`
- `Contract Test`: `test/contracts/master_detail_pattern_contract_test.rb`
- `PR Gate`: `.github/PULL_REQUEST_TEMPLATE.md` + `.github/CODEOWNERS`

## Quick Start
1. 기준 구현 확인
- `app/components/system/code/page_component.rb`
- `app/components/system/code/page_component.html.erb`
- `app/javascript/controllers/system/code_grid_controller.js`
- `app/controllers/system/code_controller.rb`
- `app/controllers/system/code_details_controller.rb`
2. 신규 화면 파일 생성
- `<ns>/<module>/page_component.rb`
- `<ns>/<module>/page_component.html.erb`
- `<ns>/<module>_grid_controller.js`
- `<ns>/<master_controller>.rb`
- `<ns>/<detail_controller>.rb`
3. 스캐폴드 참고
- `references/master-detail-scaffold.md`
4. 체크리스트 점검
- `references/master-detail-checklist.md`

## Required Contract

### 1. Routes
- master resource에 `post :batch_save, on: :collection`이 있어야 합니다.
- nested detail resource에 `post :batch_save, on: :collection`이 있어야 합니다.
- detail URL 토큰(`:id` 또는 `:code`)은 라우트/JS에서 동일해야 합니다.

### 2. PageComponent
- 필수 메서드:
- `collection_path`, `member_path`, `detail_collection_path`
- `detail_grid_url`
- `master_batch_save_url`
- `detail_batch_save_url_template`
- `search_fields`, `master_columns`, `detail_columns`를 분리해야 합니다.

### 3. ERB
- `data-controller="<name>-grid"`를 사용합니다.
- `ag-grid:ready->...#registerGrid`를 연결합니다.
- 아래 value를 모두 주입합니다.
- `master-batch-url-value`
- `detail-batch-url-template-value`
- `detail-list-url-template-value`
- target은 `masterGrid`, `detailGrid`를 사용합니다.

### 4. Stimulus
- `BaseGridController`를 상속합니다.
- `gridRoles()`에 `master`, `detail`, `parentGrid: "master"`를 정의합니다.
- `detailLoader`를 구현합니다.
- `masterManagerConfig()`, `detailManagerConfig()`를 분리합니다.
- `saveMasterRows()`, `saveDetailRows()`를 구현합니다.
- detail 액션 전에 `blockIfPendingChanges(masterManager, "...")`를 호출합니다.
- detail 저장 URL은 `buildTemplateUrl()`로 생성합니다.

### 5. Controller
- master controller:
- `index`는 HTML/JSON 응답
- `batch_save`는 트랜잭션 기반 insert/update/delete 처리
- detail controller:
- `index`는 master scope 내부 조회
- `batch_save`는 master scope 내부 저장
- detail insert 시 FK를 서버에서 강제 주입합니다.

## Mandatory Gate (Required)
1. Contract Registry 등록
- 신규 화면을 `config/master_detail_screen_contracts.yml`에 추가
2. Contract Test 통과
- `ruby bin/rails test test/contracts/master_detail_pattern_contract_test.rb`
- 또는 `ruby bin/rails wm:contracts:master_detail`
3. PR Gate 통과
- `.github/PULL_REQUEST_TEMPLATE.md`의 Master-Detail 항목 확인
- `.github/CODEOWNERS` 승인 조건 확인
4. 위 항목 중 하나라도 실패하면 merge 금지

## Done Criteria
- 라우트 계약 충족 (`master + nested details + 각 batch_save`)
- 화면 계약 충족 (`data values + targets + save handlers`)
- 컨트롤러 계약 충족 (`master/detail 각각 index + batch_save`)
- Contract Registry 등록 완료
- Contract Test 통과 완료

## Resources
- [master-detail-scaffold.md](references/master-detail-scaffold.md)
- [master-detail-checklist.md](references/master-detail-checklist.md)
