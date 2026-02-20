# PRD - WMS 보관존관리(`wm/zone`) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\wm\zone\index.vue`를 Rails 8.1 + Hotwire + Stimulus + AG Grid 구조로 이행한다.
- 메뉴 경로를 `WM > 보관존관리`(`wm/zone`)로 제공한다.
- 사용자별 메뉴 권한(`adm_user_menu_permissions`)을 생성해 비관리자 접근 제어를 적용한다.
- 개발 규약은 `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`를 준수한다.

## 2. 범위
- 포함
1. 검색 조건: 작업장, 구역, Zone 코드/명, 사용여부
2. 좌측 구역(Area) 마스터 그리드 조회
3. 우측 Zone 디테일 그리드 CRUD(행추가/행삭제/저장)
4. 배치 저장(신규/수정/삭제)
5. `WM_ZONE` 메뉴 생성 및 사용자별 메뉴 권한 생성

- 제외
1. Vue 전용 컴포넌트(`EnhancedSearch`, `EnhancedAgGrid`) 직접 사용
2. Excel 업로드/다운로드
3. 사용자별 메뉴권한 관리 UI 추가 개발

## 3. 원본 화면 분석 요약
- 검색 필드
1. `workplCd` (작업장, 필수)
2. `areaCd` (구역, 선택)
3. `zoneCd` (Zone 코드/명 검색)
4. `useYn` (기본 `Y`)

- 마스터(좌측) 컬럼
1. `workplNm`
2. `areaCd`
3. `areaNm`

- 디테일(우측) 컬럼
1. `workplCd`(hidden)
2. `areaCd`(hidden)
3. `zoneCd`(신규만 수정 가능)
4. `zoneNm`
5. `zoneDesc`
6. `useYn`
7. `updateBy`, `updateTime`

- 주요 동작
1. 검색 시 좌측 Area 목록 재조회
2. 좌측 Area 선택 시 우측 Zone 목록 조회
3. 우측 그리드에서 CRUD 후 배치 저장
4. 기존 Zone 코드 수정 금지

## 4. Rails 이행 설계
- 서버
1. `Wm::ZoneController#index` HTML/JSON (좌측 Area 목록)
2. `Wm::ZoneController#zones` JSON (우측 Zone 목록)
3. `Wm::ZoneController#batch_save` 배치 저장
4. `WmZone` 모델에서 정규화/검증/감사필드 처리

- 클라이언트
1. `zone-grid` Stimulus 컨트롤러로 마스터 선택/디테일 CRUD/상태 추적 관리
2. 좌측 그리드 이벤트(`rowClicked`, `cellFocused`) 기반 우측 목록 로딩
3. 기존 `zone_cd` 수정 차단

- ViewComponent
1. `Wm::Zone::PageComponent`에서 검색 필드/좌우 컬럼/URL 계약 정의
2. 화면 엔트리 `app/views/wm/zone/index.html.erb`에서 렌더링

## 5. 데이터 모델 요구사항

### 5.1 테이블: `wm_zones`
- 주요 컬럼
1. `workpl_cd`(string, not null)
2. `area_cd`(string, not null)
3. `zone_cd`(string, not null)
4. `zone_nm`(string, not null)
5. `zone_desc`(string, optional)
6. `use_yn`(string(1), default `Y`)
7. `create_by`, `create_time`, `update_by`, `update_time`

- 인덱스
1. `(workpl_cd, area_cd, zone_cd)` unique
2. `(workpl_cd, area_cd)`
3. `zone_nm`
4. `use_yn`

### 5.2 메뉴/권한
- `adm_menus`
1. 상위 폴더 `WM`(없으면 생성)
2. 하위 메뉴 `WM_ZONE` (`/wm/zone`, `tab_id=wm-zone`)

- `adm_user_menu_permissions`
1. 모든 사용자에 대해 `WM_ZONE` 권한(`use_yn='Y'`) 생성

## 6. 기능 요구사항

### 6.1 조회
- `GET /wm/zone` HTML: 화면 렌더링
- `GET /wm/zone.json`: 좌측 Area 목록 조회
- `GET /wm/zone/zones.json`: 우측 Zone 목록 조회

- 조회 조건
1. Area 목록: `workpl_cd`, `area_cd`, `use_yn`
2. Zone 목록: `workpl_cd`, `area_cd`(필수), `zone_cd`(코드/명 부분일치), `use_yn`

### 6.2 배치 저장
- `POST /wm/zone/batch_save`
- Payload
1. `rowsToInsert`
2. `rowsToUpdate`
3. `rowsToDelete` (복합 PK: `workpl_cd`, `area_cd`, `zone_cd`)

- 처리 규칙
1. 트랜잭션 기반 일괄 처리
2. 오류 발생 시 전체 롤백
3. 수정 시 PK(workpl_cd, area_cd, zone_cd) 변경 금지

## 7. UI/UX 요구사항
- 검색영역: `Ui::SearchFormComponent`
- 좌우 분할 레이아웃(좌: Area 목록, 우: 보관 Zone 관리)
- 우측 툴바: `행추가`, `행삭제`, `저장`
- 타이틀 좌측에 `Ui::GridActionsComponent` 적용
- 우측 그리드
1. 상태 컬럼(`__row_status`) 사용
2. 신규행 기본값: 선택된 `workpl_cd`, `area_cd`, `use_yn='Y'`
3. 기존 `zone_cd` 수정 차단

## 8. 라우트/파일 위치
- Route
1. `GET /wm/zone`
2. `GET /wm/zone/zones`
3. `POST /wm/zone/batch_save`

- 서버 파일
1. `app/models/wm_zone.rb`
2. `app/controllers/wm/zone_controller.rb`
3. `app/components/wm/zone/page_component.rb`
4. `app/components/wm/zone/page_component.html.erb`
5. `app/views/wm/zone/index.html.erb`

- 클라이언트 파일
1. `app/javascript/controllers/zone_grid_controller.js`
2. `app/javascript/controllers/index.js` 등록

- DB 파일
1. `db/migrate/*_create_wm_zones.rb`
2. `db/migrate/*_add_wm_zone_menu_and_permissions.rb`

## 9. 테스트 요구사항
- 모델 테스트
1. 필수값/정규화/`use_yn` 검증
2. 복합 유니크 검증
3. 상위 Area 존재 검증

- 컨트롤러 테스트
1. `index` HTML/JSON 응답
2. `zones` 조회 응답
3. `batch_save` insert/update/delete 성공
4. 비관리자 권한 유무에 따른 접근 제어

## 10. 완료 기준(Definition of Done)
1. `wm/zone` 화면에서 검색/Area선택/Zone CRUD/저장이 정상 동작한다.
2. 기존 Zone 데이터의 PK 수정이 차단된다.
3. `adm_menus`에 `WM_ZONE` 메뉴가 생성되어 사이드바 접근이 가능하다.
4. `adm_user_menu_permissions`에 사용자별 `WM_ZONE` 권한이 생성된다.
5. 관련 모델/컨트롤러 테스트가 추가된다.
