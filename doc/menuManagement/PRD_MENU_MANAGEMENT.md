# PRD: 메뉴관리 (Menu Management)

## 1. 개요

### 1.1 목적
시스템 관리자가 사이드바 메뉴 구조를 동적으로 관리할 수 있는 **메뉴관리** 화면을 개발합니다.
현재 하드코딩된 사이드바 메뉴(`_sidebar.html.erb`)를 DB 기반으로 전환하여, 메뉴 추가/수정/삭제를 코드 변경 없이 수행할 수 있도록 합니다.

### 1.2 메뉴 위치
- **사이드바 경로**: `시스템 > 메뉴관리`
- **탭 ID**: `system-menus`
- **URL**: `/system/menus`

### 1.3 기술 스택 (기존 프로젝트 패턴 준수)
- **Backend**: Rails 8.1 / SQLite3
- **Frontend**: Hotwire (Turbo + Stimulus) + AG Grid Community v35
- **UI 패턴**: 검색폼(`search_form_tag`) + AG Grid(`ag_grid_tag`) + 모달 CRUD

---

## 2. 데이터베이스 설계

### 2.1 테이블: `adm_menus`

| 컬럼명 | 타입 | 제약조건 | 설명 |
|---|---|---|---|
| `id` | integer | PK, auto increment | 기본키 |
| `menu_cd` | string(20) | NOT NULL, UNIQUE, INDEX | 메뉴 코드 (예: "MENU001") |
| `menu_nm` | string(100) | NOT NULL | 메뉴 명칭 (예: "게시물 목록") |
| `parent_cd` | string(20) | NULL, INDEX | 상위 메뉴 코드 (NULL=최상위) |
| `menu_url` | string(200) | NULL | 메뉴 URL (예: "/posts") |
| `menu_icon` | string(10) | NULL | 메뉴 아이콘 (이모지, 예: "📋") |
| `sort_order` | integer | NOT NULL, DEFAULT 0 | 정렬 순서 (같은 레벨 내) |
| `menu_level` | integer | NOT NULL, DEFAULT 1 | 메뉴 깊이 (1=최상위, 2=하위) |
| `menu_type` | string(10) | NOT NULL, DEFAULT 'MENU' | 메뉴 타입 (FOLDER=폴더, MENU=메뉴) |
| `use_yn` | string(1) | NOT NULL, DEFAULT 'Y' | 사용 여부 (Y/N) |
| `tab_id` | string(50) | NULL | 탭 시스템 연동 ID |
| `created_at` | datetime | NOT NULL | 생성일시 |
| `updated_at` | datetime | NOT NULL | 수정일시 |

### 2.2 마이그레이션

```ruby
# db/migrate/XXXXXXXX_create_adm_menus.rb
class CreateAdmMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_menus do |t|
      t.string  :menu_cd,       limit: 20,  null: false
      t.string  :menu_nm,       limit: 100, null: false
      t.string  :parent_cd,     limit: 20
      t.string  :menu_url,      limit: 200
      t.string  :menu_icon,     limit: 10
      t.integer :sort_order,    null: false, default: 0
      t.integer :menu_level,    null: false, default: 1
      t.string  :menu_type,     limit: 10,  null: false, default: "MENU"
      t.string  :use_yn,        limit: 1,   null: false, default: "Y"
      t.string  :tab_id,        limit: 50

      t.timestamps
    end

    add_index :adm_menus, :menu_cd, unique: true
    add_index :adm_menus, :parent_cd
    add_index :adm_menus, [:parent_cd, :sort_order]
  end
end
```

### 2.3 시드 데이터

현재 하드코딩된 사이드바 메뉴를 초기 데이터로 마이그레이션합니다:

| menu_cd | menu_nm | parent_cd | menu_url | menu_icon | sort_order | menu_level | menu_type | tab_id |
|---|---|---|---|---|---|---|---|---|
| MAIN | 메인 | NULL | NULL | NULL | 1 | 1 | FOLDER | NULL |
| OVERVIEW | 개요 | MAIN | / | 📊 | 1 | 2 | MENU | overview |
| POST | 게시물 | NULL | NULL | 📝 | 2 | 1 | FOLDER | NULL |
| POST_LIST | 게시물 목록 | POST | /posts | 📋 | 1 | 2 | MENU | posts-list |
| POST_NEW | 게시물 작성 | POST | /posts/new | ✏️ | 2 | 2 | MENU | posts-new |
| ANALYSIS | 분석 | NULL | NULL | NULL | 3 | 1 | FOLDER | NULL |
| REPORTS | 통계 | ANALYSIS | /reports | 📈 | 1 | 2 | MENU | reports |
| SYSTEM | 시스템 | NULL | NULL | NULL | 4 | 1 | FOLDER | NULL |
| SYS_MENU | 메뉴관리 | SYSTEM | /system/menus | ⚙️ | 1 | 2 | MENU | system-menus |

