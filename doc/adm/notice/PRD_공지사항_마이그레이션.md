# PRD - 시스템 공지사항(`system/notice`) 마이그레이션

## 1. 목적
- 원본 화면 `D:\project\soybean\src\views\system\notice\index.vue`를 분석하여 우리 시스템(Rails 8.1 + Hotwire + Stimulus + AG Grid) 구조로 마이그레이션한다.
- 메뉴 위치는 `system/notice`로 고정한다.
- `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md` 규약을 준수한다.
- 메뉴(`adm_menus`)와 사용자별 메뉴권한(`adm_user_menu_permissions`)을 함께 생성한다.

## 2. 범위
- 포함
1. 공지사항 목록/검색/등록/수정/삭제(단건, 다건)
2. 공지 분류, 제목, 내용, 상단고정, 게시여부, 게시기간 관리
3. 첨부파일 업로드(다중) 및 수정 화면에서 기존 첨부파일 목록 노출
4. `SYSTEM > 공지사항` 메뉴 생성
5. 기존 사용자 대상 `SYS_NOTICE` 메뉴권한 데이터 생성

- 제외
1. Vue 전용 컴포넌트(`EnhancedSearch`, `EnhancedAgGrid`, `Naive UI`) 직접 사용
2. 원본의 에디터 컴포넌트 그대로 이식(우리 시스템은 `textarea` 기반으로 처리)
3. 첨부파일 개별 삭제/정렬 고급 UI(초기 버전에서는 신규 업로드 중심)

## 3. 원본 소스 분석 요약

### 3.1 주요 기능
- 검색 조건: `categoryCode`, `title`, `isPublished`
- 목록: 분류, 상단고정 여부, 제목(클릭 시 수정), 게시여부, 등록일시, 조회수, 등록자
- 액션: 등록 모달, 수정 모달, 선택행 다중삭제
- 폼: 분류/제목/내용/상단고정/게시여부/첨부파일

### 3.2 마이그레이션 포인트
- 원본의 API 경로(`/api/system/notice`)는 우리 시스템의 `system/notice` REST + JSON 응답으로 변환
- 원본의 코드값(`NOTICE_CATEGORY`)은 우리 공통코드(`adm_code_headers/details`)로 관리
- 원본의 파일 API는 ActiveStorage 기반 첨부파일로 변환

## 4. 아키텍처 및 구현 방식
- 서버
1. `AdmNotice` 모델 + `adm_notices` 테이블
2. `System::NoticeController`에서 HTML/JSON, CRUD, 다건삭제 처리
3. ActiveStorage(`has_many_attached :attachments`)로 파일 관리

- 화면
1. `System::Notice::PageComponent` + `page_component.html.erb`
2. `Ui::SearchFormComponent`, `Ui::AgGridComponent`, `Ui::ResourceFormComponent`, `Ui::ModalShellComponent` 재사용
3. Stimulus `notice-crud` 컨트롤러로 모달/저장/다건삭제/파일 업로드 처리
4. AG Grid 렌더러 확장(공지 배지, 게시여부, 행 액션)

## 5. 데이터 모델 요구사항

### 5.1 공지사항 테이블
- 테이블: `adm_notices`
- 주요 컬럼
1. `category_code` (string, 50, not null)
2. `title` (string, 200, not null)
3. `content` (text, not null)
4. `is_top_fixed` (string(1), default `N`, not null)
5. `is_published` (string(1), default `Y`, not null)
6. `start_date` (date, nullable)
7. `end_date` (date, nullable)
8. `view_count` (integer, default 0, not null)
9. `create_by`, `create_time`, `update_by`, `update_time`

- 인덱스
1. `category_code`
2. `is_top_fixed`
3. `is_published`
4. `create_time`

### 5.2 첨부파일
- ActiveStorage 다중 첨부(`attachments`)
- 상세 조회 JSON에서 첨부파일 메타데이터(id, filename, url)를 제공

