# PRD - WMS 로케이션관리(`wm/location`) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\wm\location\index.vue`를 Rails 8.1 + Hotwire + Stimulus + AG Grid 구조로 이관한다.
- 메뉴 경로를 `WM > 로케이션관리` (`/wm/location`)로 구성한다.
- 사용자별 메뉴 권한(`adm_user_menu_permissions`)을 자동 생성한다.
- 개발 시 `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md` 규약을 준수한다.

## 2. 범위
- 포함
1. 검색 조건: 작업장, AREA, ZONE, 로케이션코드, 구분, 사용여부
2. AG Grid 기반 로케이션 목록 조회 및 인라인 편집
3. 배치 저장(신규/수정/삭제)
4. 작업장/AREA/ZONE 연쇄 선택(작업장 변경 시 AREA 초기화, AREA 변경 시 ZONE 초기화)
5. 메뉴 `WM_LOCATION` 생성 및 전 사용자 권한 생성

- 제외
1. Vue 전용 컴포넌트(`EnhancedSearch`, `EnhancedAgGrid`) 직접 사용
2. 기존 원본 API(`/api/v1/wm/location`) 호환 레이어 구현
3. 엑셀 업로드/다운로드

## 3. 원본 화면 분석 요약
- 검색 필드
1. `workplCd`
2. `areaCd`
3. `zoneCd`
4. `locCd`
5. `locClassCd`
6. `useYn`

- 그리드 컬럼
1. `workplCd`, `areaCd`, `zoneCd` (읽기 전용)
2. `locCd` (신규행만 수정 가능)
3. `locNm`
4. `locClassCd` (`STORAGE`, `PICKING`, `MOVE`)
5. `locTypeCd` (`NORMAL`, `RACK`, `FLOOR`)
6. `widthLen`, `vertLen`, `heightLen`, `maxWeight`, `maxCbm`
7. `useYn`
8. `hasStock` (읽기 전용)
9. `updateTime`

- 핵심 동작
1. 행추가 시 검색 조건의 작업장/AREA/ZONE 기본값 주입
2. 재고 보유(`hasStock = 'Y'`) 행은 삭제 금지
3. 배치 저장 시 `rowsToInsert`, `rowsToUpdate`, `rowsToDelete` 전송

## 4. 이관 설계
- 서버
1. `Wm::LocationController#index` HTML/JSON
2. `Wm::LocationController#areas` (작업장 기준 AREA 옵션 JSON)
3. `Wm::LocationController#zones` (작업장+AREA 기준 ZONE 옵션 JSON)
4. `Wm::LocationController#batch_save` (배치 저장)
5. `WmLocation` 모델로 유효성/감사필드/정규화 처리

- 클라이언트
1. `location-grid` Stimulus 컨트롤러에서 행 상태(`__is_new`, `__is_updated`, `__is_deleted`) 관리
2. 기존 PK 수정 차단(`workpl_cd`, `area_cd`, `zone_cd`, `loc_cd`)
3. 검색 select 연쇄 로딩(작업장 -> AREA -> ZONE)

- ViewComponent
1. `Wm::Location::PageComponent`에서 검색/컬럼/URL 계약 정의
2. `app/views/wm/location/index.html.erb`에서 엔트리 렌더링

## 5. 데이터 모델 요구사항

### 5.1 테이블 `wm_locations`
- 주요 컬럼
1. `workpl_cd` (string, not null)
2. `area_cd` (string, not null)
3. `zone_cd` (string, not null)
4. `loc_cd` (string, not null)
5. `loc_nm` (string, not null)
6. `loc_class_cd` (string, optional)
7. `loc_type_cd` (string, optional)
8. `width_len`, `vert_len`, `height_len`, `max_weight`, `max_cbm` (decimal, optional)
9. `has_stock` (string(1), default `N`)
10. `use_yn` (string(1), default `Y`)
11. `create_by`, `create_time`, `update_by`, `update_time`

- 인덱스
1. `(workpl_cd, area_cd, zone_cd, loc_cd)` unique
2. `(workpl_cd, area_cd, zone_cd)`
3. `loc_nm`
4. `use_yn`
5. `has_stock`

### 5.2 메뉴/권한
- `adm_menus`
1. 상위 폴더 `WM`이 없으면 생성
2. 하위 메뉴 `WM_LOCATION` 생성 (`/wm/location`, `tab_id=wm-location`)

- `adm_user_menu_permissions`
1. 전체 사용자 대상 `WM_LOCATION` 권한(`use_yn='Y'`) 생성

## 6. 기능 요구사항

### 6.1 조회
- `GET /wm/location` HTML: 화면 렌더링
- `GET /wm/location.json`: 검색조건 기반 로케이션 목록
- `GET /wm/location/areas.json`: 작업장 기준 AREA 목록
- `GET /wm/location/zones.json`: 작업장+AREA 기준 ZONE 목록

### 6.2 배치 저장
- `POST /wm/location/batch_save`
- Payload
1. `rowsToInsert`
2. `rowsToUpdate`
3. `rowsToDelete`

- 처리 규칙
1. 트랜잭션 기반 일괄 처리
2. 오류 발생 시 전체 롤백
3. 재고 보유 로케이션 삭제 요청 시 에러 반환

## 7. UI/UX 요구사항
- 검색영역: `Ui::SearchFormComponent`
- 그리드: `Ui::AgGridComponent` + `Ui::GridToolbarComponent` + `Ui::GridActionsComponent`
- 버튼: `행추가`, `행삭제`, `저장`
- `__row_status` 컬럼으로 행 상태 표시
- 검색 select 연쇄 로딩은 Stimulus에서 이벤트 기반 처리

## 8. 파일 위치
- Route
1. `GET /wm/location`
2. `GET /wm/location/areas`
3. `GET /wm/location/zones`
4. `POST /wm/location/batch_save`

- 서버 파일
1. `app/models/wm_location.rb`
2. `app/controllers/wm/location_controller.rb`
3. `app/components/wm/location/page_component.rb`
4. `app/components/wm/location/page_component.html.erb`
5. `app/views/wm/location/index.html.erb`

- 클라이언트 파일
1. `app/javascript/controllers/location_grid_controller.js`
2. `app/javascript/controllers/index.js`

- DB 파일
1. `db/migrate/*_create_wm_locations.rb`
2. `db/migrate/*_add_wm_location_menu_and_permissions.rb`

## 9. 테스트 요구사항
- 모델 테스트
1. 필수값, 코드값, 수치값 검증
2. 복합 유니크 검증
3. 상위 ZONE 존재 검증

- 컨트롤러 테스트
1. `index` HTML/JSON 응답
2. `areas`, `zones` JSON 응답
3. `batch_save` insert/update/delete 성공
4. `has_stock='Y'` 삭제 차단
5. 비관리자 권한 유무에 따른 접근 제어

## 10. 완료 기준 (Definition of Done)
1. `/wm/location` 화면에서 검색/행추가/행삭제/저장이 정상 동작한다.
2. 검색의 작업장/AREA/ZONE 연쇄 선택이 정상 동작한다.
3. 재고 보유 로케이션은 삭제되지 않는다.
4. `adm_menus`에 `WM_LOCATION` 메뉴가 생성되어 접근 가능하다.
5. `adm_user_menu_permissions`에 사용자별 `WM_LOCATION` 권한이 생성된다.
6. 관련 테스트가 통과한다.