---

## 3. 화면 설계

### 3.1 화면 레이아웃

```
┌──────────────────────────────────────────────────────────────┐
│  페이지 헤더: "메뉴관리"                                        │
├──────────────────────────────────────────────────────────────┤
│  ┌─ 검색폼 (Search Form) ──────────────────────────────────┐ │
│  │ [메뉴코드: ____] [메뉴명: ____] [사용여부: ▼전체]        │ │
│  │                             [초기화] [검색] [접기/펼치기] │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ─── sf-divider ─────────────────────────────────────────────  │
│  ┌─ 버튼 영역 ─────────────────────────────────────────────┐  │
│  │ [최상위메뉴추가]                                          │  │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌─ AG Grid (읽기전용 + 작업 컬럼) ────────────────────────┐  │
│  │ 메뉴코드│메뉴명│상위코드│URL│아이콘│정렬│레벨│타입│사용│탭ID│작업     │ │
│  │ MAIN   │메인  │      │   │    │  1 │ 1 │폴더│ Y │    │[+][✎][🗑] │ │
│  │ OVERVIEW│개요 │MAIN  │ / │ 📊 │  1 │ 2 │메뉴│ Y │over│[+][✎][🗑] │ │
│  │  ...   │     │      │   │    │    │   │   │   │    │           │ │
│  └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

┌─ 모달 팝업 (메뉴 추가/수정) ──────────────────────┐
│  메뉴코드:    [________]                            │
│  메뉴명:      [________]                            │
│  상위메뉴코드: [MAIN    ] (읽기전용, 자동설정)         │
│  URL:         [________]                            │
│  아이콘:       [________]                            │
│  정렬순서:     [___0___]                             │
│  레벨:        [___2___] (자동설정)                    │
│  타입:        [▼MENU  ]                             │
│  사용여부:     [▼Y     ]                             │
│  탭ID:        [________]                            │
│                              [취소]  [저장]          │
└────────────────────────────────────────────────────┘
```

### 3.2 검색폼 (Search Form)

`search_form_tag` 헬퍼를 사용하여 기존 패턴과 동일하게 구현합니다.

```erb
<%= search_form_tag(
  url: system_menus_path,
  fields: [
    { field: "menu_cd", type: "input", label: "메뉴코드", placeholder: "메뉴코드 검색..." },
    { field: "menu_nm", type: "input", label: "메뉴명", placeholder: "메뉴명 검색..." },
    { field: "use_yn", type: "select", label: "사용여부",
      options: [
        { label: "전체", value: "" },
        { label: "사용", value: "Y" },
        { label: "미사용", value: "N" }
      ],
      include_blank: false
    }
  ],
  cols: 3,
  enable_collapse: true
) %>
```

### 3.3 그리드 위 버튼 영역

그리드 상단에 최상위메뉴추가 버튼을 배치합니다. Stimulus 컨트롤러(`menu-crud`)가 모달과 CRUD를 관리합니다.

```erb
<div data-controller="menu-crud"
     data-menu-crud-create-url-value="<%= system_menus_path %>"
     data-menu-crud-update-url-value="<%= system_menu_path(':id') %>"
     data-menu-crud-delete-url-value="<%= system_menu_path(':id') %>">
  <div class="grid-toolbar">
    <div class="grid-toolbar-buttons">
      <button type="button" class="btn btn-sm btn-primary"
              data-action="click->menu-crud#openAddTopLevel">
        최상위메뉴추가
      </button>
    </div>
  </div>

  <%= ag_grid_tag(
    columns: [...],
    url: system_menus_path(format: :json),
    height: "calc(100vh - 370px)"
  ) %>

  <%# 메뉴 추가/수정 모달 (섹션 3.5 참조) %>
  <%= render "system/menus/form_modal" %>
</div>
```

