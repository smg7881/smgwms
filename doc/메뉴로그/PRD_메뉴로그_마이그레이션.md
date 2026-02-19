# 메뉴로그 화면 마이그레이션 PRD (Soybean -> smgWms)

## 1. 목적
- 원본 Vue 화면 `D:\project\soybean\src\views\system\menu-log\index.vue`를 우리 시스템(Rails 8.1 + Hotwire + Stimulus + AG Grid) 구조로 이식한다.
- 기존 공통 규약(`doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`)을 준수해 검색/조회 화면을 구현한다.
- 메뉴 위치는 `system/menuLog` 기능에 대응되도록 Rails 경로 `system/menu_logs`로 제공한다.

## 2. 범위
- 포함
1. 메뉴로그 조회 화면(검색폼 + 목록 그리드)
2. 메뉴로그 조회 API(`GET /system/menu_logs.json`)
3. 메뉴로그 저장용 도메인 모델/테이블(`AdmMenuLog`)
4. 라우팅/페이지 컴포넌트 연결

- 제외
1. 메뉴 클릭 로그 수집 로직 자동화(다른 화면 이동 시 로그 생성)
2. 로그 수정/삭제 기능
3. 엑셀 다운로드/업로드

## 3. 화면 요구사항
### 3.1 레이아웃
1. 상단: SearchFormComponent
2. 하단: AgGridComponent (읽기 전용)
3. CRUD 모달/전용 Stimulus 컨트롤러는 생성하지 않음

### 3.2 검색 필드
1. 사용자 ID (`user_id`)
2. 사용자명 (`user_name`)
3. 메뉴 ID (`menu_id`)
4. 메뉴명 (`menu_name`)
5. IP 주소 (`ip_address`)
6. 접속 시작일시 (`access_time_from`, datetime-local)
7. 접속 종료일시 (`access_time_to`, datetime-local)

### 3.3 그리드 컬럼
1. 로그 ID (`id`)
2. 사용자 ID (`user_id`)
3. 사용자명 (`user_name`)
4. 메뉴 ID (`menu_id`)
5. 메뉴명 (`menu_name`)
6. 메뉴 경로 (`menu_path`)
7. 접속 시간 (`access_time`, datetime formatter)
8. IP 주소 (`ip_address`)
9. User Agent (`user_agent`)
10. 세션 ID (`session_id`)
11. 이전 페이지 (`referrer`)

## 4. 기능 요구사항
### 4.1 조회
1. HTML 요청 시 화면 렌더링
2. JSON 요청 시 검색조건이 반영된 목록 반환
3. 기본 정렬: `access_time DESC`, 보조 정렬 `id DESC`

### 4.2 검색 조건 처리
1. 문자열 검색은 부분일치(`LIKE`) 사용
2. `access_time_from` 입력 시 해당 시각 이상
3. `access_time_to` 입력 시 해당 시각 이하
4. 빈 값은 조건에서 제외

## 5. 데이터 요구사항
### 5.1 테이블
- 테이블명: `adm_menu_logs`
- 주요 컬럼
1. `user_id` (string)
2. `user_name` (string)
3. `menu_id` (string)
4. `menu_name` (string)
5. `menu_path` (string)
6. `access_time` (datetime, null: false)
7. `ip_address` (string)
8. `user_agent` (text)
9. `session_id` (string)
10. `referrer` (string)
11. `created_at`, `updated_at`

### 5.2 인덱스
1. `access_time`
2. `user_id`
3. `menu_id`
4. `session_id`

## 6. 아키텍처/규약 준수
1. 화면별 컨트롤러를 얇게 유지: 페이지 이벤트 로직 없이 공통 컴포넌트 조합으로 구성
2. `System::BasePageComponent` 상속 패턴 사용
3. 검색/그리드 구성은 PageComponent에서 선언
4. 뷰는 `turbo_frame_tag "main-content"` 규약 준수

## 7. 라우팅/파일 설계
1. Route: `resources :menu_logs, only: [:index]` under `namespace :system`
2. Controller: `System::MenuLogsController#index`
3. Component:
   - `app/components/system/menu_logs/page_component.rb`
   - `app/components/system/menu_logs/page_component.html.erb`
4. View: `app/views/system/menu_logs/index.html.erb`
5. Model: `app/models/adm_menu_log.rb`
6. Migration: `db/migrate/*_create_adm_menu_logs.rb`

## 8. 수용 기준
1. `/system/menu_logs` 접속 시 검색폼 + 그리드가 렌더링된다.
2. 검색 조건으로 조회 결과가 필터링된다.
3. 접속 시간 컬럼이 날짜/시간 형태로 노출된다.
4. 기존 `system/dept`, `system/menus`, `system/users`, `system/code` 화면 동작에 회귀가 없다.

## 9. 테스트/검증
1. 라우트 확인: `bin/rails routes | findstr menu_logs`
2. 수동 조회 확인: `/system/menu_logs`, `/system/menu_logs.json`
3. 범위 검색 확인: `q[access_time_from]`, `q[access_time_to]`
4. 회귀 확인: 기존 system 화면 진입 및 목록 조회
