# Client Validation Common 구현 요약

## 1. 개요
- 목적: `client_validation_common_design.md` 설계 기준으로 실제 반영된 구현 내용을 요약한다.
- 대상 화면: 거래처관리(`client_grid_controller`)
- 범위: 프론트 Validation 공통화, 저장 파이프라인 연동, 인라인 오류 UI 적용

## 2. 변경 파일
- `app/javascript/controllers/grid/grid_crud_manager.js`
- `app/javascript/controllers/base_grid_controller.js`
- `app/javascript/controllers/client_grid_controller.js`
- `app/components/std/client/page_component.html.erb`
- `app/assets/tailwind/application.css`

## 3. 구현 상세

### 3.1 GridCrudManager 공통 Validation 엔진
- `validateRows()` 추가
- `focusValidationError(error)` 추가
- `formatValidationSummary(errors, options)` 추가
- 지원 규칙
  - `requiredFields`
  - `fieldRules` (`required`, `minLength`, `maxLength`, `pattern`, `enum`, `custom`)
  - `rowRules` (행 단위 교차 검증)
- 검증 대상
  - 신규/수정 행만 대상
  - 삭제 행 제외
  - 완전 빈 신규 행(`blankCheckFields`) 제외

### 3.2 BaseGridController 저장 파이프라인 연동
- `saveRowsWith()`에서 저장 API 호출 전에 `manager.validateRows()` 실행
- Validation 실패 시
  - 저장 API 호출 중단
  - 첫 오류 셀로 포커스 이동(`focusValidationError`)
  - 컨트롤러에 `showValidationErrors()`가 있으면 인라인 오류 렌더링
  - 인라인 렌더가 없으면 경고 알림으로 대체
- Validation 성공 시
  - `clearValidationErrors()`로 인라인 오류 초기화

### 3.3 거래처 화면 규칙 적용
- 3개 manager(마스터/담당자/작업장)에 `validationRules` 선언
- 마스터 규칙
  - 필수값 검증
  - 사업자번호 10자리 숫자 패턴
  - Y/N enum 검증
  - 날짜 순서 검증(`적용시작일 <= 적용종료일`)
- 담당자 규칙
  - 담당자명 필수
  - 이메일 형식 검증(값이 있을 때)
  - Y/N enum 검증
- 작업장 규칙
  - 작업장명 필수
  - Y/N enum 검증
- 오류 UX
  - `showValidationErrors(...)`
  - `clearValidationErrors()`
  - 오류 위치에 맞는 탭 자동 전환

### 3.4 UI 마크업/스타일
- 페이지 컴포넌트에서 선택 거래처 라벨 아래 Validation 박스 마크업 추가
- 스타일 클래스 추가
  - `.std-client-validation`
  - `.std-client-validation-title`
  - `.std-client-validation-summary`
  - `.std-client-validation-list`

## 4. 실행 흐름(요약)
1. 사용자가 저장 클릭
2. `saveRowsWith()`가 편집 종료 후 `validateRows()` 실행
3. Validation 실패 시
  - 저장 중단
  - 인라인 오류 표시
  - 첫 오류 셀 포커스
4. Validation 성공 시
  - 기존과 동일하게 operation 생성 후 저장 API 호출

## 5. 검증 결과
- JS 구문 점검 통과
  - `node --check app/javascript/controllers/base_grid_controller.js`
  - `node --check app/javascript/controllers/client_grid_controller.js`
  - `node --check app/javascript/controllers/grid/grid_crud_manager.js`
- Rails 테스트 통과
  - `ruby bin/rails test test/controllers/std/clients_controller_test.rb:61 test/controllers/std/clients_controller_test.rb:101`
  - `ruby bin/rails test test/models/std_bzac_mst_test.rb`
- 참고
  - `test/controllers/std/clients_controller_test.rb` 전체 실행 시 163라인에서 기존 라우트 헬퍼 오류 1건(`sections_std_clients_url` 미존재) 확인
  - 해당 오류는 이번 JS Validation 변경과 직접 연관이 낮음

## 6. 영향도
- 잘못된 입력은 저장 API 호출 전에 프론트에서 차단된다.
- 서버 모델 Validation은 최종 검증으로 그대로 유지된다.
- 기존 저장 흐름은 유지되며, Validation 실패 시 조기 반환만 추가되었다.

## 7. 후속 권장사항
1. `clients_controller_test`의 `sections` 라우트/헬퍼 불일치 정리
2. 동일 Validation 패턴을 다른 Grid 화면으로 확장
3. Validation 메시지 공통화(일관성/다국어) 검토
