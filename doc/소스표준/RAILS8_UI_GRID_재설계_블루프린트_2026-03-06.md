# Rails8 UI/Grid 재설계 블루프린트 (2026-03-06)

## 1. 목적
- 현재 WMS 관리자 화면의 UI/그리드 구현 불균형을 해소하고, 신규 화면 개발 속도와 유지보수성을 동시에 확보한다.
- 전면 폐기 후 재개발이 아닌, "기능 유지 + 구조 교체" 방식으로 리스크를 통제한다.

## 2. 의사결정
- 선택: 점진적 재구성(권장)
- 비선택: 전체 삭제 후 재개발

선택 이유:
1. 운영 중 도메인 규칙 유실 위험 최소화
2. 화면 단위 검증으로 장애 범위 제한
3. 기존 업무 일정과 병행 가능
4. 중간 산출물(공통 컴포넌트/공통 로직)을 즉시 재사용 가능

## 3. 최상위 원칙
1. 계약 우선: ViewComponent, Stimulus, Controller 간 API 계약을 먼저 고정한다.
2. 중복 제거: 동일 기능은 화면별 구현 금지, 공통 모듈 승격을 우선한다.
3. 얇은 컨트롤러: 비즈니스 규칙은 모델로 이동한다.
4. 점진 교체: 화면 단위로 신규 패턴 적용 후 기존 코드 제거.
5. 게이트 기반: 계약 테스트 + 회귀 테스트 통과 전 머지 금지.

## 4. 목표 아키텍처

### 4.1 화면 계층
- PageComponent: 경로/컬럼/폼/URL 템플릿 선언
- Stimulus Grid Controller: 화면 상태 + GridCrudManager 조합
- Rails Controller: index/json + batch_save + 트랜잭션 처리

### 4.2 JS 공통 계층
- `BaseGridController`: 다중 그리드, master-detail 디스패치, before-search 초기화
- `GridCrudManager`: 변경 추적(C/U/D), validation, focus 처리
- `grid_utils`: fetch/post, template URL, selection label, pending-block
- Mixins: modal, excel 등 화면 부가기능

### 4.3 UI 공통 계층
- `Ui::SearchFormComponent`
- `Ui::AgGridComponent`
- `Ui::GridToolbarComponent`
- `Ui::GridActionsComponent`
- `Ui::ModalShellComponent`

## 5. 공통 계약(필수)

### 5.1 Naming 계약
- Stimulus 대상 target: `masterGrid`, `detailGrid`(필요 시 `detail2Grid`, `execGrid`)
- 저장 액션 메서드: `saveMasterRows`, `saveDetailRows`
- 검색 전 초기화 훅: `beforeSearchReset`
- 선택 라벨 메서드: `refreshSelected...Label`

### 5.2 Master-Detail 계약
- `gridRoles()`에서 `master`, `detail`, `parentGrid: "master"` 선언
- detail 조회는 `detailLoader` 사용
- detail 작업(추가/삭제/저장) 전 `blockIfPendingChanges(masterManager, "...")` 강제
- detail batch URL은 `buildTemplateUrl()`로 생성

### 5.3 Controller 계약
- `index`: html/json dual response
- `batch_save`: `rowsToInsert/rowsToUpdate/rowsToDelete` 처리
- 트랜잭션 실패 시 `{ success: false, errors: errors.uniq }`

## 6. 마이그레이션 전략

### Phase 0. 동결선 정의 (1~2일)
- 신규 기능 개발은 허용하되 "신규 패턴"만 사용
- 기존 화면의 임시 패치 최소화

### Phase 1. 공통 코어 정리 (3~5일)
- `BaseGridController`, `GridCrudManager`, `grid_utils`에서 중복 API 통합
- deprecated 메서드 alias 제공 후 호출부 단계 교체
- 공통 에러/알림 메시지 포맷 통일

### Phase 2. 기준 화면 재구성 (3~5일)
- 기준 후보 1: `system/code` (정석 master-detail)
- 기준 후보 2: `wm/gr_prars` (복합 동작: detail + exec + 확정/취소)
- 기준 화면에서 계약 테스트를 먼저 통과시킨다.

### Phase 3. 수평 확장 (지속)
- WM/STD/OM 순으로 화면군을 배치 전환
- 화면 전환 기준: 복잡도 높은 화면 우선(중복 제거 효과가 큼)

### Phase 4. 레거시 제거
- 호출 0건 확인 후 구버전 유틸/컨트롤러 삭제
- 문서/템플릿/체크리스트 최신화

## 7. 작업 단위 표준(한 화면 기준)
1. PageComponent를 계약형 값 주입 구조로 정리
2. Stimulus를 `gridRoles + managerConfig + save*Rows` 구조로 정리
3. Controller batch/save 규약 일치
4. 테스트 추가(컨트롤러 + 계약 테스트)
5. 구코드 제거

## 8. 테스트/게이트

### 8.1 필수 테스트
- `ruby bin/rails test` (화면 컨트롤러 테스트 포함)
- master-detail 계약 테스트(있는 경우)
- 최소 1개 저장 시나리오 회귀 테스트

### 8.2 필수 정적 점검
- `bin/rubocop`
- `bin/brakeman --no-pager`

### 8.3 머지 조건
- 계약 위반 없음
- 중복 코드 증가 없음
- 신규 화면/수정 화면 모두 공통 모듈 재사용

## 9. 전면 재작성 허용 조건(예외)
아래 조건을 모두 만족할 때만 화면 단위 "재작성" 허용:
1. 기존 로직의 결함 누적이 심각
2. 계약 테스트 확보 가능
3. 기능 동결 기간 확보
4. 운영 영향 범위가 제한됨

## 10. 우선순위 백로그(권장)
1. `wm/gr_prars` 컨트롤러/그리드 계약 고정
2. `wm/pur_fee_rt_mngs`, `wm/sell_fee_rt_mngs`의 중복 패턴 통합
3. `wm/rate_retroacts`의 저장/적용 액션 계약 통일
4. `std/work_routing_step`을 템플릿 화면으로 고정

## 11. 리포지토리 적용 규칙
- 신규 화면은 `doc/starter_template/README.md` 패턴 준수
- 화면별 임시 유틸 생성 금지
- 공통화 가능 코드 발견 시 즉시 `controllers/grid/*` 또는 공용 컴포넌트로 승격

## 12. 완료 정의(Definition of Done)
1. 신규/개편 화면이 계약을 만족한다.
2. 동일 기능의 구현 위치가 1곳으로 수렴한다.
3. 저장/삭제/검증 UX가 화면 간 동일하다.
4. 문서와 코드의 계약이 일치한다.

## 13. 시작 제안 (이번 주)
1. `wm/gr_prars`를 파일럿 화면으로 고정
2. 계약 체크리스트 기반으로 누락 항목 보완
3. 관련 WM 화면 2개를 같은 패턴으로 연속 변환
4. 변환 완료 후 레거시 분기 제거
