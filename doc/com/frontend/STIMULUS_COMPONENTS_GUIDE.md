# Stimulus 컴포넌트 가이드

이 문서는 Rails + Hotwire(Stimulus/Turbo) 기반 화면에서 사용하는 공통 프런트엔드 규칙을 정리합니다.  
목표는 다음 3가지입니다.

- 화면별 컨트롤러를 얇게 유지하고 공통 로직을 재사용한다.
- 이벤트 이름, `data-*` 속성, targets를 일관되게 맞춘다.
- 유지보수 시 "어디를 수정해야 하는지"를 즉시 판단할 수 있게 한다.

## 1. CRUD 컨트롤러 규약

- 기본 클래스: `app/javascript/controllers/base_crud_controller.js`
- 구체 컨트롤러 예시:
  - `dept_crud_controller.js`
  - `menu_crud_controller.js`
  - `user_crud_controller.js`

### 필수 static 설정

```javascript
static resourceName = "dept"       // 요청 body 루트 키 + URL 파라미터 구성 기준
static deleteConfirmKey = "deptNm" // event.detail에서 삭제 확인 메시지에 표시할 필드 키
static entityLabel = "부서"         // 삭제/알림 메시지에서 사용할 엔티티 표시명
```

### Base CRUD의 공통 메서드

- `handleDelete`: 삭제 확인 후 `DELETE` 요청 실행
- `save()`: JSON payload 생성 후 `POST`/`PATCH` 요청 실행
- `submit(event)`: `event.preventDefault()` 후 `save()` 호출

`user_crud`처럼 파일 업로드가 필요한 경우에는 `save()`를 오버라이드해서 `multipart/form-data` 전송으로 바꿉니다.

### 필수 targets

- `overlay`
- `modal`
- `modalTitle`
- `form`
- `fieldId`

### 필수 action 이름

- 생성 버튼: `click->*-crud#openCreate`
- 모달 취소 버튼 역할: `data-*-crud-role="cancel"`
- 모달 닫기: `click->*-crud#closeModal`
- 폼 제출: `submit->*-crud#submit`

### 이벤트 네이밍 규칙

- 하위 추가: `*-crud:add-child`
- 수정: `*-crud:edit`
- 삭제: `*-crud:delete`

### 상세 구현 지침

- 페이지별 컨트롤러는 "전송(transport) + 페이지 특화 전처리"만 담당합니다.
- 모달 열기/닫기, 공통 검증, 로딩 상태는 Base에서 처리합니다.
- 이벤트 payload 포맷(`event.detail`)은 문서화하고 모든 화면에서 동일하게 유지합니다.

## 2. AG Grid Renderer 규약

- 렌더러 모듈: `app/javascript/controllers/ag_grid/renderers.js`
- 컬럼 정의에서 문자열 키로 등록:
  - `treeMenuCellRenderer`
  - `userActionCellRenderer`
  - `deptActionCellRenderer`
  - 기타 커스텀 렌더러

### 규칙

- `ag_grid_controller.js`: 그리드 생명주기, 데이터 로딩, API 연동 담당
- `renderers.js`: 셀 DOM 생성, 버튼 이벤트 바인딩 담당

### 상세 구현 지침

- 렌더러에서 비즈니스 판단(권한, 정책)을 직접 하지 말고 전달된 데이터/플래그만 사용합니다.
- 셀 내부 버튼은 커스텀 이벤트를 dispatch하고, 실제 처리(수정/삭제)는 CRUD 컨트롤러가 수행합니다.
- 렌더러 키 이름은 엔티티 + 역할 형태(`deptActionCellRenderer`)로 통일합니다.

## 3. 검색 폼 확장 포인트

- 컨트롤러: `app/javascript/controllers/search_form_controller.js`
- 지원 action:
  - `search`
  - `reset`
  - `toggleCollapse`

### data values

- `collapsedRowsValue`
- `colsValue`
- `enableCollapseValue`

### 규칙

- 검색 UI 동작(접기/펼치기, 버튼 상태)은 `search_form_controller.js`에서만 관리합니다.
- 화면 전용 컨트롤러에 동일 로직을 복제하지 않습니다.

### 상세 구현 지침

- 검색 요청 직전에는 폼 직렬화 규칙(빈값 처리, trim 등)을 일관되게 적용합니다.
- reset 시 URL 기준 상태(기본 쿼리 없음)로 복귀하도록 유지합니다.
- 접힘 상태는 반응형 레이아웃과 충돌하지 않게 `collapsedValueChanged` 한 곳에서만 렌더링을 제어합니다.