### 3.4 AG Grid 컬럼 정의

그리드는 **읽기전용**이며, 마지막 컬럼에 작업 아이콘(하위메뉴추가, 수정, 삭제)을 표시합니다.

| field | headerName | editable | 비고 |
|---|---|---|---|
| `menu_cd` | 메뉴코드 | false | |
| `menu_nm` | 메뉴명 | false | |
| `parent_cd` | 상위메뉴코드 | false | |
| `menu_url` | URL | false | |
| `menu_icon` | 아이콘 | false | |
| `sort_order` | 정렬순서 | false | |
| `menu_level` | 레벨 | false | |
| `menu_type` | 타입 | false | FOLDER/MENU 표시 |
| `use_yn` | 사용여부 | false | Y/N 표시 |
| `tab_id` | 탭ID | false | |
| (actions) | 작업 | false | 하위메뉴추가 / 수정 / 삭제 아이콘 |

```ruby
# 뷰에서의 컬럼 정의
columns: [
  { field: "menu_cd",    headerName: "메뉴코드",    minWidth: 120 },
  { field: "menu_nm",    headerName: "메뉴명",      minWidth: 120 },
  { field: "parent_cd",  headerName: "상위메뉴코드",  minWidth: 120 },
  { field: "menu_url",   headerName: "URL",         minWidth: 150 },
  { field: "menu_icon",  headerName: "아이콘",       maxWidth: 80 },
  { field: "sort_order", headerName: "정렬",         maxWidth: 80 },
  { field: "menu_level", headerName: "레벨",         maxWidth: 70 },
  { field: "menu_type",  headerName: "타입",         maxWidth: 80 },
  { field: "use_yn",     headerName: "사용",         maxWidth: 70 },
  { field: "tab_id",     headerName: "탭ID",         minWidth: 120 },
  { field: "actions",    headerName: "작업",         minWidth: 130, maxWidth: 130,
    cellRenderer: "actionCellRenderer" }
]
```

#### 작업 컬럼 셀 렌더러

각 행에 3개의 아이콘 버튼을 렌더링합니다:

| 아이콘 | 동작 | 설명 |
|---|---|---|
| ➕ (하위메뉴추가) | 모달 오픈 | 해당 행의 `menu_cd`를 `parent_cd`로 설정한 신규 메뉴 추가 모달 |
| ✏️ (수정) | 모달 오픈 | 해당 행의 데이터를 모달에 채워서 수정 |
| 🗑️ (삭제) | confirm 후 삭제 | 확인 다이얼로그 후 서버에 DELETE 요청 |

```javascript
// actionCellRenderer - AG Grid 커스텀 셀 렌더러
function actionCellRenderer(params) {
  const container = document.createElement("div")
  container.classList.add("grid-action-buttons")

  // 하위메뉴추가 버튼
  const addBtn = document.createElement("button")
  addBtn.innerHTML = "➕"
  addBtn.title = "하위메뉴추가"
  addBtn.classList.add("grid-action-btn")
  addBtn.addEventListener("click", () => {
    const event = new CustomEvent("menu-crud:add-child", {
      detail: { parentCd: params.data.menu_cd, parentLevel: params.data.menu_level },
      bubbles: true
    })
    container.dispatchEvent(event)
  })

  // 수정 버튼
  const editBtn = document.createElement("button")
  editBtn.innerHTML = "✏️"
  editBtn.title = "수정"
  editBtn.classList.add("grid-action-btn")
  editBtn.addEventListener("click", () => {
    const event = new CustomEvent("menu-crud:edit", {
      detail: { menuData: params.data },
      bubbles: true
    })
    container.dispatchEvent(event)
  })

  // 삭제 버튼
  const deleteBtn = document.createElement("button")
  deleteBtn.innerHTML = "🗑️"
  deleteBtn.title = "삭제"
  deleteBtn.classList.add("grid-action-btn", "grid-action-btn--danger")
  deleteBtn.addEventListener("click", () => {
    const event = new CustomEvent("menu-crud:delete", {
      detail: { id: params.data.id, menuCd: params.data.menu_cd },
      bubbles: true
    })
    container.dispatchEvent(event)
  })

  container.appendChild(addBtn)
  container.appendChild(editBtn)
  container.appendChild(deleteBtn)
  return container
}
```

