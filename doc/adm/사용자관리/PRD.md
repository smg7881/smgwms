# 사용자관리 (AdmUser) PRD

## 1. 기능 개요

시스템 사용자(사원)를 등록, 조회, 수정, 삭제하는 관리 화면입니다.
기존 `users` 테이블을 `adm_users`로 rename하고 사원관리 필드를 추가합니다.
인증 체계(Session, Current, Authentication concern)는 그대로 유지합니다.

## 2. 데이터 모델

### 테이블: `adm_users` (기존 `users` rename)

| 컬럼명 | 타입 | 설명 | 제약 |
|--------|------|------|------|
| id | integer | PK | auto |
| email_address | string | 이메일(인증용) | unique, not null |
| password_digest | string | 비밀번호 해시 | not null |
| user_id_code | string | 사번 | unique, 영문/숫자 4-16자 |
| user_nm | string | 사원명 | max 20자 |
| dept_cd | string | 부서코드 | - |
| dept_nm | string | 부서명 | - |
| role_cd | string | 권한코드 | - |
| position_cd | string | 직급코드 | - |
| job_title_cd | string | 직책코드 | - |
| work_status | string | 재직상태 | ACTIVE/RESIGNED, default: ACTIVE |
| hire_date | date | 입사일 | - |
| resign_date | date | 퇴사일 | hire_date 이후 |
| phone | string | 연락처 | 010-XXXX-XXXX |
| address | string | 주소 | - |
| detail_address | string | 상세주소 | - |
| created_at | datetime | 생성일시 | auto |
| updated_at | datetime | 수정일시 | auto |

## 3. UI 구성

### 3.1 검색 영역
- 부서명 (input)
- 사원명 (input)
- 재직상태 (select: 전체/재직/퇴사)

### 3.2 그리드 컬럼
- 사번, 사원명, 부서, 연락처, 재직상태, 입사일, 퇴사일, 이메일, 주소, 작업(수정/삭제)

### 3.3 등록/수정 모달
- 사번 (수정시 readonly), 사원명, 이메일, 부서코드, 부서명
- 권한코드, 직급코드, 직책코드, 재직상태
- 입사일, 퇴사일, 연락처, 주소, 상세주소

## 4. API 명세

| Method | Path | 설명 |
|--------|------|------|
| GET | /system/users | 목록 (HTML + JSON) |
| GET | /system/users/:id | 상세 조회 (JSON) |
| POST | /system/users | 등록 (JSON) |
| PATCH | /system/users/:id | 수정 (JSON) |
| DELETE | /system/users/:id | 삭제 (JSON) |
| GET | /system/users/check_id?code=XXX | 사번 중복체크 (JSON) |

## 5. 검증 규칙

- user_id_code: 영문/숫자 4-16자, unique
- user_nm: max 20자
- work_status: ACTIVE 또는 RESIGNED
- phone: 010-XXXX-XXXX 형식
- resign_date: hire_date 이후
- email_address: 이메일 형식, unique (기존)
