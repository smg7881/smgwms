# Master-Detail Checklist

## 사전 결정
- [ ] 화면이 1:N 구조인지 확인한다.
- [ ] master PK, detail PK, detail FK를 확정한다.
- [ ] detail URL 템플릿 치환 키(`:id`/`:code`)를 확정한다.

## 라우트
- [ ] master 리소스에 `batch_save`를 추가한다.
- [ ] nested detail 리소스와 detail `batch_save`를 추가한다.
- [ ] `param:` 값과 controller `find_*` 로직이 일치하는지 확인한다.

## PageComponent
- [ ] `collection_path`, `member_path`, `detail_collection_path`를 구현한다.
- [ ] `detail_grid_url`을 `selected_*` 존재 조건으로 구현한다.
- [ ] `master_batch_save_url`, `detail_batch_save_url_template`를 구현한다.
- [ ] `search_fields`, `master_columns`, `detail_columns`를 분리한다.
- [ ] master/detail 모두 상태 컬럼(`__row_status`)을 둔다.

## ERB
- [ ] 최상위 `data-controller`와 `ag-grid:ready` 바인딩을 설정한다.
- [ ] `masterBatchUrl`, `detailBatchUrlTemplate`, `detailListUrlTemplate`, `selected` value를 주입한다.
- [ ] master grid target=`masterGrid`, detail grid target=`detailGrid`를 맞춘다.
- [ ] selected 라벨 target을 렌더링한다.

## Stimulus
- [ ] `BaseGridController`를 상속한다.
- [ ] `gridRoles()`에 `master`/`detail` 역할을 선언한다.
- [ ] detail role에 `parentGrid`, `onMasterRowChange`, `detailLoader`를 구현한다.
- [ ] `masterManagerConfig()`와 `detailManagerConfig()`를 분리한다.
- [ ] 디테일 액션 전에 `blockIfPendingChanges(masterManager, "...")`를 호출한다.
- [ ] detail 저장 URL 치환에 `buildTemplateUrl()`을 사용한다.
- [ ] `beforeSearchReset()`에서 `selected` 상태/라벨/디테일 초기화를 수행한다.

## Controller
- [ ] master `index`는 HTML/JSON 응답을 모두 제공한다.
- [ ] master `batch_save`는 트랜잭션 + insert/update/delete 분리 메서드를 사용한다.
- [ ] detail `index`는 master 기준 scope로만 조회한다.
- [ ] detail `batch_save`는 master 강제 조회(`master!`) 후 처리한다.
- [ ] detail insert에서 FK를 서버에서 강제 주입한다.
- [ ] 오류는 `errors.uniq`로 정리해 반환한다.

## 검증
- [ ] master 신규/수정/삭제 저장을 확인한다.
- [ ] master 선택 변경 시 detail 자동 재조회(또는 초기화)를 확인한다.
- [ ] master 미저장 상태에서 detail 작업 차단을 확인한다.
- [ ] detail 신규/수정/삭제 저장을 확인한다.
- [ ] 검색 후 선택/라벨 상태가 깨지지 않는지 확인한다.
- [ ] `bin/rubocop`와 관련 테스트를 실행한다.
