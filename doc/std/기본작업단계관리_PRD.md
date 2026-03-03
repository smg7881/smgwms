# 기본작업단계관리 PRD (우리 시스템 적용안)

## 1. 문서 목적
- 원본 기준:  
  `LogisT-CM-DS02(화면설계서-V1.0)-기본작업단계관리.pdf`  
  `LogisT-CM-AN13(화면정의서-V1.0)_기본작업단계관리_20100628.pdf`
- 목적: 원본 요구를 현재 Rails/Hotwire 구조에 맞춰 `std` 도메인으로 구현한다.
- 구현 패턴: **부서관리 화면 패턴(그리드 + 모달 CRUD)** 을 따른다.

## 2. 메뉴/권한
- 메뉴 경로: `기준정보 > 코드관리 > 기준작업관리 > 기준작업경로관리 > 기본작업단계관리`
- 메뉴코드(신규): `STD_WORK_STEP`
- 부모 메뉴코드: `STD_WORK_ROUTING`
- 메뉴 URL: `/std/work_steps`
- 권한: `Std::BaseController#require_menu_permission!` 기준으로 `adm_user_menu_permissions.menu_cd = STD_WORK_STEP`

## 3. 기능 범위
- 기본작업단계 마스터 데이터 CRUD
- 조회 조건
  - 작업단계코드
  - 작업단계명
  - 사용여부
- 등록/수정 항목
  - 작업단계코드
  - 작업단계명
  - 작업단계 Level1
  - 작업단계 Level2
  - 사용여부
  - 정렬순서
  - 내용
  - 비고
- 감사 정보(등록자/등록일시/수정자/수정일시)는 시스템 자동 관리

## 4. 화면 요구사항
### 4.1 조회 영역
- `작업단계코드` 입력
- `작업단계명` 입력
- `사용여부` 셀렉트 (`CMM_USE_YN`, 전체 포함)

### 4.2 목록 그리드
- 컬럼
  - 작업단계코드
  - 작업단계명
  - 작업단계Level1
  - 작업단계Level2
  - 정렬순서
  - 사용여부
  - 비고
  - 수정자/수정일시/생성자/생성일시
  - 작업(수정/삭제 렌더러 버튼)
- 정렬 기본값: `sort_seq`, `work_step_cd`

### 4.3 상세 입력(모달)
- 필수
  - 작업단계코드
  - 작업단계명
  - 작업단계Level1
  - 작업단계Level2
  - 사용여부
- 선택
  - 정렬순서
  - 내용
  - 비고
- 생성 모드 기본값
  - 사용여부 = `Y`
  - 정렬순서 = `0`
- 수정 모드
  - 작업단계코드는 ReadOnly

## 5. 업무 규칙
- 삭제는 물리삭제가 아닌 **논리삭제**로 처리 (`use_yn_cd = 'N'`)
- `작업단계Level2`는 선택한 `작업단계Level1`에 매핑되는 코드만 허용
  - 코드 소스
    - Level1: 공통코드 `07`
    - Level2: 공통코드 `08` (상위코드 매핑 `upper_detail_code`)
- 코드/명칭 중복 방지
  - `work_step_cd` 유니크

## 6. 데이터 모델
### 6.1 신규 테이블
- 테이블명: `std_work_steps`
- 컬럼
  - `work_step_cd` string(30), not null, unique
  - `work_step_nm` string(150), not null
  - `work_step_level1_cd` string(30), not null
  - `work_step_level2_cd` string(30), not null
  - `sort_seq` integer, not null, default 0
  - `conts_cd` text
  - `rmk_cd` string(500)
  - `use_yn_cd` string(1), not null, default `Y`
  - `create_by` string(50)
  - `create_time` datetime
  - `update_by` string(50)
  - `update_time` datetime
- 인덱스
  - unique: `work_step_cd`
  - normal: `work_step_nm`, `use_yn_cd`, `work_step_level1_cd`, `work_step_level2_cd`

## 7. API/라우팅
- `GET /std/work_steps` (HTML/JSON)
- `POST /std/work_steps`
- `PATCH /std/work_steps/:id`
- `DELETE /std/work_steps/:id` (논리삭제)

## 8. 프런트엔드 구현 기준
- 참조 문서: `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md`
- 구현 패턴: 부서관리와 동일한 modal CRUD
  - `PageComponent`에서 search/grid/form 계약 정의
  - Stimulus CRUD 컨트롤러(`BaseGridController + ModalMixin`) 사용
  - AG Grid 액션 렌더러 이벤트(`edit/delete`) 수신

## 9. 수용 기준
- 메뉴에서 `기본작업단계관리` 진입 가능
- 조회/등록/수정/논리삭제 동작
- Level1 변경 시 Level2 선택값 검증/초기화
- 감사필드 자동 반영
- 권한 없는 사용자는 접근 불가
- 컨트롤러 테스트 통과
