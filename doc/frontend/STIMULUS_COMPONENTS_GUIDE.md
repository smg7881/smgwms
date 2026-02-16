# Stimulus Components Guide

## 1. CRUD Controller Convention
- Base class: `app/javascript/controllers/base_crud_controller.js`
- Concrete controllers:
  - `dept_crud_controller.js`
  - `menu_crud_controller.js`
  - `user_crud_controller.js`

### Static config (서브클래스 필수)
```javascript
static resourceName = "dept"        // JSON body 키 + URL 치환
static deleteConfirmKey = "deptNm"  // event.detail에서 삭제 확인 표시명 추출 키
static entityLabel = "부서"          // 삭제 확인 메시지 라벨
```

### Base에서 제공하는 공통 메서드
- `handleDelete` — 삭제 확인 + DELETE 요청 (static config 사용)
- `save()` — JSON payload 빌드 + POST/PATCH 요청 (static `resourceName`으로 body 키 결정)
- `submit(event)` — `event.preventDefault()` 후 `save()` 호출

서브클래스에서 오버라이드 가능 (예: `user_crud`는 multipart 전송을 위해 `save()` 오버라이드).

### Required targets
- `overlay`, `modal`, `modalTitle`, `form`, `fieldId`

### Required action names
- Toolbar create button: `click->*-crud#openCreate`
- Modal cancel button role: `data-*-crud-role="cancel"`
- Modal close action: `click->*-crud#closeModal`
- Form submit: `submit->*-crud#submit`

### Event naming
- Add child: `*-crud:add-child`
- Edit: `*-crud:edit`
- Delete: `*-crud:delete`

## 2. AG Grid Renderer Convention
- Renderer module: `app/javascript/controllers/ag_grid/renderers.js`
- Register by string key in column definitions:
  - `treeMenuCellRenderer`
  - `userActionCellRenderer`
  - `deptActionCellRenderer`
  - etc.

### Rule
- Keep controller thin:
  - `ag_grid_controller.js` handles grid lifecycle and data loading
  - `renderers.js` handles cell DOM/event generation

## 3. Search Form Extension Points
- Controller: `app/javascript/controllers/search_form_controller.js`
- Supported actions:
  - `search`
  - `reset`
  - `toggleCollapse`

### Data values
- `collapsedRowsValue`
- `colsValue`
- `enableCollapseValue`

### Rule
- Search UI behavior belongs in `search_form_controller.js`.
- Do not duplicate collapse logic in page-specific controllers.

## 4. Resource Form Extension Points
- Controller: `app/javascript/controllers/resource_form_controller.js`
- Supported actions:
  - `submit`
  - `reset`
  - `validateField`
  - `onSelectChange`

### Dependencies
- Use `depends_on`, `depends_filter` in field definitions.
- Data is passed by `resource_form_dependencies_value`.

### Rule
- Validation/dependency behavior belongs in `resource_form_controller.js`.
- Page-specific CRUD controllers only handle transport (create/update/delete).

## 5. ViewComponent + Stimulus Wiring

### UI 헬퍼 (직접 호출)
검색 폼, 그리드, 리소스 폼은 ViewComponent 래퍼 없이 헬퍼를 직접 호출한다.
- `helpers.search_form_tag(...)` — `SearchFormHelper`
- `helpers.ag_grid_tag(...)` — `AgGridHelper`
- `helpers.resource_form_tag(...)` — `ResourceFormHelper`

### UI ViewComponent
- `Ui::GridToolbarComponent` — 그리드 상단 버튼 툴바
- `Ui::ModalShellComponent` — 드래그 가능한 모달 셸 (header/body/footer)

### Screen composition
- `System::BasePageComponent` — 공통 `initialize`, URL 헬퍼 (`create_url`, `update_url`, `delete_url`, `grid_url`)
- `System::*::PageComponent` — `BasePageComponent` 상속. 검색 필드, 그리드 컬럼, 폼 필드, 모달을 하나의 컴포넌트에서 정의

서브클래스는 `collection_path`와 `member_path`만 구현하면 된다:
```ruby
def collection_path(**) = helpers.system_dept_index_path(**)
def member_path(id, **) = helpers.system_dept_path(id, **)
```

### Rule
- ViewComponent는 마크업과 `data-*` 속성을 정의한다.
- Stimulus 컨트롤러는 해당 속성과 이벤트만 소비한다.
- 헬퍼를 그대로 위임만 하는 래퍼 컴포넌트는 만들지 않는다.

## 6. Tabs Controller Convention
- Controller: `app/javascript/controllers/tabs_controller.js`
- Scope: top-level `.app-layout` (`data-controller="tabs"`)

### Actions
- Open from sidebar: `click->tabs#openTab`
- Activate from tab bar: `click->tabs#activateTab`
- Close tab: `click->tabs#closeTab:stop`
- Toggle sidebar: `click->tabs#toggleSidebar`

### State and endpoints
- Value: `tabsEndpointValue` (default: `/tabs`)
- Request helper: `requestTurboStream(method, url, body)`

### Rule
- Tab open/activate/close must always use Turbo Stream responses.
- After stream render, run `syncUI` or `syncUIFromActiveTab` to keep:
  - sidebar active class
  - breadcrumb current label

## 7. Sidebar Controller Convention
- Controller: `app/javascript/controllers/sidebar_controller.js`
- Action: `click->sidebar#toggleTree`

### Required markup
- Tree toggle button must be followed by `.nav-tree-children`
- Toggle button should have `aria-expanded="false"` initially

### Rule
- `toggleTree` is the only place that updates:
  - `button.expanded` class
  - `.nav-tree-children.open` class
  - `aria-expanded` value

## 8. Search Form Event Table
- Controller: `app/javascript/controllers/search_form_controller.js`

| Event Source | data-action | Method | Purpose |
| --- | --- | --- | --- |
| Search button | `click->search-form#search` | `search(event)` | Validate and submit search form |
| Reset button | `click->search-form#reset` | `reset(event)` | Reset fields and reload base URL |
| Collapse button | `click->search-form#toggleCollapse` | `toggleCollapse(event)` | Toggle compact/expanded search layout |

### State values
- `collapsedValue`
- `loadingValue`
- `collapsedRowsValue`
- `colsValue`
- `enableCollapseValue`

### Required targets
- `form`
- `fieldGroup`
- `buttonGroup`
- Optional: `collapseBtn`, `collapseBtnText`, `collapseBtnIcon`

### Rule
- Search layout visibility is controlled only by `collapsedValueChanged`.
- Page-specific controllers must not directly hide/show search fields.

## 9. Resource Form Event Table
- Controller: `app/javascript/controllers/resource_form_controller.js`

| Event Source | data-action | Method | Purpose |
| --- | --- | --- | --- |
| Form submit | `submit->resource-form#submit` | `submit(event)` | Validate and lock submit during request |
| Reset button | `click->resource-form#reset` | `reset(event)` | Reset fields/errors/dependencies |
| Input blur/change | `blur->resource-form#validateField` (or change) | `validateField(event)` | Field-level validation feedback |
| Parent select change | `change->resource-form#onSelectChange` | `onSelectChange(event)` | Cascade dependent select options |

### State values
- `loadingValue`
- `dependenciesValue`

### Required targets
- `form`
- `fieldGroup`
- Optional by use case: `input`, `dependentField`, `submitBtn`, `submitText`, `submitSpinner`, `errorSummary`, `buttonGroup`

### Dependency field contract
- Child field defines `depends_on` and optional `depends_filter`.
- Parent change must re-filter child options from `data-all-options`.
- Dependency handling must stay inside `resource_form_controller.js`.
