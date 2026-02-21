# [STD] 거래처관리 (Client Management) 시스템 구축

## 1. 목적
- 기존 화면정의(PRD) 요구사항을 현재 `smgWms` 코드 구조(Rails 8 + ViewComponent + AG Grid + Stimulus + 메뉴권한)로 실구현 가능한 형태로 반영한다.
- `STD` 네임스페이스에 거래처 마스터/하위정보(담당자, 작업장)와 변경이력 저장 구조를 제공한다.

## 2. 현재 시스템 반영 구조

### 2.1 라우팅
- `GET /std/clients` : 거래처관리 화면
- `GET /std/clients.json` : 거래처 목록
- `GET /std/clients/sections` : 거래처구분그룹 변경 시 거래처구분 목록 조회
- `POST /std/clients/batch_save` : 거래처 마스터 일괄 저장(신규/수정/비활성)
- `GET /std/clients/:id/contacts` : 거래처 담당자 목록
- `POST /std/clients/:id/batch_save_contacts` : 거래처 담당자 일괄 저장
- `GET /std/clients/:id/workplaces` : 거래처 작업장 목록
- `POST /std/clients/:id/batch_save_workplaces` : 거래처 작업장 일괄 저장

### 2.2 화면 구성
- 상단: 검색폼(`Ui::SearchFormComponent`)
- 중단: 거래처 마스터 그리드(AG Grid)
- 하단: 담당자/작업장 2개 하위 그리드(AG Grid)
- 마스터 행 선택 시 하위 2개 그리드 자동 로딩
- 마스터에 미저장 변경이 있으면 하위 저장/편집 차단

### 2.3 Stimulus 컨트롤러
- `client_grid_controller.js`
  - 마스터/담당자/작업장 3개 GridCrudManager 동시 제어
  - 행 선택 기반 하위 데이터 로딩
  - `거래처구분그룹 -> 거래처구분` 캐스케이드(select 옵션 재로딩)
  - 사업자번호 숫자 정규화(숫자 외 제거)

## 3. 데이터 모델

### 3.1 신규 테이블
- `std_bzac_mst` : 거래처 마스터
- `std_bzac_ofcr` : 거래처 담당자
- `std_bzac_workpl` : 거래처 작업장
- `std_cm04004` : 거래처 변경이력

### 3.2 핵심 비즈니스 룰
- 거래처코드(`bzac_cd`) 미입력 신규건은 8자리 자동채번
- 사업자번호(`bizman_no`)는 숫자 10자리 검증
- 대표거래처(`rpt_bzac_cd`)가 비어있는 경우 동일 사업자번호 중복 불가
- 삭제는 물리삭제가 아닌 `use_yn_cd = 'N'` 비활성 처리
- 수정 시 변경컬럼을 `std_cm04004`에 이력 적재

## 4. 공통코드 반영
- `STD_BZAC_SCTN_GRP` : 거래처구분그룹
- `STD_BZAC_SCTN` : 거래처구분 (`ref_code`로 그룹 연결)
- `STD_BZAC_KIND` : 거래처종류
- `STD_NATION` : 국가
- `CMM_USE_YN` : 공통 Y/N

## 5. 메뉴 및 권한
- 메뉴 폴더: `STD` (root folder)
- 메뉴: `STD_CLIENT` (`/std/clients`)
- 마이그레이션에서 사용자별 `adm_user_menu_permissions` 자동 부여
- 접근 제어: `Std::BaseController`에서 메뉴코드 기반 권한 검사

## 6. 구현 파일 요약
- 컨트롤러: `app/controllers/std/base_controller.rb`, `app/controllers/std/clients_controller.rb`
- 컴포넌트: `app/components/std/base_page_component.rb`, `app/components/std/client/page_component.rb`, `app/components/std/client/page_component.html.erb`
- 뷰: `app/views/std/clients/index.html.erb`
- 모델: `app/models/std_bzac_mst.rb`, `app/models/std_bzac_ofcr.rb`, `app/models/std_bzac_workpl.rb`, `app/models/std_cm04004.rb`
- JS: `app/javascript/controllers/client_grid_controller.js`, `app/javascript/controllers/index.js`
- 라우트: `config/routes.rb`
- 마이그레이션: `db/migrate/20260221100000_create_std_client_management_tables.rb`, `db/migrate/20260221101000_seed_std_client_codes.rb`, `db/migrate/20260221102000_add_std_client_menu_and_permissions.rb`

## 7. 이후 확장 포인트
- 화면 원본처럼 하단 탭(기본정보/추가정보) 폼 기반 편집 UI로 확장
- 팝업 연동 검색 필드(관리법인/국가/사원/우편번호 등) 추가
- 담당자/작업장 soft-delete 전환 및 이력화
- 시스템 간 IF 항목(`if_yn_cd`, `customsEDICd` 등) 상세 검증 강화