### 3.5 모달 팝업 (메뉴 추가/수정)

하위메뉴추가, 수정, 최상위메뉴추가 시 공통으로 사용하는 모달입니다.

```erb
<%# app/views/system/menus/_form_modal.html.erb %>
<div class="modal-overlay" data-menu-crud-target="overlay"
     data-action="click->menu-crud#closeModal" hidden>
  <div class="modal-content" data-action="click->menu-crud#stopPropagation">
    <div class="modal-header">
      <h3 data-menu-crud-target="modalTitle">메뉴 추가</h3>
      <button type="button" class="modal-close"
              data-action="click->menu-crud#closeModal">&times;</button>
    </div>
    <div class="modal-body">
      <form data-menu-crud-target="form">
        <input type="hidden" name="id" data-menu-crud-target="fieldId">

        <div class="form-group">
          <label>메뉴코드 <span class="required">*</span></label>
          <input type="text" name="menu_cd" maxlength="20" required
                 data-menu-crud-target="fieldMenuCd">
        </div>
        <div class="form-group">
          <label>메뉴명 <span class="required">*</span></label>
          <input type="text" name="menu_nm" maxlength="100" required
                 data-menu-crud-target="fieldMenuNm">
        </div>
        <div class="form-group">
          <label>상위메뉴코드</label>
          <input type="text" name="parent_cd" maxlength="20" readonly
                 data-menu-crud-target="fieldParentCd">
        </div>
        <div class="form-group">
          <label>URL</label>
          <input type="text" name="menu_url" maxlength="200"
                 data-menu-crud-target="fieldMenuUrl">
        </div>
        <div class="form-group">
          <label>아이콘</label>
          <input type="text" name="menu_icon" maxlength="10"
                 data-menu-crud-target="fieldMenuIcon">
        </div>
        <div class="form-group">
          <label>정렬순서</label>
          <input type="number" name="sort_order" value="0"
                 data-menu-crud-target="fieldSortOrder">
        </div>
        <div class="form-group">
          <label>레벨</label>
          <input type="number" name="menu_level" readonly
                 data-menu-crud-target="fieldMenuLevel">
        </div>
        <div class="form-group">
          <label>타입</label>
          <select name="menu_type" data-menu-crud-target="fieldMenuType">
            <option value="FOLDER">FOLDER</option>
            <option value="MENU">MENU</option>
          </select>
        </div>
        <div class="form-group">
          <label>사용여부</label>
          <select name="use_yn" data-menu-crud-target="fieldUseYn">
            <option value="Y">Y</option>
            <option value="N">N</option>
          </select>
        </div>
        <div class="form-group">
          <label>탭ID</label>
          <input type="text" name="tab_id" maxlength="50"
                 data-menu-crud-target="fieldTabId">
        </div>
      </form>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn btn-sm btn-secondary"
              data-action="click->menu-crud#closeModal">취소</button>
      <button type="button" class="btn btn-sm btn-primary"
              data-action="click->menu-crud#saveMenu">저장</button>
    </div>
  </div>
</div>
```

#### 모달 동작 규칙

| 호출 | 모달 제목 | parent_cd | menu_level | menu_cd 편집 |
|---|---|---|---|---|
| 최상위메뉴추가 | "최상위 메뉴 추가" | 빈값 (NULL) | 1 (자동) | 가능 |
| 하위메뉴추가 (➕) | "하위 메뉴 추가" | 부모 menu_cd (읽기전용) | 부모 level + 1 (자동) | 가능 |
| 수정 (✏️) | "메뉴 수정" | 기존값 (읽기전용) | 기존값 (읽기전용) | **불가** (읽기전용) |

---

## 4. API 설계

### 4.1 라우팅

```ruby
# config/routes.rb
namespace :system do
  resources :menus, only: [:index, :create, :update, :destroy]
end
```

생성되는 라우트:
- `GET    /system/menus`       → `System::MenusController#index` (HTML + JSON)
- `POST   /system/menus`       → `System::MenusController#create` (메뉴 추가)
- `PATCH  /system/menus/:id`   → `System::MenusController#update` (메뉴 수정)
- `DELETE /system/menus/:id`   → `System::MenusController#destroy` (메뉴 삭제)

### 4.2 컨트롤러: `System::MenusController`