## 4. 리소스 폼 확장 포인트

- 컨트롤러: `app/javascript/controllers/resource_form_controller.js`
- 지원 action:
  - `submit`
  - `reset`
  - `validateField`
  - `onSelectChange`

### 의존성 규칙

- 필드 정의에 `depends_on`, `depends_filter` 사용
- 의존 데이터는 `resource_form_dependencies_value`로 전달

### 규칙

- 검증/의존성 처리 로직은 `resource_form_controller.js`에 둡니다.
- CRUD 컨트롤러는 생성/수정/삭제 전송만 담당합니다.

### 상세 구현 지침

- 필드 단위 오류 표시와 요약 오류 표시(`errorSummary`)를 동시에 지원합니다.
- 제출 중(`loadingValue=true`)에는 submit 버튼 중복 클릭을 차단합니다.
- 부모 필드 변경 시 자식 필드의 선택 불가능 값을 즉시 제거해 잘못된 제출을 방지합니다.

## 5. ViewComponent + Stimulus 연결 규약

### UI 헬퍼 직접 호출

검색/그리드/리소스 폼은 ViewComponent 래퍼를 만들지 않고 헬퍼를 직접 호출합니다.

- `helpers.search_form_tag(...)` from `SearchFormHelper`
- `helpers.ag_grid_tag(...)` from `AgGridHelper`
- `helpers.resource_form_tag(...)` from `ResourceFormHelper`

### UI ViewComponent

- `Ui::GridToolbarComponent`: 그리드 상단 버튼 영역
- `Ui::ModalShellComponent`: 드래그 가능한 모달 셸(header/body/footer)

### 화면 구성

- `System::BasePageComponent`: 공통 `initialize`, URL 헬퍼(`create_url`, `update_url`, `delete_url`, `grid_url`)
- `System::*::PageComponent`: `BasePageComponent` 상속 후 검색 필드/그리드 컬럼/폼 필드/모달 구성 정의

서브 클래스는 최소한 아래 2개 path만 구현하면 됩니다.

```ruby
def collection_path(**) = helpers.system_dept_index_path(**)
def member_path(id, **) = helpers.system_dept_path(id, **)
```

### 규칙

- ViewComponent는 마크업과 `data-*` 속성을 정의합니다.
- Stimulus 컨트롤러는 해당 속성과 이벤트를 소비합니다.
- 단순 위임만 하는 불필요한 래퍼 컴포넌트는 만들지 않습니다.

### 상세 구현 지침

- 새로운 화면 추가 시 먼저 PageComponent에서 데이터/레이아웃 계약을 확정한 뒤 JS를 연결합니다.
- `data-controller`, `data-*-target`, `data-action`은 컴포넌트 템플릿에 모아서 선언해 추적성을 높입니다.
- 컨트롤러가 DOM 구조에 과도하게 의존하지 않도록 의미 있는 target 이름을 유지합니다.

## 6. Tabs 컨트롤러 규약

- 컨트롤러: `app/javascript/controllers/tabs_controller.js`
- 스코프: 최상위 `.app-layout` (`data-controller="tabs"`)

### actions

- 사이드바에서 열기: `click->tabs#openTab`
- 탭바에서 활성화: `click->tabs#activateTab`
- 탭 닫기: `click->tabs#closeTab:stop`
- 사이드바 토글: `click->tabs#toggleSidebar`

### 상태/엔드포인트

- value: `tabsEndpointValue` (기본값 `/tabs`)
- 요청 헬퍼: `requestTurboStream(method, url, body)`

### 규칙

- 탭 열기/활성화/닫기는 항상 Turbo Stream 응답으로 처리합니다.
- stream 렌더링 후 `syncUI` 또는 `syncUIFromActiveTab`을 호출해 다음 상태를 동기화합니다.
  - 사이드바 active 클래스
  - breadcrumb 현재 라벨

### 상세 구현 지침

- 탭 식별자는 URL + 파라미터를 기준으로 안정적으로 생성합니다.
- 동일 탭 중복 생성 방지 로직을 두고, 존재하면 활성화로 전환합니다.
- 닫힌 탭 다음 활성 대상(좌/우 우선순위)을 일관된 규칙으로 유지합니다.

## 7. Sidebar 컨트롤러 규약

- 컨트롤러: `app/javascript/controllers/sidebar_controller.js`
- action: `click->sidebar#toggleTree`

### 필수 마크업

