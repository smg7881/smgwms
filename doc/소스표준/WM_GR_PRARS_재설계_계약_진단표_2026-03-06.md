# wm/gr_prars 재설계 계약 진단표 (2026-03-06)

## 범위
- 페이지: `app/components/wm/gr_prars/page_component.rb`, `app/components/wm/gr_prars/page_component.html.erb`
- 프론트: `app/javascript/controllers/wm/gr_prar_grid_controller.js`
- 백엔드: `app/controllers/wm/gr_prars_controller.rb`, `config/routes.rb`
- 계약 기준: `doc/소스표준/UI_GRID_재설계_실행_체크리스트.md`

## 종합 평가
- 완료: 12
- 부분완료: 4
- 미완료: 5
- 미확인(실행검증 필요): 2

핵심 판단:
1. 프론트(Stimulus) 계약은 대부분 충족됨
2. 백엔드는 `batch_save` 표준 계약 대신 커스텀 액션(`save_gr/confirm/cancel`) 구조
3. 테스트/계약게이트는 아직 미충족

## 체크리스트 진단

### A. PageComponent
1. `collection_path`, `member_path` 구현: 완료
- 근거: `app/components/wm/gr_prars/page_component.rb:10`, `:11`

2. master/detail URL template 주입: 부분완료
- 근거: `detail_list_url_template` 있음 (`page_component.rb:13`)
- 근거: ERB data 주입 있음 (`page_component.html.erb:4`)
- 이슈: 표준형 `master_batch_url`, `detail_batch_url_template` 계약은 없음

3. search/master/detail 컬럼 분리: 완료
- 근거: `search_fields` (`page_component.rb:41`), `master_columns` (`:98`), `detail_columns` (`:131`)

4. selected label 값 주입: 완료
- 근거: `selected_master_label` (`page_component.rb:37`), ERB target (`page_component.html.erb:60`)

### B. Stimulus
1. `BaseGridController` 상속: 완료
- 근거: `gr_prar_grid_controller.js:28`

2. `gridRoles()`에 master/detail 정의: 완료
- 근거: `gr_prar_grid_controller.js:59`

3. `detailLoader` 구현: 완료
- 근거: detail loader (`gr_prar_grid_controller.js:72`), exec loader (`:77`)

4. `masterManagerConfig`/`detailManagerConfig` 분리: 완료
- 근거: `gr_prar_grid_controller.js:97`, `:113`

5. `saveMasterRows`/`saveDetailRows` 구현: 완료
- 근거: `gr_prar_grid_controller.js:282`, `:290`

6. detail 액션 전 `blockIfPendingChanges`: 완료
- 근거: `blockDetailActionIfMasterChanged` (`gr_prar_grid_controller.js:407`) 및 저장/확정/취소 호출

7. `beforeSearchReset` 초기화: 완료
- 근거: `gr_prar_grid_controller.js:133`

### C. Controller
1. `index` html/json dual response: 완료
- 근거: `gr_prars_controller.rb:3`, `:5`, `:6`

2. `batch_save` 트랜잭션 처리: 미완료
- 근거: `save_gr`, `confirm`, `cancel` 커스텀 액션 구조(`gr_prars_controller.rb:42`, `:185`, `:211`)
- 근거: 라우트도 `batch_save` 없음 (`config/routes.rb:121..130`)

3. FK 서버 강제 주입: 부분완료
- 근거: 상세 대상은 `gr_prar.details.find_by(lineno:)`로 master scope 강제 (`gr_prars_controller.rb:56`)
- 이슈: 표준 batch_save payload 계약(`rowsToInsert/Update/Delete`)과는 다름

4. 에러 응답 `errors.uniq`: 완료
- 근거: `gr_prars_controller.rb:174`, `:315`

### D. 테스트/검증
1. 컨트롤러 테스트: 미완료
- 근거: `test/controllers`에 `gr_prars_controller_test.rb` 없음

2. 계약 테스트 통과: 미완료
- 근거: `config/master_detail_screen_contracts.yml`에 `wm_gr_prars` 등록 없음

3. `bin/rubocop` 통과: 미확인
4. `bin/brakeman --no-pager` 통과: 미확인

### E. 정리
1. 레거시 분기 제거: 부분완료
- 근거: 컨트롤러가 표준 `batch_save` 계열과 별개 액션을 유지

2. 중복 유틸 제거: 부분완료
- 근거: 공통화 시작했지만 화면별 커스텀 로직(탭+확정/취소) 다수 잔존

3. 문서 업데이트: 미완료
- 근거: 본 문서 작성 전까지 화면별 재설계 진단 문서 부재

## 우선 개선 항목 (P0/P1)

### P0
1. `wm/gr_prars`를 계약 레지스트리에 등록 (`config/master_detail_screen_contracts.yml`)
2. 컨트롤러 테스트 추가 (`test/controllers/wm/gr_prars_controller_test.rb`)
3. `save_gr` 입력/에러 계약을 공통 batch 응답 포맷과 정렬

### P1
1. 라우트를 점진적으로 `batch_save` 표준 계약과 병행 지원
2. 페이지 컴포넌트에 표준형 URL template naming 병행 주입
3. 탭(exec) 영역을 계약 확장 항목으로 문서화

## 결정 제안
- `wm/gr_prars`는 "완료된 표준 화면"이 아니라 "파일럿 전환 화면"으로 유지
- 다음 단계는 테스트/계약게이트 보강을 먼저 수행하고, 이후 라우트/컨트롤러 계약을 표준형으로 정렬