```ruby
# app/controllers/system/menus_controller.rb
class System::MenusController < ApplicationController
  def index
    @menus = AdmMenu.order(:sort_order, :menu_cd)

    # 검색 필터 적용
    if search_params[:menu_cd].present?
      @menus = @menus.where("menu_cd LIKE ?", "%#{search_params[:menu_cd]}%")
    end
    if search_params[:menu_nm].present?
      @menus = @menus.where("menu_nm LIKE ?", "%#{search_params[:menu_nm]}%")
    end
    if search_params[:use_yn].present?
      @menus = @menus.where(use_yn: search_params[:use_yn])
    end

    respond_to do |format|
      format.html
      format.json { render json: @menus }
    end
  end

  def create
    menu = AdmMenu.new(menu_params)

    if menu.save
      render json: { success: true, message: "추가되었습니다.", menu: menu }
    else
      render json: { success: false, errors: menu.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def update
    menu = AdmMenu.find(params[:id])

    if menu.update(menu_params)
      render json: { success: true, message: "수정되었습니다.", menu: menu }
    else
      render json: { success: false, errors: menu.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def destroy
    menu = AdmMenu.find(params[:id])

    # 하위 메뉴가 있으면 삭제 불가
    if menu.children.exists?
      render json: { success: false, errors: ["하위 메뉴가 존재하여 삭제할 수 없습니다."] },
             status: :unprocessable_entity
    else
      menu.destroy
      render json: { success: true, message: "삭제되었습니다." }
    end
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:menu_cd, :menu_nm, :use_yn)
    end

    def menu_params
      params.require(:menu).permit(
        :menu_cd, :menu_nm, :parent_cd, :menu_url, :menu_icon,
        :sort_order, :menu_level, :menu_type, :use_yn, :tab_id
      )
    end
end
```

### 4.3 JSON 응답 형식

**GET /system/menus.json** (목록 조회)
```json
[
  {
    "id": 1,
    "menu_cd": "MAIN",
    "menu_nm": "메인",
    "parent_cd": null,
    "menu_url": null,
    "menu_icon": null,
    "sort_order": 1,
    "menu_level": 1,
    "menu_type": "FOLDER",
    "use_yn": "Y",
    "tab_id": null
  }
]
```

**POST /system/menus** (메뉴 추가 요청)
```json
{
  "menu": {
    "menu_cd": "NEW_MENU",
    "menu_nm": "새메뉴",
    "parent_cd": "MAIN",
    "sort_order": 5,
    "menu_level": 2,
    "menu_type": "MENU",
    "use_yn": "Y"
  }
}
```

**POST /system/menus** (성공 응답)
```json
{
  "success": true,
  "message": "추가되었습니다.",
  "menu": { "id": 10, "menu_cd": "NEW_MENU", ... }
}
```

**PATCH /system/menus/:id** (메뉴 수정 요청)
```json
{
  "menu": {
    "menu_nm": "메인(수정)",
    "sort_order": 1
  }
}
```

**DELETE /system/menus/:id** (삭제 응답)
```json
{ "success": true, "message": "삭제되었습니다." }
```

---

## 5. 모델 설계

### 5.1 AdmMenu 모델

```ruby
# app/models/adm_menu.rb
class AdmMenu < ApplicationRecord
  # ── 유효성 검증 ──
  validates :menu_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :menu_nm, presence: true, length: { maximum: 100 }
  validates :use_yn, inclusion: { in: %w[Y N] }
  validates :menu_level, inclusion: { in: [1, 2] }
  validates :menu_type, inclusion: { in: %w[FOLDER MENU] }
  validates :sort_order, numericality: { only_integer: true }

  # ── 스코프 ──
  scope :active, -> { where(use_yn: "Y") }
  scope :ordered, -> { order(:sort_order, :menu_cd) }
  scope :top_level, -> { where(parent_cd: nil) }
  scope :folders, -> { where(menu_type: "FOLDER") }
  scope :menus, -> { where(menu_type: "MENU") }

  # ── 관계 (자기참조) ──
  def children
    AdmMenu.where(parent_cd: menu_cd)
  end

  def parent
    AdmMenu.find_by(menu_cd: parent_cd) if parent_cd.present?
  end

  # ── 사이드바 메뉴 조회 (캐시 가능) ──
  def self.sidebar_tree
    active.ordered.group_by(&:parent_cd)
  end

  # ── 폴더 여부 ──
  def folder?
    menu_type == "FOLDER"
  end
end
```

