# 기본작업경로별작업단계관리 PRD

## 1. 문서 개요
- 대상 화면: `기본작업경로별작업단계관리`
- 메뉴 경로: `기준정보 > 코드관리 > 기준작업관리 > 기준작업경로별작업단계관리`
- 화면 패턴: 마스터-디테일 그리드 (공통코드관리 패턴)
- 기준 문서:
  - `LogisT-CM-DS02(화면설계서-V1.0)-기본작업경로별작업단계관리.pdf`
  - `LogisT-CM-AN13(화면정의서-V1.0)_기본작업경로별작업단계관리_20100719.pdf`
- 구현 기준:
  - `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md`
  - 기존 `System::Code` 마스터-디테일 패턴

## 2. 범위
- 작업경로(마스터) 조회/등록/수정/삭제(소프트삭제)
- 작업경로별 작업단계(디테일) 조회/등록/수정/삭제(소프트삭제)
- 마스터 선택 변경 시 디테일 자동 재조회
- 저장은 마스터/디테일 각각 배치 저장
- 메뉴 권한(`STD_WRK_RTING_STEP`) 적용

## 3. 사용자 흐름
1. 화면 진입 시 검색영역과 마스터 그리드가 로드된다.
2. 검색 조건(작업경로코드, 작업경로명, 사용여부)으로 마스터를 조회한다.
3. 마스터 행 선택 시 해당 작업경로의 디테일 목록이 오른쪽 그리드에 표시된다.
4. 마스터/디테일에서 행추가, 행삭제, 저장을 각각 수행한다.
5. 기존 데이터 삭제는 물리삭제가 아니라 `use_yn_cd = "N"`으로 처리한다.

## 4. 화면 구성
### 4.1 검색 영역
- `작업경로코드` (input)
- `작업경로명` (input)
- `사용여부` (select, 기본값 전체)

### 4.2 마스터 그리드: 작업경로목록
- 상태, 작업경로코드, 작업경로명
- 화종, 작업유형1, 작업유형2
- 사용여부, 비고
- 생성/수정 감사 컬럼
- 버튼: 행추가, 행삭제, 저장

### 4.3 디테일 그리드: 작업경로별작업단계목록
- 상태, 순서
- 작업단계코드, 작업단계Level1, 작업단계Level2
- 사용여부, 비고
- 생성/수정 감사 컬럼
- 버튼: 행추가, 행삭제, 저장

## 5. 데이터 모델
### 5.1 마스터 테이블
- 테이블명: `std_work_routings`
- PK: `wrk_rt_cd`
- 주요 컬럼:
  - `wrk_rt_cd` (작업경로코드)
  - `wrk_rt_nm` (작업경로명)
  - `hwajong_cd` (화종)
  - `wrk_type1_cd` (작업유형1)
  - `wrk_type2_cd` (작업유형2)
  - `use_yn_cd` (Y/N, 기본 Y)
  - `rmk_cd` (비고)
  - `create_by`, `create_time`, `update_by`, `update_time`

### 5.2 디테일 테이블
- 테이블명: `std_work_routing_steps`
- PK(복합): `wrk_rt_cd + seq_no`
- 주요 컬럼:
  - `wrk_rt_cd` (상위 작업경로코드)
  - `seq_no` (순서)
  - `work_step_cd` (작업단계코드)
  - `work_step_level1_cd` (작업단계Level1)
  - `work_step_level2_cd` (작업단계Level2)
  - `use_yn_cd` (Y/N, 기본 Y)
  - `rmk_cd` (비고)
  - `create_by`, `create_time`, `update_by`, `update_time`

## 6. 공통코드 매핑
- `07`: 작업단계Level1
- `08`: 작업단계Level2 (상위: Level1)
- `09`: 작업경로 화물종류(화종)
- `10`: 작업유형1(물류영역)
- `11`: 작업유형2(물류기능)
- `181`: 작업단계
- `CMM_USE_YN`: 사용여부

참고: 원본 정의서에는 작업유형2를 `12`로 기술한 부분이 있으나, 현행 시스템 DB의 실제 코드체계는 `11`이므로 `11`을 기준으로 구현한다.

## 7. 비즈니스 규칙
- 신규 행 기본 `use_yn_cd = "Y"`
- 삭제는 소프트삭제(`use_yn_cd = "N"`)
- 디테일은 마스터 키(`wrk_rt_cd`)가 없으면 추가/저장 불가
- 마스터 미저장 변경이 있으면 디테일 저장/수정 차단
- 정합성 검증:
  - `wrk_type1_cd`는 선택된 `hwajong_cd`에 허용된 값이어야 함
  - `wrk_type2_cd`는 선택된 `wrk_type1_cd`에 허용된 값이어야 함
  - `work_step_level2_cd`는 선택된 `work_step_level1_cd`에 허용된 값이어야 함

## 8. API/라우팅
- 화면/마스터
  - `GET /std/work_routing_steps` (HTML/JSON)
  - `POST /std/work_routing_steps/batch_save`
- 디테일
  - `GET /std/work_routing_steps/:work_routing_step_id/details`
  - `POST /std/work_routing_steps/:work_routing_step_id/details/batch_save`

## 9. 권한/메뉴
- 메뉴코드: `STD_WRK_RTING_STEP`
- 메뉴 URL: `/std/work_routing_steps`
- 탭 ID: `std-work-routing-steps`
- `Std::BaseController#require_menu_permission!`를 통해 권한 검사

## 10. 완료 기준
- 마스터-디테일 화면이 공통코드관리와 동일한 UX 패턴으로 동작
- 마스터/디테일 배치 저장 정상 동작
- 소프트삭제 정상 동작
- 공통코드 표시/검증 동작
- 권한 없는 사용자 접근 차단
