# Client Grid Validation Common Design

## 1. 목적
- 거래처관리 화면의 저장 Validation 동작을 명확히 정의한다.
- Validation 로직을 `GridCrudManager` 중심으로 공통화한다.
- `saveRowsWith` 저장 파이프라인에 공통 Validation을 연결한다.
- 거래처관리(`client_grid_controller`)에 적용 가능한 규칙 셋을 설계한다.
- 본 문서는 설계만 다루며, 소스 구현은 포함하지 않는다.

## 2. 범위
- 프론트엔드
  - `app/javascript/controllers/grid/grid_crud_manager.js`
  - `app/javascript/controllers/base_grid_controller.js`
  - `app/javascript/controllers/client_grid_controller.js`
- 백엔드(참고)
  - `app/controllers/std/clients_controller.rb`
  - `app/models/std_bzac_mst.rb`
  - `app/models/std_bzac_ofcr.rb`
  - `app/models/std_bzac_workpl.rb`

## 3. 현재 구조 요약

### 3.1 저장 흐름
1. 화면 컨트롤러(`client_grid_controller`)가 `saveRowsWith` 호출
2. `saveRowsWith`가 `manager.stopEditing()` 실행
3. `manager.buildOperations()`로 insert/update/delete 페이로드 생성
4. 변경건 없으면 종료
5. `postJson(batchUrl, operations)` 전송
6. 서버에서 모델 validation 실패 시 `errors` 반환

### 3.2 현재 Validation 성격
- 프론트:
  - `blankCheckFields`: "완전 빈 신규행" 제외 용도 (강한 필수 검증 아님)
  - `comparableFields`: 변경 감지 용도
- 서버:
  - ActiveRecord validation이 최종 검증 담당
  - 에러는 batch 저장 결과로 전달

### 3.3 현재 문제
- 필수값 누락/형식 오류를 저장 시점 이전에 충분히 안내하지 못함
- 화면별 검증이 컨트롤러 단에서 흩어질 가능성이 큼
- 공통적인 Validation UX(메시지/포커스/행 식별) 정책 부재

## 4. 목표 아키텍처

### 4.1 원칙
- 서버 모델 validation은 계속 "최종 진실원"으로 유지
- 프론트 validation은 "사전 차단 + 사용자 피드백" 담당
- 공통 엔진(`GridCrudManager.validateRows`) + 화면별 선언형 규칙 사용

### 4.2 Validation 계층
1. Row 정규화 계층
- 기존 `fields` normalizer(`trim`, `trimUpper`, `number`, ...) 재사용

2. 공통 행 검증 계층
- `GridCrudManager.validateRows()` 신설
- 저장 대상(insert/update) 행만 검증
- 삭제 행은 기본적으로 제외

3. 화면별 규칙 계층
- 각 manager config에 규칙 선언
- 예: 필수값, 길이, 패턴, 교차 필드 규칙

4. 서버 최종 검증 계층
- 기존 모델 validation 유지
- 프론트 통과해도 서버에서 재검증

## 5. 설계 상세

### 5.1 `GridCrudManager` 확장 설계

#### A. config 확장안
- `validationRules` (신규)
  - `requiredFields: string[]`
  - `fieldRules: Record<string, Rule[]>`
  - `rowRules: RowRule[]`
  - `messages: Record<string, string>` (옵션)
- Rule 예시 타입(개념)
  - `required`
  - `maxLength`
  - `minLength`
  - `pattern`
  - `enum`
  - `custom` (함수형)

#### B. `validateRows()` 반환 구조
- `valid: boolean`
- `errors: ValidationError[]`
  - `scope`: `insert | update`
  - `rowKey` 또는 `tempId`
  - `field` (없을 수 있음, row-level 에러)
  - `code` (예: `required`, `pattern`)
  - `message`
- `firstError` (포커스 이동용)

#### C. 동작 규칙
- 대상 행: `rowsToInsert + rowsToUpdate`
- `blankCheckFields`로 제외되는 완전 빈 신규행은 검증 제외
- field rule 먼저, row rule 다음 순서
- 첫 에러 위치를 기록해 UI 포커스 이동에 사용

### 5.2 `saveRowsWith` 연동 설계