---

## 6. 프론트엔드 설계

### 6.1 Stimulus 컨트롤러: `menu-crud`

모달을 통한 메뉴 CRUD를 관리하는 Stimulus 컨트롤러입니다.
`ag-grid` 컨트롤러는 그리드 렌더링/데이터 로딩을 담당하고, `menu-crud`는 모달 열기/닫기, 폼 데이터 처리, 서버 통신을 담당합니다.

```javascript
// app/javascript/controllers/menu_crud_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "overlay", "modalTitle", "form",
    "fieldId", "fieldMenuCd", "fieldMenuNm", "fieldParentCd",
    "fieldMenuUrl", "fieldMenuIcon", "fieldSortOrder",
    "fieldMenuLevel", "fieldMenuType", "fieldUseYn", "fieldTabId"
  ]

  static values = {
    createUrl: String,   // POST /system/menus
    updateUrl: String,   // PATCH /system/menus/:id (":id"를 실제 id로 치환)
    deleteUrl: String    // DELETE /system/menus/:id
  }

  connect() {
    // 그리드 작업 컬럼 커스텀 이벤트 수신
    this.element.addEventListener("menu-crud:add-child", this.#handleAddChild)
    this.element.addEventListener("menu-crud:edit", this.#handleEdit)
    this.element.addEventListener("menu-crud:delete", this.#handleDelete)
  }

  disconnect() {
    this.element.removeEventListener("menu-crud:add-child", this.#handleAddChild)
    this.element.removeEventListener("menu-crud:edit", this.#handleEdit)
    this.element.removeEventListener("menu-crud:delete", this.#handleDelete)
  }

  // ── 최상위메뉴추가 버튼 ──
  openAddTopLevel() {
    this.#resetForm()
    this.modalTitleTarget.textContent = "최상위 메뉴 추가"
    this.fieldParentCdTarget.value = ""
    this.fieldMenuLevelTarget.value = 1
    this.fieldMenuTypeTarget.value = "FOLDER"
    this.fieldMenuCdTarget.readOnly = false
    this._mode = "create"
    this.#openModal()
  }

  // ── 하위메뉴추가 (그리드 이벤트) ──
  #handleAddChild = (event) => {
    const { parentCd, parentLevel } = event.detail
    this.#resetForm()
    this.modalTitleTarget.textContent = "하위 메뉴 추가"
    this.fieldParentCdTarget.value = parentCd
    this.fieldMenuLevelTarget.value = parentLevel + 1
    this.fieldMenuTypeTarget.value = "MENU"
    this.fieldMenuCdTarget.readOnly = false
    this._mode = "create"
    this.#openModal()
  }

  // ── 수정 (그리드 이벤트) ──
  #handleEdit = (event) => {
    const data = event.detail.menuData
    this.modalTitleTarget.textContent = "메뉴 수정"
    this.fieldIdTarget.value = data.id
    this.fieldMenuCdTarget.value = data.menu_cd
    this.fieldMenuCdTarget.readOnly = true  // 수정 시 메뉴코드 변경 불가
    this.fieldMenuNmTarget.value = data.menu_nm
    this.fieldParentCdTarget.value = data.parent_cd || ""
    this.fieldMenuUrlTarget.value = data.menu_url || ""
    this.fieldMenuIconTarget.value = data.menu_icon || ""
    this.fieldSortOrderTarget.value = data.sort_order
    this.fieldMenuLevelTarget.value = data.menu_level
    this.fieldMenuTypeTarget.value = data.menu_type
    this.fieldUseYnTarget.value = data.use_yn
    this.fieldTabIdTarget.value = data.tab_id || ""
    this._mode = "update"
    this.#openModal()
  }

  // ── 삭제 (그리드 이벤트) ──
  #handleDelete = async (event) => {
    const { id, menuCd } = event.detail

    if (!confirm(`"${menuCd}" 메뉴를 삭제하시겠습니까?`)) return

    const url = this.deleteUrlValue.replace(":id", id)
    const response = await fetch(url, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })

    const result = await response.json()
    if (result.success) {
      alert("삭제되었습니다.")
      this.#refreshGrid()
    } else {
      alert("삭제 실패: " + result.errors.join(", "))
    }
  }

  // ── 모달 저장 버튼 ──
  async saveMenu() {
    const formData = new FormData(this.formTarget)
    const menu = Object.fromEntries(formData)

    // 빈 문자열을 null로 변환
    Object.keys(menu).forEach(key => {
      if (menu[key] === "") menu[key] = null
    })

    let url, method
    if (this._mode === "create") {
      url = this.createUrlValue
      method = "POST"
      delete menu.id
    } else {
      url = this.updateUrlValue.replace(":id", menu.id)
      method = "PATCH"
      delete menu.id
    }

    const response = await fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ menu })
    })

    const result = await response.json()
    if (result.success) {
      alert(result.message)
      this.closeModal()
      this.#refreshGrid()
    } else {
      alert("저장 실패: " + result.errors.join(", "))
    }
  }

  // ── 모달 열기/닫기 ──
  #openModal() {
    this.overlayTarget.hidden = false
  }

  closeModal() {
    this.overlayTarget.hidden = true
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // ── 폼 초기화 ──
  #resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldSortOrderTarget.value = 0
    this.fieldUseYnTarget.value = "Y"
  }

  // ── 그리드 새로고침 ──
  #refreshGrid() {
    const agGridEl = this.element.querySelector("[data-controller='ag-grid']")
    const agGridController = this.application.getControllerForElementAndIdentifier(
      agGridEl, "ag-grid"
    )
    agGridController?.refresh()
  }
}
```

