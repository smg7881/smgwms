# PRD - WMS 작업장관리(`wm/workplace`) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\wm\workplace\index.vue`를 우리 시스템(Rails 8.1 + Hotwire + Stimulus + AG Grid) 구조로 이관한다.
- 메뉴 경로는 `wm/workplace`로 고정한다.
- 개발 규약은 `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`를 따른다.
- 메뉴 등록과 함께 사용자별 메뉴권한 데이터도 생성한다.

## 2. 범위
- 포함
1. 작업장 검색(작업장코드/명, 작업장유형, 사용여부)
2. AG Grid 인라인 편집 기반 목록 관리
3. 배치 저장(신규/수정/삭제 일괄 반영)
4. `WM > 작업장관리` 메뉴 생성
5. 사용자별 메뉴권한 데이터 생성(신규 메뉴 포함)

- 제외
1. 외부 Vue 컴포넌트(`EnhancedSearch`, `EnhancedAgGrid`) 직접 사용
2. 엑셀 업로드/다운로드
3. 사용자별 메뉴권한 관리 UI 신규 개발(데이터 생성/조회 기반까지만 반영)

## 3. 원본 화면 분석 요약
- 검색 파라미터
1. `workpl` (작업장코드/명 통합 검색)
2. `workplType`
3. `useYn`

- 목록 컬럼
1. `workplCd`, `workplNm`, `workplType`
2. `nationCd`, `zipCd`, `addr`, `addrDtl`
3. `telNo`, `useYn`

- 주요 동작
1. 행 추가(기본 `useYn=Y`)
2. 다중 선택 삭제
3. 변경 행 상태 추적 후 배치 저장
4. 그리드 컬럼 상태 초기화

## 4. 우리 시스템 이행 설계
- 페이지 컴포넌트: `Wm::Workplace::PageComponent`
- 화면 엔트리: `app/views/wm/workplace/index.html.erb`
- 컨트롤러: `Wm::WorkplaceController`
- 클라이언트 컨트롤러(Stimulus): `workplace-grid`
- 모델: `WmWorkplace`, `AdmUserMenuPermission`

## 5. 데이터 모델 요구사항

### 5.1 작업장 테이블
- 테이블: `wm_workplaces`
- 주요 컬럼
1. `workpl_cd` (string, unique, not null)
2. `workpl_nm` (string, not null)
3. `workpl_type` (string)
4. `nation_cd`, `zip_cd`, `addr`, `addr_dtl`, `tel_no`
5. `client_cd`, `prop_cd`, `fax_no`, `remk`
6. `use_yn` (string(1), default `Y`)
7. `create_by`, `create_time`, `update_by`, `update_time`

### 5.2 사용자별 메뉴권한 테이블
- 테이블: `adm_user_menu_permissions`
- 목적: 사용자-메뉴 단위 허용여부 데이터 저장
- 주요 컬럼
1. `user_id` (FK: `adm_users.id`)
2. `menu_cd` (string, not null)
3. `use_yn` (string(1), default `Y`)
4. `create_by`, `create_time`, `update_by`, `update_time`
- 유니크 인덱스: `[user_id, menu_cd]`

## 6. 기능 요구사항

### 6.1 조회
- `GET /wm/workplace` HTML: 화면 렌더링
- `GET /wm/workplace.json`: 검색 조건 기반 목록 반환
- `workpl`는 `workpl_cd`, `workpl_nm`에 OR 부분일치 검색

### 6.2 배치저장
- `POST /wm/workplace/batch_save`
- payload
1. `rowsToInsert`
2. `rowsToUpdate`
3. `rowsToDelete`
- 트랜잭션 기반 일괄 처리, 오류 시 전체 롤백

### 6.3 삭제 정책
- 신규 임시 행은 클라이언트에서 즉시 제거
- 기존 행 삭제는 `rowsToDelete`로 서버 반영

## 7. UI/UX 요구사항
- 검색영역: 공통 `Ui::SearchFormComponent` 사용
- 툴바: `행추가`, `행삭제`, `저장`, `새로고침`
- 그리드
1. 상태 컬럼(`__row_status`) 사용
2. 작업장유형/사용여부 select 편집 지원
3. 다중 선택 삭제 지원
- 이벤트/타깃/액션 네이밍은 `STIMULUS_COMPONENTS_GUIDE` 규약 준수

## 8. 메뉴/권한 요구사항
- `adm_menus`에 아래 메뉴 생성
1. 폴더: `WM` (`menu_type=FOLDER`, level 1)
2. 화면: `WM_WORKPLACE` (`menu_url=/wm/workplace`, `tab_id=wm-workplace`, level 2)
- 사용자별 메뉴권한(`adm_user_menu_permissions`)에 `WM_WORKPLACE` 레코드 생성
1. 기존 사용자 전원 기본 `use_yn='Y'`
2. 신규 사용자 권한은 별도 정책으로 관리(본 작업 범위 외)

## 9. 라우팅/파일 위치
- Route
1. `GET /wm/workplace`
2. `POST /wm/workplace/batch_save`
- 서버 파일
1. `app/controllers/wm/base_controller.rb`
2. `app/controllers/wm/workplace_controller.rb`
3. `app/models/wm_workplace.rb`
4. `app/models/adm_user_menu_permission.rb`
5. `app/components/wm/base_page_component.rb`
6. `app/components/wm/workplace/page_component.rb`
7. `app/components/wm/workplace/page_component.html.erb`
8. `app/views/wm/workplace/index.html.erb`
9. `app/javascript/controllers/workplace_grid_controller.js`

## 10. 테스트 요구사항
- 모델 테스트
1. `WmWorkplace` 필수값/코드값 검증
2. `AdmUserMenuPermission` 유니크 제약 검증
- 컨트롤러 테스트
1. `index` HTML/JSON 응답
2. `batch_save` insert/update/delete 성공
3. 비관리자 접근 제한

## 11. 완료 기준(Definition of Done)
1. `wm/workplace` 화면에서 검색/행추가/행삭제/저장이 정상 동작한다.
2. `adm_menus`에 `WM > 작업장관리` 메뉴가 생성되어 사이드바에서 접근 가능하다.
3. `adm_user_menu_permissions`에 신규 메뉴 권한 데이터가 생성된다.
4. 관련 테스트가 통과한다.