#### A. 실행 순서 변경
1. `manager.stopEditing()`
2. `manager.validateRows()`
3. invalid면:
  - 요약 alert 표시
  - 첫 에러 셀/행으로 포커스 이동
  - 저장 중단(return false)
4. valid면 `buildOperations()` -> `postJson()` 진행

#### B. 메시지 정책
- 기본: "입력값을 확인해주세요. (N건 오류)"
- 상세: 첫 오류 1건 + 필요 시 리스트(최대 5건)
- 서버 에러는 기존처럼 응답 메시지 우선

### 5.3 거래처관리 규칙 적용안

#### A. 마스터(`masterManagerConfig`) 규칙안
- 필수(프론트 사전검증)
  - `bzac_nm`, `mngt_corp_cd`, `bizman_no`, `bzac_sctn_grp_cd`, `bzac_sctn_cd`, `bzac_kind_cd`, `ctry_cd`, `rpt_sales_emp_cd`, `aply_strt_day_cd`, `use_yn_cd`
- 형식
  - `bizman_no`: 숫자 10자리
  - Y/N 필드: `Y|N`
- 교차 규칙
  - `aply_end_day_cd`가 있으면 `aply_strt_day_cd <= aply_end_day_cd`

#### B. 담당자(`contactManagerConfig`) 규칙안
- 필수: `nm_cd`
- 형식
  - `email_cd`는 값이 있을 때 이메일 패턴
  - `rpt_yn_cd`, `use_yn_cd`는 `Y|N`

#### C. 작업장(`workplaceManagerConfig`) 규칙안
- 필수: `workpl_nm_cd`
- 형식
  - `use_yn_cd`는 `Y|N`

### 5.4 서버 검증과의 관계
- 서버 모델 validation은 유지 (중복 허용)
- 프론트는 사용자 경험 개선용 1차 필터
- 서버는 무결성 보장용 최종 필터

## 6. 공통화 적용 단계

### Phase 1. 공통 인터페이스 도입
- `GridCrudManager`에 `validationRules` 스키마 정의
- `validateRows()` API 시그니처 확정

### Phase 2. 저장 파이프라인 연동
- `BaseGridController.saveRowsWith`에서 `validateRows()` 호출
- 실패 시 포커스/메시지 정책 반영

### Phase 3. 거래처 화면 규칙 선언 적용
- `client_grid_controller` 3개 manager config에 규칙 선언

### Phase 4. 수평 확장
- 다른 grid controller로 동일 패턴 확장
- 필요 시 공통 validator 라이브러리로 분리

## 7. 테스트 전략

### 7.1 단위 테스트
- `GridCrudManager.validateRows`:
  - required 누락
  - pattern 위반
  - row-level 규칙 위반
  - 정상 통과

### 7.2 통합 테스트(화면)
- 거래처관리 저장 버튼:
  - 잘못된 데이터 입력 시 저장 중단
  - 에러 메시지/포커스 이동 확인
  - 정상 데이터 저장 성공

### 7.3 회귀 테스트
- 기존 `buildOperations` 결과 동일성
- 기존 서버 validation 응답 처리 유지

## 8. 리스크 및 대응
- 리스크: 규칙 중복 관리(프론트/서버)
  - 대응: 서버 기준 유지, 프론트는 UX용 최소 규칙부터 적용
- 리스크: 화면별 예외 규칙 증가
  - 대응: `custom rowRule` 허용 + 공통 rule 우선
- 리스크: 기존 저장 흐름 영향
  - 대응: feature flag 또는 화면 단위 점진 적용

## 9. 의사결정 필요 항목
1. 프론트 필수 검증 범위(서버와 100% 동일화 vs 핵심 필드만)
2. 에러 표시 방식(알림창만 vs 필드 하이라이트 병행)
3. 적용 전략(거래처관리 선적용 후 확장 여부)

## 10. 완료 기준(구현 시)
- `GridCrudManager.validateRows`가 공통 동작한다.
- `saveRowsWith`가 validate 실패 시 API 호출을 중단한다.
- 거래처관리 3개 manager에 선언형 규칙이 적용된다.
- 서버 validation과 충돌 없이 기존 저장 기능이 유지된다.