### 6.2 AG Grid 작업 컬럼 렌더러

`ag_grid_controller.js`에 `actionCellRenderer`를 등록하여 작업 컬럼을 렌더링합니다.
컬럼 정의에서 `cellRenderer: "actionCellRenderer"`를 사용합니다 (섹션 3.4 참조).

### 6.3 AG Grid Helper 확장

`ALLOWED_COLUMN_KEYS`에 `cellRenderer` 키를 추가해야 합니다.

### 6.4 모달 CSS 스타일

```css
/* app/assets/stylesheets/menu_modal.css */

/* 모달 오버레이 */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

/* 모달 컨텐츠 */
.modal-content {
  background: var(--bg-primary, #fff);
  border-radius: 8px;
  width: 480px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.15);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid var(--border-color, #e5e7eb);
}

.modal-header h3 { margin: 0; font-size: 16px; }

.modal-close {
  background: none;
  border: none;
  font-size: 20px;
  cursor: pointer;
  color: var(--text-secondary, #6b7280);
}

.modal-body {
  padding: 20px;
}

.modal-body .form-group {
  margin-bottom: 12px;
}

.modal-body .form-group label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  margin-bottom: 4px;
  color: var(--text-primary, #374151);
}

.modal-body .form-group .required {
  color: #ef4444;
}

.modal-body .form-group input,
.modal-body .form-group select {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid var(--border-color, #d1d5db);
  border-radius: 4px;
  font-size: 13px;
}

.modal-body .form-group input[readonly] {
  background: var(--bg-secondary, #f3f4f6);
  color: var(--text-secondary, #6b7280);
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 12px 20px;
  border-top: 1px solid var(--border-color, #e5e7eb);
}

/* 그리드 작업 버튼 */
.grid-action-buttons {
  display: flex;
  gap: 4px;
  align-items: center;
}

.grid-action-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 2px 4px;
  font-size: 14px;
  border-radius: 3px;
}

.grid-action-btn:hover {
  background: var(--bg-hover, #f3f4f6);
}

.grid-action-btn--danger:hover {
  background: #fef2f2;
}
```

---

## 7. 사이드바 연동

### 7.1 사이드바 동적 렌더링

`_sidebar.html.erb`를 DB 기반 메뉴로 전환합니다:

```erb
<nav class="sidebar-nav">
  <% AdmMenu.sidebar_tree.each do |parent_cd, menus| %>
    <% if parent_cd.nil? %>
      <% menus.each do |section| %>
        <% if section.menu_type == "FOLDER" %>
          <div class="nav-section-label"><%= section.menu_nm %></div>

          <% children = AdmMenu.active.ordered.where(parent_cd: section.menu_cd) %>
          <% children.each do |child| %>
            <% if child.menu_type == "FOLDER" %>
              <button class="nav-item has-children" type="button"
                      data-action="click->sidebar#toggleTree">
                <span class="icon"><%= child.menu_icon %></span> <%= child.menu_nm %>
                <span class="chevron">▶</span>
              </button>
              <div class="nav-tree-children">
                <% AdmMenu.active.ordered.where(parent_cd: child.menu_cd).each do |grandchild| %>
                  <%= sidebar_menu_button grandchild.menu_nm,
                        tab_id: grandchild.tab_id, icon: grandchild.menu_icon, url: grandchild.menu_url %>
                <% end %>
              </div>
            <% else %>
              <%= sidebar_menu_button child.menu_nm,
                    tab_id: child.tab_id, icon: child.menu_icon, url: child.menu_url %>
            <% end %>
          <% end %>
        <% elsif section.menu_type == "MENU" && section.menu_url.present? %>
          <%= sidebar_menu_button section.menu_nm,
                tab_id: section.tab_id, icon: section.menu_icon, url: section.menu_url %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
</nav>
```

### 7.2 TabRegistry 연동

`TabRegistry`도 DB 기반으로 전환하거나, 메뉴 저장 시 TabRegistry 캐시를 갱신하는 방식을 선택할 수 있습니다.
**1차 구현**에서는 TabRegistry를 유지하되, 사이드바만 DB 기반으로 전환합니다.

---

## 8. 파일 구조

### 8.1 신규 생성 파일

```
db/migrate/XXXXXXXX_create_adm_menus.rb            # 마이그레이션
app/models/adm_menu.rb                              # 모델
app/controllers/system/menus_controller.rb          # 컨트롤러 (index, create, update, destroy)
app/views/system/menus/index.html.erb               # 뷰 (검색폼 + 그리드)
app/views/system/menus/_form_modal.html.erb         # 메뉴 추가/수정 모달 파셜
app/javascript/controllers/menu_crud_controller.js  # 모달 CRUD Stimulus 컨트롤러
app/assets/stylesheets/menu_modal.css               # 모달 + 작업버튼 스타일
db/seeds/adm_menus.rb                               # 시드 데이터 (또는 db/seeds.rb에 추가)
```

### 8.2 수정 파일

```
config/routes.rb                                 # 라우팅 추가
app/views/shared/_sidebar.html.erb               # DB 기반 메뉴로 전환
app/javascript/controllers/ag_grid_controller.js # actionCellRenderer 등록
app/models/tab_registry.rb                       # system-menus 탭 추가
```

---

## 9. 구현 순서 (Implementation Steps)

### Phase 1: 백엔드 기초
1. 마이그레이션 생성 및 실행 (`adm_menus` 테이블)
2. `AdmMenu` 모델 생성 (유효성 검증, 스코프)
3. `System::MenusController` 생성 (index, create, update, destroy)
4. 라우팅 추가 (`namespace :system`)
5. 시드 데이터 작성 및 실행

### Phase 2: 프론트엔드 화면
6. `system/menus/index.html.erb` 뷰 생성 (검색폼 + 최상위메뉴추가 버튼 + 그리드)
7. `_form_modal.html.erb` 모달 파셜 생성
8. `menu_crud_controller.js` Stimulus 컨트롤러 생성
9. `ag_grid_controller.js`에 `actionCellRenderer` 등록
10. 모달 + 작업버튼 CSS 스타일링 (`menu_modal.css`)

### Phase 3: 사이드바/탭 연동
11. `TabRegistry`에 `system-menus` 엔트리 추가
12. 사이드바 메뉴에 "시스템 > 메뉴관리" 추가 (우선 하드코딩, Phase 4에서 동적 전환)

### Phase 4: 사이드바 동적 전환 (선택)
13. `_sidebar.html.erb`를 DB 기반 메뉴로 전환
14. 사이드바 캐싱 적용

---

## 10. 고려사항

### 10.1 보안
- `menu_params`에 Strong Parameters 적용
- CSRF 토큰 검증 (Rails 기본)
- 인증 필수 (`require_authentication` before_action)

### 10.2 성능
- 사이드바 메뉴 조회는 매 요청마다 발생하므로, 향후 `Rails.cache` 적용 고려
- 검색 시 LIKE 쿼리에 인덱스 활용

### 10.3 확장성
- `menu_level`은 현재 2단계까지 지원, 향후 3단계 이상 확장 가능
- 권한(role) 기반 메뉴 필터링은 별도 테이블(`adm_menu_roles`)로 확장 가능
