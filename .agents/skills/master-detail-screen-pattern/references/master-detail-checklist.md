# Master-Detail Checklist

## Standard Terms
- [ ] Contract Registry: `config/master_detail_screen_contracts.yml`
- [ ] Contract Test: `test/contracts/master_detail_pattern_contract_test.rb`
- [ ] PR Gate: `.github/PULL_REQUEST_TEMPLATE.md` + `.github/CODEOWNERS`

## Pre-Design
- [ ] 화면이 1:N master-detail 구조인지 확인했다.
- [ ] master PK, detail PK, detail FK를 확정했다.
- [ ] detail URL 토큰(`:id` 또는 `:code`)을 확정했고 전 구간에서 동일하게 사용한다.

## Routes
- [ ] master resource에 `post :batch_save, on: :collection`을 추가했다.
- [ ] nested detail resource에 `post :batch_save, on: :collection`을 추가했다.
- [ ] 라우트 파라미터와 controller finder 키가 일치한다.

## PageComponent
- [ ] `collection_path`, `member_path`, `detail_collection_path`를 구현했다.
- [ ] `detail_grid_url`을 구현했다.
- [ ] `master_batch_save_url`을 구현했다.
- [ ] `detail_batch_save_url_template`를 구현했다.
- [ ] `search_fields`, `master_columns`, `detail_columns`를 분리했다.
- [ ] master/detail 모두 `__row_status` 컬럼을 포함했다.

## ERB
- [ ] `data-controller="<name>-grid"`를 설정했다.
- [ ] `ag-grid:ready->...#registerGrid`를 연결했다.
- [ ] 아래 value를 모두 주입했다.
- [ ] `master-batch-url-value`
- [ ] `detail-batch-url-template-value`
- [ ] `detail-list-url-template-value`
- [ ] target을 `masterGrid`, `detailGrid`로 사용한다.

## Stimulus
- [ ] `BaseGridController`를 상속했다.
- [ ] `gridRoles()`에 `master`, `detail`, `parentGrid: "master"`를 정의했다.
- [ ] `detailLoader`를 구현했다.
- [ ] `masterManagerConfig()`, `detailManagerConfig()`를 구현했다.
- [ ] `saveMasterRows()`, `saveDetailRows()`를 구현했다.
- [ ] detail 액션 전에 `blockIfPendingChanges(masterManager, "...")`를 호출한다.
- [ ] detail batch URL 생성에 `buildTemplateUrl()`를 사용한다.
- [ ] `beforeSearchReset()`에서 selected/label/detail 상태를 초기화한다.

## Controller
- [ ] master `index`가 HTML/JSON 응답을 모두 지원한다.
- [ ] master `batch_save`가 트랜잭션 insert/update/delete를 처리한다.
- [ ] detail `index`가 master scope 내부 조회만 수행한다.
- [ ] detail `batch_save`가 master scope 내부 저장만 수행한다.
- [ ] detail insert 시 FK를 서버에서 강제 주입한다.
- [ ] 에러 응답을 `errors.uniq`로 정리한다.

## Mandatory Gate (Required)
- [ ] Contract Registry(`config/master_detail_screen_contracts.yml`)에 신규 화면을 등록했다.
- [ ] Contract Test를 통과했다.
- [ ] `ruby bin/rails test test/contracts/master_detail_pattern_contract_test.rb`
- [ ] 또는 `ruby bin/rails wm:contracts:master_detail`
- [ ] PR Gate를 통과했다.
- [ ] `.github/PULL_REQUEST_TEMPLATE.md`의 Master-Detail 항목을 점검했다.
- [ ] `.github/CODEOWNERS` 승인 조건을 확인했다.
- [ ] 하나라도 실패하면 merge하지 않는다.

## Validation
- [ ] master 저장이 정상 동작한다.
- [ ] master 선택 변경 시 detail 자동 조회/초기화가 정상 동작한다.
- [ ] master 미저장 변경 시 detail 조작 차단이 정상 동작한다.
- [ ] detail 저장이 정상 동작한다.
- [ ] 검색 후 selected/label/detail 상태 일관성이 유지된다.
- [ ] `ruby bin/rubocop`을 통과했다.