### 5.3 공통코드
- 코드헤더: `NOTICE_CATEGORY`
- 상세코드 예시: `GENERAL`, `SYSTEM`, `EVENT`

## 6. 기능 요구사항

### 6.1 조회
- `GET /system/notice` HTML: 화면 렌더
- `GET /system/notice.json`:
1. 검색조건(`q[category_code]`, `q[title]`, `q[is_published]`) 적용
2. 정렬: 상단고정 우선 + 최신 등록순

### 6.2 등록/수정
- `POST /system/notice`
- `PATCH /system/notice/:id`
- 유효성
1. 필수값: 분류, 제목, 내용
2. 값 제한: `is_top_fixed`, `is_published`는 `Y/N`
3. 날짜 검증: `end_date >= start_date` (둘 다 입력 시)

### 6.3 삭제
- 단건: `DELETE /system/notice/:id`
- 다건: `DELETE /system/notice/bulk_destroy` (ids 배열)

### 6.4 첨부파일
- 등록/수정 시 파일 업로드 가능(멀티 파일)
- 수정 모달에서 기존 첨부 목록을 링크로 확인 가능

## 7. UI/UX 요구사항
- 검색: 분류/제목/게시여부
- 목록 컬럼
1. 분류
2. 상단고정 여부(뱃지)
3. 제목
4. 게시여부(뱃지)
5. 등록일시
6. 조회수
7. 등록자
8. 액션(수정/삭제)
- 툴바 버튼
1. 등록
2. 선택삭제
- 모달 폼
1. 분류, 제목, 상단고정, 게시여부
2. 게시 시작일/종료일
3. 내용(`textarea`)
4. 첨부파일(`multiple`)

## 8. 메뉴/권한 요구사항
- 메뉴 생성
1. `menu_cd`: `SYS_NOTICE`
2. `parent_cd`: `SYSTEM`
3. `menu_url`: `/system/notice`
4. `tab_id`: `system-notice`
5. `menu_type`: `MENU`

- 사용자별 메뉴권한
1. 기존 모든 사용자(`adm_users`)에 대해 `SYS_NOTICE` 권한 레코드 생성
2. 이미 존재 시 `use_yn='Y'`로 갱신

## 9. 파일 설계
- 서버
1. `app/models/adm_notice.rb`
2. `app/controllers/system/notice_controller.rb`
3. `db/migrate/*_create_adm_notices.rb`
4. `db/migrate/*_add_system_notice_menu_and_permissions.rb`
5. `db/migrate/*_seed_notice_category_code.rb`

- 화면
1. `app/components/system/notice/page_component.rb`
2. `app/components/system/notice/page_component.html.erb`
3. `app/views/system/notice/index.html.erb`
4. `app/javascript/controllers/notice_crud_controller.js`
5. `app/javascript/controllers/ag_grid/renderers.js` (notice 렌더러 추가)
6. `app/javascript/controllers/index.js` (controller 등록)
7. `config/routes.rb` (`system/notice` 라우트)

## 10. 테스트 요구사항
- 모델
1. 필수값/날짜검증/YN 검증
- 컨트롤러
1. 목록 JSON 필터 동작
2. 등록/수정/삭제 응답
3. 다건삭제 동작
- 마이그레이션
1. 메뉴 생성 확인
2. 사용자별 메뉴권한 생성 확인

## 11. 완료 기준 (Definition of Done)
1. `system/notice`에서 검색/등록/수정/삭제(단건/다건)가 동작한다.
2. `SYSTEM > 공지사항` 메뉴가 생성되고 접근 가능하다.
3. `adm_user_menu_permissions`에 `SYS_NOTICE` 권한 데이터가 생성된다.
4. 공지 분류 코드(`NOTICE_CATEGORY`)가 생성되어 화면에서 선택 가능하다.
5. 기본 테스트 또는 최소 실행 검증을 통과한다.
