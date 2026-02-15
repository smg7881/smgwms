# 부서관리(우리 시스템) PRD

## 1. 목적
- 기존 참조 문서 `doc/부서관리/부서관리_PRD.md`는 타 시스템(Vue/Soybean) 기준이다.
- 본 문서는 우리 시스템(Rails 8.1 + Hotwire + Stimulus + AG Grid) 기준으로 부서관리 화면을 재정의한다.
- 대상 메뉴 경로는 `system/dept` 이다.

## 2. 범위
- 부서 조회(검색)
- 부서 트리 목록 조회
- 부서 추가(최상위/하위)
- 부서 수정
- 부서 삭제(하위 부서 존재 시 삭제 제한)
- 목록 CSV 다운로드

## 3. 화면 요구사항

### 3.1 검색 영역
- 검색 조건
  - 부서코드(`dept_code`, 부분일치)
  - 부서명(`dept_nm`, 부분일치)
  - 사용여부(`use_yn`, 전체/Y/N)
- 검색/초기화는 공통 `search_form` 컴포넌트를 사용한다.

### 3.2 목록 영역
- AG Grid 기반 목록 표시
- 트리 표현 컬럼: 부서명(레벨 기반 들여쓰기)
- 주요 컬럼
  - 부서명, 부서코드, 상위부서코드, 부서유형, 부서순서, 사용여부
  - 수정자, 수정일시, 생성자, 생성일시
  - 작업(하위추가/수정/삭제)

### 3.3 팝업(등록/수정)
- 팝업 타이틀: `부서 추가`, `하위 부서 추가`, `부서 수정`
- 입력 항목
  - 부서코드(필수, 수정 시 읽기전용)
  - 부서명(필수)
  - 상위부서코드(하위 추가 시 자동 세팅, 읽기전용)
  - 부서유형(선택)
  - 부서순서(숫자)
  - 사용여부(Y/N)
  - 설명
- 저장/취소 버튼 제공

## 4. 기능 요구사항

### 4.1 조회
- HTML 요청 시 화면 렌더링
- JSON 요청 시 그리드 데이터 반환
- 검색 조건이 없으면 트리 정렬 기준으로 반환
- 검색 조건이 있으면 조건 필터링 결과 반환

### 4.2 추가
- 최상위 추가: `parent_dept_code = null`
- 하위 추가: 선택 행의 `dept_code`를 `parent_dept_code`로 설정
- `dept_order` 미입력 시 같은 부모 기준 마지막 순서 + 1 자동 부여

### 4.3 수정
- 부서코드는 변경 불가
- 나머지 필드 변경 가능
- 저장 시 수정자/수정일시 자동 갱신

### 4.4 삭제
- 하위 부서가 존재하면 삭제 불가
- 하위 부서가 없으면 삭제 가능

## 5. 데이터 모델(우리 시스템)
- 테이블: `adm_depts`
- PK: `dept_code`
- 컬럼
  - `dept_code` string(50), not null, unique
  - `dept_nm` string(100), not null
  - `dept_type` string(50), null
  - `parent_dept_code` string(50), null
  - `description` text, null
  - `dept_order` integer, default 0
  - `use_yn` string(1), default `Y` (`Y`/`N`)
  - `create_by` string(50), null
  - `create_time` datetime, null
  - `update_by` string(50), null
  - `update_time` datetime, null

## 6. 외부 PRD 대비 마이그레이션 기준
- Vue 컴포넌트(`src/views/system/dept/index.vue`) 구현을 Rails MVC + Stimulus로 치환
- 배치 저장 중심 UX를 우리 시스템 즉시 저장(CRUD API) 방식으로 단순화
- 트리 데이터는 서버에서 계층 정렬 + 레벨 계산 후 그리드 렌더러에서 들여쓰기 표시
- 공통 UI는 기존 `search_form`, `resource_form`, `ag_grid` 규약을 따른다

## 7. 라우팅/구현 위치
- Route: `/system/dept`
- Controller: `app/controllers/system/dept_controller.rb`
- View:
  - `app/views/system/dept/index.html.erb`
  - `app/views/system/dept/_form_modal.html.erb`
- Stimulus:
  - `app/javascript/controllers/dept_crud_controller.js`
- Model:
  - `app/models/adm_dept.rb`

## 8. 테스트 범위
- 모델 테스트
  - 필수값/코드값 검증
  - 상위부서 존재 검증
  - 트리 정렬/레벨 계산
- 컨트롤러 테스트
  - index HTML/JSON 응답
  - create 성공
  - 하위 부서 존재 시 delete 실패
