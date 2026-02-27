# Grid 공통 소스 정리 계획

## 1. 대상 파일
- `app/javascript/controllers/ag_grid/grid_defaults.js`
- `app/javascript/controllers/ag_grid/renderers.js`
- `app/javascript/controllers/grid/grid_crud_manager.js`
- `app/javascript/controllers/grid/grid_dependent_select_utils.js`
- `app/javascript/controllers/grid/grid_event_manager.js`
- `app/javascript/controllers/grid/grid_form_utils.js`
- `app/javascript/controllers/grid/grid_utils.js`
- `app/javascript/controllers/grid/request_tracker.js`
- `app/javascript/controllers/ag_grid_controller.js`
- `app/javascript/controllers/base_crud_controller.js`
- `app/javascript/controllers/base_grid_controller.js`
- `app/javascript/controllers/master_detail_grid_controller.js`

## 2. 현재 문제 요약
- 공통 로직 중복
  - `isApiAlive`, CSRF/JSON 요청, Search Form 접근 로직이 여러 파일에 중복.
- 책임 경계 불명확
  - AG Grid 전용 책임과 도메인/CRUD 책임이 한 파일에 혼재.
- 파일 과대화
  - `ag_grid_controller.js`, `renderers.js`가 길고 변경 영향 범위가 큼.
- 등록 방식 혼재
  - `registerGrid` 패턴이 컨트롤러마다 달라 추적이 어려움.

## 3. 정리 원칙
- 원칙 1: 공통은 한 곳만 유지 (Single Source of Truth)
- 원칙 2: AG Grid 전용 코드와 화면/도메인 코드를 분리
- 원칙 3: 동작 변경 없는 구조 리팩터링을 먼저 수행
- 원칙 4: 단계별 마이그레이션으로 리스크 최소화

## 4. 목표 구조
```text
app/javascript/controllers/grid/
  core/
    api_guard.js            # isApiAlive 등 생명주기 체크
    http_client.js          # fetch/post/json/CSRF 공통
    search_form_bridge.js   # search-form 접근 공통
    grid_registration.js    # registerGrid/registerGridInstance 공통
    request_tracker.js      # AbortableRequestTracker
  features/
    crud_manager.js         # 기존 grid_crud_manager
    form_sync.js            # 기존 grid_form_utils
    dependent_select.js     # 기존 grid_dependent_select_utils
    event_bus.js            # 기존 grid_event_manager 성격의 바인딩 유틸

app/javascript/controllers/ag_grid/
  defaults.js               # locale/theme/formatter
  column_builder.js         # buildColumnDefs 관련 순수 변환
  data_loader.js            # fetchData/fetchServerPage 로딩 책임
  renderers/
    common.js               # 공통 renderer (link/status/lookup 등)
    actions.js              # 도메인 action renderer
```

## 5. 단계별 실행 계획

### Phase 1 (무동작 리팩터링)
- `grid/core/http_client.js` 신설 후 중복 요청 로직 통합
  - 대상: `base_grid_controller`, `base_crud_controller`, `grid_utils` 일부
- `grid/core/search_form_bridge.js` 신설 후 Search Form 접근 통합
  - 대상: `base_grid_controller#getSearchFormValue/getSearchFieldElement`
  - 대상: `base_crud_controller#getSearchFormValue`
- `grid/core/api_guard.js` 신설 후 `isApiAlive` 단일화
  - 대상: `ag_grid_controller` 내부 중복 제거
- 회귀 확인
  - 그리드 조회/저장/삭제/선택 이벤트가 기존과 동일하게 동작하는지 점검

### Phase 2 (파일 분해)
- `ag_grid_controller.js`에서 아래 책임 분리
  - 컬럼 변환: `column_builder`
  - 데이터 로딩: `data_loader`
  - 컨트롤러는 lifecycle + event wiring 중심으로 축소
- `renderers.js` 분해
  - `common.js`: link/status/lookup 등 재사용 렌더러
  - `actions.js`: `*-crud:*` 이벤트 발생 렌더러

### Phase 3 (등록 규칙 통일)
- `registerGrid` 패턴을 `grid/core/grid_registration.js`로 강제 통일
- `base_grid_controller`/`master_detail_grid_controller`/다중 그리드 화면에 동일 규약 적용
- 신규 컨트롤러 작성 시 템플릿화

### Phase 4 (정리 및 문서화)
- 구 파일 alias 제거 및 import 경로 정리
- Deprecated 경로 제거
- 개발 가이드 문서 갱신 (`doc/` 내 사용 예시 추가)

## 6. 우선순위
1. 중복 제거 (`http/search/api_guard`)
2. `ag_grid_controller` 분해
3. `renderers` 분해
4. 등록 방식 통일

## 7. 리스크 및 대응
- 리스크: 이벤트명 변경/누락으로 화면 동작 불일치
  - 대응: 이벤트명은 Phase 1~2 동안 유지, 내부만 이동
- 리스크: 다중 그리드 화면 초기화 타이밍 이슈
  - 대응: `registerGrid` 공통화 시 ready 조건 테스트 케이스 확보
- 리스크: 회귀 범위가 넓음
  - 대응: 화면별 스모크 체크리스트 운영 (조회/추가/수정/삭제/저장)

## 8. 즉시 수정 권장 항목
- `grid/request_tracker.js`의 `cancelCurrent()`에서
  - `this.abortController = null`이 주석에 붙어 실행되지 않는 형태로 보임.
  - 분리하여 명시적으로 실행되도록 수정 필요.

## 9. 완료 기준 (Definition of Done)
- 공통 유틸 중복 제거 완료 (`api_guard/http/search_form_bridge`)
- `ag_grid_controller.js`와 `renderers.js` 길이/책임 분리 완료
- 주요 그리드 화면 스모크 테스트 통과
- 신규 화면이 공통 규약으로만 구현 가능

