# 공통코드 화면 마이그레이션 PRD (Soybean -> smgWms)

## 1. 문서 목적
- 원본 Vue(`D:\project\soybean\src\views\system\code\index.vue`)의 공통코드 관리 화면을 우리 시스템(Rails + Hotwire + Stimulus) 구조로 이식한다.
- 이식 대상 메뉴 경로는 `system/code` 이다.
- 본 문서는 구현 전에 데이터/화면/이벤트/엔드포인트 계약을 확정하기 위한 기준 문서다.

## 2. 참조 기준
- 원본 화면: `D:\project\soybean\src\views\system\code\index.vue`
- 원본 필드/컬럼:
  - `D:\project\soybean\src\views\system\code\modules\code-search.ts`
  - `D:\project\soybean\src\views\system\code\modules\code-columns.ts`
- 우리 시스템 규약:
  - `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`
  - 기존 구현 패턴: `system/dept`, `system/menus`, `system/users`

## 3. 범위
### 3.1 포함
- 공통코드 마스터/상세 CRUD
- 마스터/상세 2-패널 화면
- 검색(코드, 코드명, 상세코드, 상세코드명, 사용여부)
- 마스터 선택에 따른 상세 목록 조회
- 메뉴 등록(`system/code`)
- Rails + ViewComponent + Stimulus + AG Grid 기반 이식

### 3.2 제외
- Vue의 인라인 배치편집(셀 직접 편집 + 일괄 저장) 완전 동일 재현
- 다국어(i18n) 추가 확장
- 외부 시스템 연동 API

## 4. 기능 요구사항
### 4.1 화면 레이아웃
- 상단: 검색 폼
- 하단 좌측: 코드 마스터 그리드 + 툴바
- 하단 우측: 상세코드 그리드 + 툴바
- 마스터/상세 각각 모달 기반 등록/수정

### 4.2 검색
- 조건: `code`, `code_name`, `detail_code`, `detail_code_name`, `use_yn`
- Reset 시 검색조건/선택코드 초기화
- 검색은 `q[...]` 파라미터 규약 유지

### 4.3 마스터(코드)
- 목록 조회/등록/수정/삭제
- 삭제 전 확인 메시지 노출
- 마스터 행 액션:
  - `상세보기`(선택코드 전환)
  - `수정`
  - `삭제`

### 4.4 상세코드
- 선택된 마스터 코드 기준 목록 조회
- 등록/수정/삭제
- 마스터 미선택 상태에서 등록 시 차단 알림

## 5. 데이터 모델
### 5.1 마스터 테이블
- 테이블: `adm_code_headers`
- 주요 컬럼:
  - `code`(PK), `code_name`, `use_yn`
  - `create_by`, `create_time`, `update_by`, `update_time`

### 5.2 상세 테이블
- 테이블: `adm_code_details`
- 주요 컬럼:
  - `code`(FK 역할), `detail_code`, `detail_code_name`
  - `short_name`, `ref_code`, `sort_order`, `use_yn`
  - `create_by`, `create_time`, `update_by`, `update_time`
- 유니크: `(code, detail_code)`

## 6. API/라우팅 계약
### 6.1 마스터
- `GET /system/code` (HTML/JSON)
- `POST /system/code`
- `PATCH /system/code/:id`
- `DELETE /system/code/:id`

### 6.2 상세
- `GET /system/code/:code_id/details` (JSON)
- `POST /system/code/:code_id/details`
- `PATCH /system/code/:code_id/details/:detail_code`
- `DELETE /system/code/:code_id/details/:detail_code`

## 7. UI/Stimulus 아키텍처
- PageComponent 중심 구성:
  - `System::Code::PageComponent`
- Stimulus 컨트롤러 분리:
  - `code-header-crud`: 마스터 CRUD + 선택코드 전환
  - `code-detail-crud`: 상세 CRUD
- 공통 규약 준수:
  - Base CRUD 상속
  - 이벤트 네이밍(`*-crud:edit`, `*-crud:delete`)
  - 필수 targets/action 규칙은 `STIMULUS_COMPONENTS_GUIDE.md` 기준 준수

## 8. 원본 대비 마이그레이션 전략
- 유지:
  - 검색 조건/마스터-상세 구조/핵심 필드
- 변경:
  - Vue 배치 저장 -> 우리 시스템 표준 모달 CRUD 방식
  - 그리드 셀 inline edit 최소화, 서버 일관성 우선
- 이유:
  - 현재 시스템 표준(재사용 가능한 Base CRUD + Resource Form + AgGrid Renderer)과 정합성 확보
  - 유지보수 비용/회귀 리스크 최소화

## 9. 비기능 요구사항
- 코드 스타일: 현재 프로젝트 규약(`STYLE.md`, `STIMULUS_COMPONENTS_GUIDE.md`)
- 보안: Strong Params, CSRF, 서버 검증
- 성능: 인덱스 기반 조회(코드, 사용여부, 상세코드)

## 10. 수용 기준 (Acceptance Criteria)
- `/system/code` 진입 시 검색 + 2개 그리드가 렌더링된다.
- 검색 조건으로 마스터 목록 필터링이 된다.
- 마스터 `상세보기` 클릭 시 우측 상세 목록이 해당 코드 기준으로 로딩된다.
- 마스터/상세 각각 등록, 수정, 삭제가 성공/실패 메시지와 함께 동작한다.
- 메뉴 트리에서 `system/code` 경로로 접근 가능하다.
- 기존 `dept/menus/users` 화면 동작에 회귀가 없다.

## 11. 구현 산출물
- DB 마이그레이션(마스터/상세 + 메뉴)
- 모델 2종
- 컨트롤러 2종(마스터/상세)
- ViewComponent + 템플릿 + index view
- Stimulus 컨트롤러 2종
- AG Grid 렌더러 추가
- route 추가
