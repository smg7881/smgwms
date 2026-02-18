# 시스템 보안/테스트 강화 작업 정리 (2026-02-18)

## 개요
- 목적:
  - 시스템 관리 API의 인가(Authorization) 누락 보완
  - 사용자 응답 JSON의 민감정보 노출 차단
  - 시스템 컨트롤러 테스트 공백 보완
- 범위:
  - `app/controllers/system/*`
  - `app/controllers/application_controller.rb`
  - `test/controllers/system/*`
  - `test/fixtures/users.yml`

## 문제점(작업 전)
- 시스템 네임스페이스(`system/*`)는 로그인만 되면 접근 가능한 상태였음.
- `System::UsersController`의 `user.as_json` 전체 반환으로 `password_digest` 노출 위험이 있었음.
- `users`, `code`, `code_details` 컨트롤러 테스트가 없어 권한/보안 회귀를 잡기 어려웠음.

## 적용 내용

## 1) 관리자 인가 공통화
- `System::BaseController` 신설:
  - `app/controllers/system/base_controller.rb`
  - `before_action :require_admin!` 적용
- 시스템 컨트롤러 상속 변경:
  - `app/controllers/system/dept_controller.rb`
  - `app/controllers/system/menus_controller.rb`
  - `app/controllers/system/users_controller.rb`
  - `app/controllers/system/code_controller.rb`
  - `app/controllers/system/code_details_controller.rb`

## 2) 인가 메서드 추가
- `app/controllers/application_controller.rb`
  - `admin?` 추가 (`Current.user&.role_cd == "ADMIN"`)
  - `require_admin!` 추가
    - HTML 요청: 루트로 리다이렉트 + 경고 메시지
    - 그 외 요청(JSON 등): `403 Forbidden`

## 3) 사용자 JSON 민감정보 차단
- `app/controllers/system/users_controller.rb`
  - `user_json`을 화이트리스트 방식으로 변경
  - 포함 필드만 명시적으로 직렬화
  - `password_digest` 미노출 보장

## 4) 테스트 보강
- 신규 테스트 추가:
  - `test/controllers/system/users_controller_test.rb`
  - `test/controllers/system/code_controller_test.rb`
  - `test/controllers/system/code_details_controller_test.rb`
- 기존 테스트 보완:
  - `test/controllers/system/dept_controller_test.rb`
  - `test/controllers/system/menus_controller_test.rb`
  - 관리자 로그인 기준으로 변경, 비관리자 접근 시 `403` 검증 케이스 추가
- 픽스처 보강:
  - `test/fixtures/users.yml`
  - `admin` 사용자(ROLE: `ADMIN`) 추가
  - `one` 사용자 ROLE을 `USER`로 명시

## 검증 결과
- 실행 명령:
  - `ruby bin/rubocop --cache false`
  - `ruby bin/rails test`
- 결과:
  - RuboCop: 위반 없음
  - 테스트: `85 runs, 213 assertions, 0 failures, 0 errors, 0 skips`

## 참고
- `bundler-audit`는 로컬 권한 문제로 advisory DB 다운로드 실패 이력이 있어 별도 권한 정리가 필요함.

## 추가 조치 (시스템 메뉴 미조회 이슈)

### 증상
- 관리자 로그인 후에도 좌측 사이드바의 `시스템` 하위 메뉴가 보이지 않는 현상이 발생.

### 원인 분석
- 실행 DB 기준 `admin@example.com` 사용자의 `role_cd`가 비어 있어 관리자 인가가 통과되지 않았음.
- `db/seeds.rb`가 기존 관리자 계정을 생성/유지할 때 `role_cd`를 강제로 보정하지 않아 환경에 따라 권한 누락이 발생할 수 있었음.

### 적용한 조치
- `db/seeds.rb` 보강:
  - `admin@example.com` 생성 시 `role_cd: "ADMIN"`, `user_id_code`, `user_nm` 기본값 설정.
  - 기존 관리자 계정이 이미 있어도 `update!`로 `role_cd: "ADMIN"`을 보정하도록 추가.
- `db/seeds/adm_menus.rb` 재정비:
  - `SYSTEM` 루트 폴더와 하위 메뉴(`SYS_MENU`, `SYS_DEPT`, `SYS_USER`, `SYS_CODE`)를 항상 `use_yn: "Y"`로 생성/보정.
  - 한글 라벨/아이콘/정렬값을 명시해 일관된 사이드바 구성을 보장.
- 사이드바 렌더링 보강:
  - `app/helpers/sidebar_helper.rb`: `SYSTEM` 폴더 기본 펼침 처리.
  - `app/views/shared/_sidebar.html.erb`:
    - 동적 메뉴 루트가 `MENU` 타입이어도 렌더되도록 보강.
    - 동적 메뉴 로딩 실패 시, 관리자에게 시스템 4개 메뉴를 fallback으로 표시.

### 실행/검증
- 실행 명령:
  - `ruby bin/rails db:seed`
  - `ruby bin/rails runner "u=User.find_by(email_address:'admin@example.com'); p [u&.email_address, u&.role_cd, u&.user_id_code, u&.user_nm]"`
  - `ruby bin/rails runner "p AdmMenu.where(menu_cd:'SYSTEM').pluck(:menu_cd,:menu_type,:parent_cd,:use_yn); p AdmMenu.where(parent_cd:'SYSTEM').order(:sort_order,:menu_cd).pluck(:menu_cd,:menu_nm,:menu_url,:tab_id,:use_yn)"`
- 확인 결과:
  - 관리자 계정: `admin@example.com / ADMIN / admin01 / 관리자`
  - 시스템 하위 메뉴 4개 모두 조회 가능 상태로 DB 보정 완료.

### 운영 체크 포인트
- 관리자 계정으로 로그인했는데 시스템 메뉴가 보이지 않으면 우선 `role_cd`를 점검.
- 환경(로컬/도커/다른 DB 파일)마다 시드를 별도로 실행해야 동일한 메뉴/권한 상태가 유지됨.
