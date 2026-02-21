# PRD - WMS 구역관리(`wm/area`) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\wm\area\index.vue`를 Rails 8.1 + Hotwire + Stimulus + AG Grid 구조로 이행한다.
- 메뉴 경로를 `WM > 구역관리`(`wm/area`)로 제공한다.
- 사용자별 메뉴 권한(`adm_user_menu_permissions`)을 생성해 비관리자 접근 제어를 적용한다.
- 개발 규약은 `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`를 준수한다.

## 2. 범위
- 포함
1. 검색 조건: 작업장, AREA명, 사용여부
2. AG Grid 인라인 편집 기반 목록 관리
3. 배치 저장(신규/수정/삭제)
4. WM 메뉴 및 하위 AREA 메뉴 생성
5. 전체 사용자 대상 `WM_AREA` 메뉴 권한 생성

- 제외
1. Vue 전용 컴포넌트(`EnhancedSearch`, `EnhancedAgGrid`, `SearchPopupCellEditor`) 직접 사용
2. 공통 팝업(`WorkplSlcPopup`) 신규 개발
3. Excel 업로드/다운로드

## 3. 원본 화면 분석 요약
- 검색 필드
1. `workplCd`(작업장)
2. `areaNm`(AREA명)
3. `useYn`(사용여부)

- 그리드 컬럼
1. `workplCd`, `workplNm`
2. `areaCd`, `areaNm`, `areaDesc`
3. `useYn`
4. `createBy`, `createTime`, `updateBy`, `updateTime`

- 주요 동작
1. 행추가(기본 `useYn=Y`)
2. 다중선택 삭제
3. 변경 상태 추적 후 배치 저장
4. 기존 PK(workplCd, areaCd) 수정 금지
5. 검색 조건의 작업장이 있으면 신규행 기본값으로 반영

## 4. Rails 이행 설계
- 서버
1. `Wm::AreaController#index` HTML/JSON 제공
2. `Wm::AreaController#batch_save` 배치 저장 제공
3. `WmArea` 모델에서 정규화/검증/감사필드 처리

- 클라이언트
1. `area-grid` Stimulus 컨트롤러로 행 상태(`__is_new`, `__is_updated`, `__is_deleted`) 관리
2. 기존 PK 수정 시 원복 + 경고 메시지 처리
3. `Ui::SearchFormComponent`, `Ui::GridToolbarComponent`, `Ui::GridActionsComponent`, `Ui::AgGridComponent` 재사용

- ViewComponent
1. `Wm::Area::PageComponent`에서 검색 필드/컬럼/URL 계약 정의
2. 화면 엔트리 `app/views/wm/area/index.html.erb`에서 PageComponent 렌더링

## 5. 데이터 모델 요구사항

### 5.1 테이블: `wm_areas`
- 주요 컬럼
1. `workpl_cd`(string, not null)
2. `area_cd`(string, not null)
3. `area_nm`(string, not null)
4. `area_desc`(string, optional)
5. `use_yn`(string(1), default `Y`)
6. `create_by`, `create_time`, `update_by`, `update_time`

- 인덱스
1. `(workpl_cd, area_cd)` unique
2. `workpl_cd`
3. `area_nm`
4. `use_yn`

### 5.2 메뉴/권한
- `adm_menus`
1. 상위 폴더 `WM`(없으면 생성)
2. 하위 메뉴 `WM_AREA` (`/wm/area`, `tab_id=wm-area`)

- `adm_user_menu_permissions`
1. 모든 사용자에 대해 `WM_AREA` 권한(`use_yn='Y'`) 생성

## 6. 기능 요구사항

### 6.1 조회
- `GET /wm/area` HTML: 화면 렌더링
- `GET /wm/area.json`: 검색 조건 기반 목록 반환
- 검색 조건
1. `workpl_cd` 정확 일치
2. `area_nm` 부분 일치
3. `use_yn` 일치

### 6.2 배치 저장
- `POST /wm/area/batch_save`
- Payload
1. `rowsToInsert`
2. `rowsToUpdate`
3. `rowsToDelete` (복합 PK: `workpl_cd`, `area_cd`)

- 처리 규칙
1. 트랜잭션 기반 일괄 처리
2. 오류 발생 시 전체 롤백
3. 수정 시 PK 변경 금지(서버는 PK 기준 조회 후 비PK 컬럼만 update)

## 7. UI/UX 요구사항
- 검색영역: `Ui::SearchFormComponent`
- 타이틀 좌측: `Ui::GridActionsComponent`(컬럼상태저장/초기화/엑셀다운로드)
- 툴바: `행추가`, `행삭제`, `저장`
- 그리드
1. 상태 컬럼(`__row_status`) 사용
2. `workpl_cd`는 Select 편집기로 제공, 선택 시 `workpl_nm` 자동 매핑
3. 기존 행의 `workpl_cd`, `area_cd` 수정 차단
4. `use_yn`은 Select 편집기(`Y/N`) 사용

## 8. 라우트/파일 위치
- Route
1. `GET /wm/area`
2. `POST /wm/area/batch_save`

- 서버 파일
1. `app/models/wm_area.rb`
2. `app/controllers/wm/area_controller.rb`
3. `app/components/wm/area/page_component.rb`
4. `app/components/wm/area/page_component.html.erb`
5. `app/views/wm/area/index.html.erb`

- 클라이언트 파일
1. `app/javascript/controllers/area_grid_controller.js`
2. `app/javascript/controllers/index.js` 등록

- DB 파일
1. `db/migrate/*_create_wm_areas.rb`
2. `db/migrate/*_add_wm_area_menu_and_permissions.rb`

## 9. 테스트 요구사항
- 모델 테스트
1. 필수값/정규화/`use_yn` 검증
2. 복합 유니크 검증

- 컨트롤러 테스트
1. `index` HTML/JSON 응답
2. `batch_save` insert/update/delete 성공
3. 비관리자 권한 유무에 따른 접근 제어

## 10. 완료 기준(Definition of Done)
1. `wm/area` 화면에서 조회/행추가/행삭제/저장이 정상 동작한다.
2. 기존 데이터의 `workpl_cd`, `area_cd`는 수정할 수 없다.
3. `adm_menus`에 `WM_AREA` 메뉴가 생성되어 사이드바에서 접근 가능하다.
4. `adm_user_menu_permissions`에 사용자별 `WM_AREA` 권한이 생성된다.
5. 관련 모델/컨트롤러 테스트가 추가된다.
