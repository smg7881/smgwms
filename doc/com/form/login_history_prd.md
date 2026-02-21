# 로그인 이력 (Login History) PRD

## 개요
모든 로그인 시도(성공/실패)를 영구 기록하여 보안 감사 및 관리 목적으로 활용하는 읽기 전용 시스템 관리 화면.

## 기능 요약
- **로그인 성공 기록**: 인증 성공 시 사번, 사원명, IP, 브라우저/OS 정보 자동 저장
- **로그인 실패 기록**: 인증 실패 시 입력 이메일, IP, 실패 사유 자동 저장
- **조회 화면**: AG Grid 기반 서버 사이드 페이지네이션 (50건/페이지)
- **검색 필터**: 사번, 시작일시, 종료일시, 결과(성공/실패)

## 데이터 모델
테이블: `adm_login_histories`

| 컬럼 | 타입 | 설명 |
|---|---|---|
| user_id_code | string(16) | 사번 |
| user_nm | string(20) | 사원명 |
| login_time | datetime | 로그인 시도 시각 |
| login_success | boolean | 성공/실패 |
| ip_address | string(45) | IP 주소 |
| user_agent | string(500) | UA 문자열 |
| browser | string(100) | 브라우저명 |
| os | string(100) | OS명 |
| failure_reason | string(200) | 실패 사유 |

## UI 구성
- 검색 폼 (4컬럼 레이아웃)
- AG Grid (서버 사이드 페이지네이션)
- 성공/실패 컬러 뱃지 렌더러

## 접근 제한
- 관리자(ADMIN) 전용 (`System::BaseController` → `require_admin!`)