- 트리 토글 버튼 바로 다음 요소가 `.nav-tree-children` 이어야 합니다.
- 토글 버튼 초기값은 `aria-expanded="false"`를 권장합니다.

### 규칙

아래 상태 변경은 오직 `toggleTree`에서만 수행합니다.

- `button.expanded` 클래스
- `.nav-tree-children.open` 클래스
- `aria-expanded` 값

### 상세 구현 지침

- 접근성 기준을 위해 키보드 포커스 이동 시에도 펼침 상태를 예측 가능하게 유지합니다.
- 서버 렌더링 초기 상태와 클라이언트 토글 상태가 충돌하지 않도록 초기 class/aria를 맞춥니다.

## 8. Search Form 이벤트 표

- 컨트롤러: `app/javascript/controllers/search_form_controller.js`

| 이벤트 소스 | data-action | 메서드 | 목적 |
| --- | --- | --- | --- |
| 검색 버튼 | `click->search-form#search` | `search(event)` | 검색 폼 검증 후 제출 |
| 초기화 버튼 | `click->search-form#reset` | `reset(event)` | 필드 초기화 후 기본 URL 재조회 |
| 접기 버튼 | `click->search-form#toggleCollapse` | `toggleCollapse(event)` | 검색 영역 접기/펼치기 전환 |

### 상태 값

- `collapsedValue`
- `loadingValue`
- `collapsedRowsValue`
- `colsValue`
- `enableCollapseValue`

### 필수 targets

- `form`
- `fieldGroup`
- `buttonGroup`
- 선택: `collapseBtn`, `collapseBtnText`, `collapseBtnIcon`

### 규칙

- 검색 레이아웃 표시/숨김은 `collapsedValueChanged`만 제어합니다.
- 페이지 전용 컨트롤러가 검색 필드를 직접 숨김/표시하지 않습니다.

## 9. Resource Form 이벤트 표

- 컨트롤러: `app/javascript/controllers/resource_form_controller.js`

| 이벤트 소스 | data-action | 메서드 | 목적 |
| --- | --- | --- | --- |
| 폼 제출 | `submit->resource-form#submit` | `submit(event)` | 검증 수행 및 요청 중 submit 잠금 |
| 초기화 버튼 | `click->resource-form#reset` | `reset(event)` | 필드/오류/의존성 초기화 |
| 입력 blur/change | `blur->resource-form#validateField` (또는 change) | `validateField(event)` | 필드 단위 검증 피드백 |
| 부모 select 변경 | `change->resource-form#onSelectChange` | `onSelectChange(event)` | 의존 select 옵션 연쇄 갱신 |

### 상태 값

- `loadingValue`
- `dependenciesValue`

### 필수 targets

- `form`
- `fieldGroup`
- 선택(화면별): `input`, `dependentField`, `submitBtn`, `submitText`, `submitSpinner`, `errorSummary`, `buttonGroup`

### 의존 필드 계약

- 자식 필드는 `depends_on`과 선택적으로 `depends_filter`를 정의합니다.
- 부모 값 변경 시 자식 옵션은 `data-all-options`를 기준으로 재필터링합니다.
- 의존성 처리 코드는 `resource_form_controller.js` 내부에만 둡니다.

## 10. 신규 화면 추가 체크리스트

- `System::*::PageComponent`에 URL/필드/컬럼/모달 계약 정의
- `data-controller`, `data-action`, `data-*-target` 연결
- CRUD 이벤트(`add-child`, `edit`, `delete`) 연동 확인
- 검색/리소스 폼 공통 컨트롤러 재사용 여부 확인
- Turbo Stream 응답과 탭 동기화(`syncUI*`) 확인
- 접근성 속성(`aria-expanded`, 버튼 label) 확인

## 11. 안티패턴

- 페이지마다 동일한 `search/reset/collapse` 로직을 복붙
- 렌더러에서 API 호출/도메인 로직 수행
- 컨트롤러마다 다른 이벤트 이름 사용
- ViewComponent 밖에서 임의로 `data-*` 구조를 깨뜨림
- 제출 중 중복 클릭 방지 없이 연속 요청 허용

## 12. 디버깅 포인트

- 이벤트가 안 오면: `data-action` 문자열(`event->controller#method`) 오탈자 확인
- target 인식 실패 시: `data-*-target` 이름과 `static targets` 일치 여부 확인
- 폼 의존성 오류 시: `dependenciesValue`와 `data-all-options` 구조 확인
- 탭/사이드바 동기화 불일치 시: Turbo Stream 렌더링 직후 `syncUI*` 호출 여부 확인
