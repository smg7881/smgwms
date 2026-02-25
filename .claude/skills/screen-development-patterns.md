# WMS 화면 개발 패턴 가이드

## 개요

WMS 프로젝트의 관리 화면은 **3-레이어 아키텍처**를 따릅니다:

1. **ViewComponent 페이지** (`app/components/<namespace>/<module>/page_component.rb` + `.html.erb`)
   - `System::BasePageComponent` 상속
   - 검색 필드, 그리드 컬럼, 폼 필드, URL 정의
2. **Stimulus 컨트롤러** (`app/javascript/controllers/<module>_grid_controller.js` 또는 `<module>_crud_controller.js`)
   - `BaseGridController` (인라인 편집) 또는 `BaseCrudController` (모달 CRUD) 상속
3. **Rails 컨트롤러** (`app/controllers/<namespace>/<module>_controller.rb`)
   - `System::BaseController` 상속, JSON 응답

### 공통 규칙

- 네임스페이스별 베이스 컨트롤러를 상속 (예: `System::BaseController`, `Wm::BaseController`)
- 검색 파라미터는 `params.fetch(:q, {}).permit(...)` 패턴
- JSON 응답: `{ success: true/false, message: "...", errors: [...] }`
- 감사 필드(create_by, create_time, update_by, update_time)는 모델 콜백에서 자동 처리
- UI 컴포넌트: `Ui::SearchFormComponent`, `Ui::GridHeaderComponent`, `Ui::AgGridComponent`, `Ui::ModalShellComponent`, `Ui::ResourceFormComponent`

---

## 공통 구성요소 스니펫

### 상태 컬럼 정의 (인라인 편집 그리드 필수)

```ruby
{
  field: "__row_status",
  headerName: "상태",
  width: 68,
  minWidth: 68,
  maxWidth: 68,
  editable: false,
  sortable: false,
  filter: false,
  resizable: false,
  cellStyle: { textAlign: "center" },
  cellRenderer: "rowStatusCellRenderer"
}
```

### 감사 컬럼 정의 (공통)

```ruby
{ field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
{ field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
{ field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
{ field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
```

### 사용여부 셀 (공통)

```ruby
{
  field: "use_yn",
  headerName: "사용여부",
  maxWidth: 110,
  editable: true,
  cellEditor: "agSelectCellEditor",
  cellEditorParams: { values: common_code_values("CMM_USE_YN") },
  cellRenderer: "codeUseYnCellRenderer"
}
```

### 검색 필드 타입별 예시

```ruby
# input 타입
{ field: "zone_cd", type: "input", label: "구역코드", placeholder: "구역코드 검색.." }

# select 타입 (문자열 공통코드)
{
  field: "use_yn",
  type: "select",
  label: "사용여부",
  options: common_code_options("CMM_USE_YN", include_all: true),
  include_blank: false
}

# select 타입 (숫자 공통코드 - WM 도메인)
# 공통코드 그룹이 숫자인 경우 문자열로 감싸서 사용
{
  field: "gr_stat_cd",
  type: "select",
  label: "입고상태",
  options: common_code_options("153", include_all: true),  # "153" 숫자 코드 그룹
  include_blank: false
}

# date_picker 타입
{ field: "start_date", type: "date_picker", label: "시작일" }

# date_range 타입
{ field: "period", type: "date_range", label: "기간" }

# popup 타입 (검색팝업)
{
  field: "item_nm",
  type: "popup",
  label: "품목",
  popup_type: "item",
  code_field: "item_cd"
}
```

### 폼 필드 타입별 예시

```ruby
# input
{ field: "zone_cd", type: "input", label: "구역코드", required: true, maxlength: 50, target: "fieldZoneCd" }

# number
{ field: "sort_order", type: "number", label: "정렬순서", value: 0, min: 0, target: "fieldSortOrder" }

# select
{
  field: "zone_type",
  type: "select",
  label: "구역유형",
  include_blank: true,
  options: [
    { label: "보관", value: "STORAGE" },
    { label: "출고", value: "SHIPPING" }
  ],
  target: "fieldZoneType"
}

# radio
{
  field: "use_yn",
  type: "radio",
  label: "사용여부",
  value: "Y",
  options: [
    { label: "사용", value: "Y" },
    { label: "미사용", value: "N" }
  ]
}

# textarea
{ field: "description", type: "textarea", label: "설명", rows: 4, colspan: 2, maxlength: 500, target: "fieldDescription" }
```

---

## 유형 1: 조회조건 + 인라인 편집 그리드

행추가/행삭제/일괄저장(batch_save) 패턴. 모달 없이 그리드에서 직접 편집합니다.

**기존 참조**: 역할관리(roles)
**예제 도메인**: 창고구역 관리 (warehouse_zone)

### 파일 구성

```
app/components/system/warehouse_zone/page_component.rb
app/components/system/warehouse_zone/page_component.html.erb
app/javascript/controllers/warehouse_zone_grid_controller.js
app/controllers/system/warehouse_zones_controller.rb
app/models/warehouse_zone.rb
db/migrate/YYYYMMDDHHMMSS_create_warehouse_zones.rb
```

### PageComponent (Ruby)

```ruby
# app/components/system/warehouse_zone/page_component.rb
class System::WarehouseZone::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_warehouse_zones_path(**)
    def member_path(id, **) = helpers.system_warehouse_zone_path(id, **)

    def batch_save_url
      helpers.batch_save_system_warehouse_zones_path
    end

    def search_fields
      [
        { field: "zone_cd", type: "input", label: "구역코드", placeholder: "구역코드 검색.." },
        { field: "zone_nm", type: "input", label: "구역명", placeholder: "구역명 검색.." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "zone_cd", headerName: "구역코드", minWidth: 130, editable: true },
        { field: "zone_nm", headerName: "구역명", minWidth: 180, editable: true },
        { field: "zone_type", headerName: "구역유형", minWidth: 130, editable: true },
        { field: "description", headerName: "설명", minWidth: 220, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end
end
```

### ERB 템플릿

```erb
<%# app/components/system/warehouse_zone/page_component.html.erb %>
<div data-controller="warehouse-zone-grid"
     data-action="ag-grid:ready->warehouse-zone-grid#registerGrid"
     data-warehouse-zone-grid-batch-url-value="<%= batch_save_url %>">
  <%= render Ui::SearchFormComponent.new(
    url: create_url,
    fields: search_fields,
    cols: 3,
    enable_collapse: true
  ) %>

  <%= render Ui::GridHeaderComponent.new(
    icon: "warehouse", title: "창고구역 목록", grid_id: "warehouse-zones",
    buttons: [
      { label: "행추가", class: "btn btn-sm btn-primary", action: "click->warehouse-zone-grid#addRow" },
      { label: "행삭제", class: "btn btn-sm btn-danger", action: "click->warehouse-zone-grid#deleteRows" },
      { label: "저장", class: "btn btn-sm btn-success", action: "click->warehouse-zone-grid#saveRows" }
    ]
  ) %>

  <%= render Ui::AgGridComponent.new(
    columns: columns,
    url: grid_url,
    height: "calc(100vh - 370px)",
    pagination: false,
    row_selection: "multiple",
    grid_id: "warehouse-zones",
    data: { warehouse_zone_grid_target: "grid" }
  ) %>
</div>
```

### Stimulus Controller (JS)

```javascript
// app/javascript/controllers/warehouse_zone_grid_controller.js
import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["zone_cd"],
      fields: {
        zone_cd: "trimUpper",
        zone_nm: "trim",
        zone_type: "trim",
        description: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { zone_cd: "", zone_nm: "", zone_type: "", description: "", use_yn: "Y" },
      blankCheckFields: ["zone_cd", "zone_nm"],
      comparableFields: ["zone_nm", "zone_type", "description", "use_yn"],
      firstEditCol: "zone_cd",
      pkLabels: { zone_cd: "구역코드" }
    }
  }

  get saveMessage() {
    return "창고구역 데이터가 저장되었습니다."
  }
}
```

### Rails Controller

```ruby
# app/controllers/system/warehouse_zones_controller.rb
class System::WarehouseZonesController < System::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: zones_scope.map { |z| zone_json(z) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:zone_cd].to_s.strip.blank? && attrs[:zone_nm].to_s.strip.blank?
          next
        end

        zone = WarehouseZone.new(attrs.permit(:zone_cd, :zone_nm, :zone_type, :description, :use_yn))
        if zone.save
          result[:inserted] += 1
        else
          errors.concat(zone.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        zone = WarehouseZone.find_by(zone_cd: attrs[:zone_cd].to_s)
        if zone.nil?
          errors << "구역코드를 찾을 수 없습니다: #{attrs[:zone_cd]}"
          next
        end

        if zone.update(attrs.permit(:zone_nm, :zone_type, :description, :use_yn))
          result[:updated] += 1
        else
          errors.concat(zone.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |zone_cd|
        zone = WarehouseZone.find_by(zone_cd: zone_cd.to_s)
        next if zone.nil?

        if zone.destroy
          result[:deleted] += 1
        else
          errors.concat(zone.errors.full_messages.presence || ["구역 삭제에 실패했습니다: #{zone_cd}"])
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "창고구역 저장이 완료되었습니다.", data: result }
    end
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:zone_cd, :zone_nm, :use_yn)
    end

    def zones_scope
      scope = WarehouseZone.ordered

      if search_params[:zone_cd].present?
        scope = scope.where("zone_cd LIKE ?", "%#{search_params[:zone_cd]}%")
      end
      if search_params[:zone_nm].present?
        scope = scope.where("zone_nm LIKE ?", "%#{search_params[:zone_nm]}%")
      end
      if search_params[:use_yn].present?
        scope = scope.where(use_yn: search_params[:use_yn])
      end

      scope
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [:zone_cd, :zone_nm, :zone_type, :description, :use_yn],
        rowsToUpdate: [:zone_cd, :zone_nm, :zone_type, :description, :use_yn]
      )
    end

    def zone_json(zone)
      {
        id: zone.zone_cd,
        zone_cd: zone.zone_cd,
        zone_nm: zone.zone_nm,
        zone_type: zone.zone_type,
        description: zone.description,
        use_yn: zone.use_yn,
        update_by: zone.update_by,
        update_time: zone.update_time,
        create_by: zone.create_by,
        create_time: zone.create_time
      }
    end
end
```

### Model

```ruby
# app/models/warehouse_zone.rb
class WarehouseZone < ApplicationRecord
  self.table_name = "warehouse_zones"

  validates :zone_cd, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :zone_nm, presence: true, length: { maximum: 100 }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(:zone_cd) }

  private
    def normalize_fields
      self.zone_cd = zone_cd.to_s.strip.upcase
      self.zone_nm = zone_nm.to_s.strip
      self.zone_type = zone_type.to_s.strip.presence
      self.description = description.to_s.strip.presence
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
    end

    def assign_update_audit_fields
      actor = current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_create_audit_fields
      actor = current_actor
      self.create_by = actor
      self.create_time = Time.current
    end

    def current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
```

### Routes

```ruby
# config/routes.rb (namespace :system 내부에 추가)
resources :warehouse_zones, only: [:index] do
  post :batch_save, on: :collection
end
```

### Migration

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_warehouse_zones.rb
class CreateWarehouseZones < ActiveRecord::Migration[8.1]
  def change
    create_table :warehouse_zones, id: false do |t|
      t.string :zone_cd, limit: 50, null: false
      t.string :zone_nm, limit: 100, null: false
      t.string :zone_type, limit: 50
      t.string :description, limit: 500
      t.string :use_yn, limit: 1, default: "Y", null: false
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :warehouse_zones, :zone_cd, unique: true
  end
end
```

---

## 유형 2: 조회조건 + 마스터 그리드 + 디테일 그리드

마스터-디테일(1:N) 구조. 마스터 행 선택 시 디테일 그리드가 Ajax로 로드됩니다. 각 그리드는 독립적으로 행추가/행삭제/저장 가능합니다.

**기존 참조**: 공통코드(code) 관리
**예제 도메인**: 거래처 관리 (partner 마스터 + partner_contact 디테일)

### 파일 구성

```
app/components/system/partner/page_component.rb
app/components/system/partner/page_component.html.erb
app/javascript/controllers/partner_grid_controller.js
app/controllers/system/partners_controller.rb
app/controllers/system/partner_contacts_controller.rb
app/models/partner.rb
app/models/partner_contact.rb
db/migrate/YYYYMMDDHHMMSS_create_partners.rb
db/migrate/YYYYMMDDHHMMSS_create_partner_contacts.rb
```

### PageComponent (Ruby)

```ruby
# app/components/system/partner/page_component.rb
class System::Partner::PageComponent < System::BasePageComponent
  def initialize(query_params:, selected_partner:)
    super(query_params: query_params)
    @selected_partner = selected_partner.presence
  end

  private
    attr_reader :selected_partner

    def collection_path(**) = helpers.system_partners_path(**)
    def member_path(id, **) = helpers.system_partner_path(id, **)

    def detail_grid_url
      return nil if selected_partner.blank?
      helpers.system_partner_contacts_path(selected_partner, format: :json)
    end

    def master_batch_save_url
      helpers.batch_save_system_partners_path
    end

    def detail_batch_save_url_template
      "/system/partners/:partner_cd/contacts/batch_save"
    end

    def selected_partner_label
      selected_partner.present? ? "선택 거래처: #{selected_partner}" : "거래처를 먼저 선택하세요."
    end

    def search_fields
      [
        { field: "partner_cd", type: "input", label: "거래처코드", placeholder: "거래처코드 검색.." },
        { field: "partner_nm", type: "input", label: "거래처명", placeholder: "거래처명 검색.." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def master_columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "partner_cd", headerName: "거래처코드", minWidth: 130, editable: true },
        { field: "partner_nm", headerName: "거래처명", minWidth: 180, editable: true },
        { field: "partner_type", headerName: "거래처유형", minWidth: 130, editable: true },
        { field: "biz_no", headerName: "사업자번호", minWidth: 150, editable: true },
        { field: "address", headerName: "주소", minWidth: 220, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end

    def detail_columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "contact_nm", headerName: "담당자명", minWidth: 150, editable: true },
        { field: "contact_tel", headerName: "연락처", minWidth: 150, editable: true },
        { field: "contact_email", headerName: "이메일", minWidth: 200, editable: true },
        { field: "department", headerName: "부서", minWidth: 130, editable: true },
        { field: "position", headerName: "직위", minWidth: 100, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end
end
```

### ERB 템플릿

```erb
<%# app/components/system/partner/page_component.html.erb %>
<div data-controller="partner-grid"
     data-action="ag-grid:ready->partner-grid#registerGrid"
     data-partner-grid-master-batch-url-value="<%= master_batch_save_url %>"
     data-partner-grid-detail-batch-url-template-value="<%= detail_batch_save_url_template %>"
     data-partner-grid-detail-list-url-template-value="/system/partners/:partner_cd/contacts.json"
     data-partner-grid-selected-partner-value="<%= selected_partner.to_s %>">
  <%= render Ui::SearchFormComponent.new(
    url: create_url,
    fields: search_fields,
    cols: 3,
    enable_collapse: true
  ) %>

  <div class="grid grid-cols-2 gap-3 max-[1200px]:grid-cols-1">
    <section class="min-w-0">
      <%= render Ui::GridHeaderComponent.new(
        icon: "building-2", title: "거래처 목록", grid_id: "partner-master",
        buttons: [
          { label: "행추가", class: "btn btn-sm btn-primary", action: "click->partner-grid#addMasterRow" },
          { label: "행삭제", class: "btn btn-sm btn-danger", action: "click->partner-grid#deleteMasterRows" },
          { label: "저장", class: "btn btn-sm btn-success", action: "click->partner-grid#saveMasterRows" }
        ]
      ) %>

      <%= render Ui::AgGridComponent.new(
        columns: master_columns,
        url: grid_url,
        height: "calc(100vh - 420px)",
        pagination: false,
        row_selection: "multiple",
        grid_id: "partner-master",
        data: { partner_grid_target: "masterGrid" }
      ) %>
    </section>

    <section class="min-w-0">
      <%= render Ui::GridHeaderComponent.new(
        icon: "users", title: "담당자 목록", grid_id: "partner-contact",
        buttons: [
          { label: "행추가", class: "btn btn-sm btn-primary", action: "click->partner-grid#addDetailRow" },
          { label: "행삭제", class: "btn btn-sm btn-danger", action: "click->partner-grid#deleteDetailRows" },
          { label: "저장", class: "btn btn-sm btn-success", action: "click->partner-grid#saveDetailRows" }
        ]
      ) do |header| %>
        <% header.with_subtitle do %>
          <p class="text-text-secondary text-xs" data-partner-grid-target="selectedPartnerLabel"><%= selected_partner_label %></p>
        <% end %>
      <% end %>

      <% if detail_grid_url.present? %>
        <%= render Ui::AgGridComponent.new(
          columns: detail_columns,
          url: detail_grid_url,
          height: "calc(100vh - 420px)",
          pagination: false,
          row_selection: "multiple",
          grid_id: "partner-contact",
          data: { partner_grid_target: "detailGrid" }
        ) %>
      <% else %>
        <%= render Ui::AgGridComponent.new(
          columns: detail_columns,
          row_data: [],
          height: "calc(100vh - 420px)",
          pagination: false,
          row_selection: "multiple",
          grid_id: "partner-contact",
          data: { partner_grid_target: "detailGrid" }
        ) %>
      <% end %>
    </section>
  </div>
</div>
```

### Stimulus Controller (JS)

```javascript
// app/javascript/controllers/partner_grid_controller.js
import BaseGridController from "controllers/base_grid_controller"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, fetchJson, setManagerRowData, focusFirstRow, hasPendingChanges, blockIfPendingChanges, buildTemplateUrl, refreshSelectionLabel } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedPartnerLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedPartner: String
  }

  connect() {
    super.connect()
    this.initialMasterSyncDone = false
    this.masterGridEvents = new GridEventManager()
    this.detailGridController = null
    this.detailManager = null
  }

  disconnect() {
    this.masterGridEvents.unbindAll()
    if (this.detailManager) {
      this.detailManager.detach()
      this.detailManager = null
    }
    this.detailGridController = null
    super.disconnect()
  }

  // 마스터 그리드 CRUD 설정
  configureManager() {
    return {
      pkFields: ["partner_cd"],
      fields: {
        partner_cd: "trimUpper",
        partner_nm: "trim",
        partner_type: "trim",
        biz_no: "trim",
        address: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { partner_cd: "", partner_nm: "", partner_type: "", biz_no: "", address: "", use_yn: "Y" },
      blankCheckFields: ["partner_cd", "partner_nm"],
      comparableFields: ["partner_nm", "partner_type", "biz_no", "address", "use_yn"],
      firstEditCol: "partner_cd",
      pkLabels: { partner_cd: "거래처코드" },
      onRowDataUpdated: () => {
        this.detailManager?.resetTracking()
        if (!this.initialMasterSyncDone && isApiAlive(this.detailManager?.api)) {
          this.initialMasterSyncDone = true
          this.syncMasterSelectionAfterLoad()
        }
      }
    }
  }

  // 디테일 그리드 CRUD 설정
  configureDetailManager() {
    return {
      pkFields: ["id"],
      fields: {
        contact_nm: "trim",
        contact_tel: "trim",
        contact_email: "trim",
        department: "trim",
        position: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { contact_nm: "", contact_tel: "", contact_email: "", department: "", position: "", use_yn: "Y" },
      blankCheckFields: ["contact_nm"],
      comparableFields: ["contact_nm", "contact_tel", "contact_email", "department", "position", "use_yn"],
      firstEditCol: "contact_nm",
      pkLabels: { id: "ID" }
    }
  }

  // 그리드 등록 분기 (마스터 / 디테일)
  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

    if (gridElement === this.masterGridTarget) {
      super.registerGrid(event)
    } else if (gridElement === this.detailGridTarget) {
      if (this.detailManager) this.detailManager.detach()
      this.detailGridController = controller
      this.detailManager = new GridCrudManager(this.configureDetailManager())
      this.detailManager.attach(api)
    }

    if (this.manager?.api && this.detailManager?.api) {
      this.bindMasterGridEvents()
      if (!this.initialMasterSyncDone) {
        this.initialMasterSyncDone = true
        this.syncMasterSelectionAfterLoad()
      }
    }
  }

  // 마스터 그리드 이벤트 바인딩
  bindMasterGridEvents() {
    this.masterGridEvents.unbindAll()
    this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterRowClicked)
    this.masterGridEvents.bind(this.manager?.api, "cellFocused", this.handleMasterCellFocused)
  }

  handleMasterRowClicked = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    await this.handleMasterRowChange(rowData)
  }

  handleMasterCellFocused = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    if (!rowData) return
    await this.handleMasterRowChange(rowData)
  }

  async handleMasterRowChange(rowData) {
    if (!isApiAlive(this.detailManager?.api)) return

    const partnerCd = rowData?.partner_cd
    if (!partnerCd || rowData?.__is_deleted || rowData?.__is_new) {
      this.selectedPartnerValue = partnerCd || ""
      this.refreshSelectedPartnerLabel()
      this.clearDetailRows()
      return
    }

    this.selectedPartnerValue = partnerCd
    this.refreshSelectedPartnerLabel()
    await this.loadDetailRows(partnerCd)
  }

  // ─── 마스터 액션 ───

  addMasterRow() {
    if (!this.manager) return
    const txResult = this.manager.addRow()
    const addedNode = txResult?.add?.[0]
    if (addedNode?.data) this.handleMasterRowChange(addedNode.data)
  }

  deleteMasterRows() {
    if (!this.manager) return
    this.manager.deleteRows()
  }

  async saveMasterRows() {
    if (!this.manager) return
    this.manager.stopEditing()
    const operations = this.manager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const ok = await postJson(this.masterBatchUrlValue, operations)
    if (!ok) return

    alert("거래처 데이터가 저장되었습니다.")
    await this.reloadMasterRows()
  }

  async reloadMasterRows() {
    if (!isApiAlive(this.manager?.api)) return
    if (!this.gridController?.urlValue) return

    try {
      const rows = await fetchJson(this.gridController.urlValue)
      setManagerRowData(this.manager, rows)
      await this.syncMasterSelectionAfterLoad()
    } catch {
      alert("거래처 목록 조회에 실패했습니다.")
    }
  }

  async syncMasterSelectionAfterLoad() {
    if (!isApiAlive(this.manager?.api) || !isApiAlive(this.detailManager?.api)) return

    const firstData = focusFirstRow(this.manager.api)
    if (!firstData) {
      this.selectedPartnerValue = ""
      this.refreshSelectedPartnerLabel()
      this.clearDetailRows()
      return
    }

    await this.handleMasterRowChange(firstData)
  }

  // ─── 디테일 액션 ───

  addDetailRow() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return
    if (!this.selectedPartnerValue) {
      alert("거래처를 먼저 선택해주세요.")
      return
    }
    this.detailManager.addRow({ partner_cd: this.selectedPartnerValue })
  }

  deleteDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return
    this.detailManager.deleteRows()
  }

  async saveDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return
    if (!this.selectedPartnerValue) {
      alert("거래처를 먼저 선택해주세요.")
      return
    }

    this.detailManager.stopEditing()
    const operations = this.detailManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":partner_cd", this.selectedPartnerValue)
    const ok = await postJson(batchUrl, operations)
    if (!ok) return

    alert("담당자 데이터가 저장되었습니다.")
    await this.loadDetailRows(this.selectedPartnerValue)
  }

  async loadDetailRows(partnerCd) {
    if (!isApiAlive(this.detailManager?.api)) return
    if (!partnerCd) {
      this.clearDetailRows()
      return
    }

    try {
      const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":partner_cd", partnerCd)
      const rows = await fetchJson(url)
      setManagerRowData(this.detailManager, rows)
    } catch {
      alert("담당자 목록 조회에 실패했습니다.")
    }
  }

  clearDetailRows() {
    setManagerRowData(this.detailManager, [])
  }

  refreshSelectedPartnerLabel() {
    if (!this.hasSelectedPartnerLabelTarget) return
    refreshSelectionLabel(this.selectedPartnerLabelTarget, this.selectedPartnerValue, "거래처", "거래처를 먼저 선택하세요.")
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.manager, "마스터 거래처")
  }
}
```

### Routes

```ruby
# config/routes.rb (namespace :system 내부에 추가)
resources :partners, only: [:index] do
  post :batch_save, on: :collection
  resources :contacts, controller: :partner_contacts, only: [:index] do
    post :batch_save, on: :collection
  end
end
```

---

## 유형 3: 조회조건 + 그리드 + 입력 팝업(모달)

그리드에서 목록을 표시하고, 등록/수정/삭제는 모달 폼으로 처리합니다.

**기존 참조**: 부서관리(dept), 사용자관리(users)
**예제 도메인**: 품목 관리 (item)

### 파일 구성

```
app/components/system/item/page_component.rb
app/components/system/item/page_component.html.erb
app/javascript/controllers/item_crud_controller.js
app/controllers/system/items_controller.rb
app/models/item.rb
db/migrate/YYYYMMDDHHMMSS_create_items.rb
```

### PageComponent (Ruby)

```ruby
# app/components/system/item/page_component.rb
class System::Item::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_items_path(**)
    def member_path(id, **) = helpers.system_item_path(id, **)

    def search_fields
      [
        { field: "item_cd", type: "input", label: "품목코드", placeholder: "품목코드 검색.." },
        { field: "item_nm", type: "input", label: "품목명", placeholder: "품목명 검색.." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        { field: "item_cd", headerName: "품목코드", minWidth: 130 },
        { field: "item_nm", headerName: "품목명", minWidth: 200 },
        { field: "item_type", headerName: "품목유형", minWidth: 130 },
        { field: "unit", headerName: "단위", minWidth: 80 },
        { field: "spec", headerName: "규격", minWidth: 150 },
        { field: "use_yn", headerName: "사용여부", maxWidth: 100, cellRenderer: "codeUseYnCellRenderer" },
        { field: "update_by", headerName: "수정자", minWidth: 100 },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime" },
        { field: "create_by", headerName: "생성자", minWidth: 100 },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime" },
        {
          field: "actions",
          headerName: "작업",
          minWidth: 120,
          maxWidth: 120,
          filter: false,
          sortable: false,
          cellClass: "ag-cell-actions",
          cellRenderer: "editDeleteActionCellRenderer"
        }
      ]
    end

    def form_fields
      [
        { field: "item_cd", type: "input", label: "품목코드", required: true, maxlength: 50, target: "fieldItemCd" },
        { field: "item_nm", type: "input", label: "품목명", required: true, maxlength: 200, target: "fieldItemNm" },
        {
          field: "item_type",
          type: "select",
          label: "품목유형",
          include_blank: true,
          options: [
            { label: "원자재", value: "RAW" },
            { label: "완제품", value: "FINISHED" },
            { label: "반제품", value: "SEMI" }
          ],
          target: "fieldItemType"
        },
        { field: "unit", type: "input", label: "단위", maxlength: 20, target: "fieldUnit" },
        { field: "spec", type: "input", label: "규격", maxlength: 200, target: "fieldSpec" },
        {
          field: "use_yn",
          type: "radio",
          label: "사용여부",
          value: "Y",
          options: [
            { label: "사용", value: "Y" },
            { label: "미사용", value: "N" }
          ]
        },
        { field: "description", type: "textarea", label: "설명", rows: 4, colspan: 2, maxlength: 500, target: "fieldDescription" }
      ]
    end
end
```

### ERB 템플릿

```erb
<%# app/components/system/item/page_component.html.erb %>
<div data-controller="item-crud"
     data-item-crud-create-url-value="<%= create_url %>"
     data-item-crud-update-url-value="<%= update_url %>"
     data-item-crud-delete-url-value="<%= delete_url %>">
  <%= render Ui::SearchFormComponent.new(
    url: create_url,
    fields: search_fields,
    cols: 3,
    enable_collapse: true
  ) %>

  <%= render Ui::GridHeaderComponent.new(
    icon: "package", title: "품목 목록", grid_id: "items",
    buttons: [
      { label: "추가", class: "btn btn-sm btn-primary", action: "click->item-crud#openCreate" }
    ]
  ) %>

  <%= render Ui::AgGridComponent.new(
    columns: columns,
    url: grid_url,
    height: "calc(100vh - 370px)",
    pagination: false,
    grid_id: "items"
  ) %>

  <%= render Ui::ModalShellComponent.new(
    controller: "item-crud",
    title: "품목 추가",
    save_form_id: "item-crud-form",
    cancel_role: "cancel",
    save_role: "save"
  ) do |modal| %>
    <% modal.with_body do %>
      <input type="hidden" data-item-crud-target="fieldId" />

      <%= render Ui::ResourceFormComponent.new(
        model: Item.new,
        url: "#",
        cols: 2,
        show_buttons: false,
        target_controller: "item_crud",
        fields: form_fields,
        form_data: {
          item_crud_target: "form",
          action: "submit->resource-form#submit submit->item-crud#submit"
        },
        form_html: {
          id: "item-crud-form",
          novalidate: true,
          autocomplete: "off"
        }
      ) %>
    <% end %>
  <% end %>
</div>
```

### Stimulus Controller (JS)

```javascript
// app/javascript/controllers/item_crud_controller.js
import BaseCrudController from "controllers/base_crud_controller"

export default class extends BaseCrudController {
  static resourceName = "item"
  static deleteConfirmKey = "item_nm"
  static entityLabel = "품목"

  static targets = [
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldItemCd", "fieldItemNm", "fieldItemType",
    "fieldUnit", "fieldSpec", "fieldDescription"
  ]

  static values = {
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    this.connectBase({
      events: [
        { name: "item-crud:edit", handler: this.handleEdit },
        { name: "item-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
  }

  // 신규 등록 모달
  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "품목 추가"
    this.fieldItemCdTarget.readOnly = false
    this.mode = "create"
    this.openModal()
  }

  // 수정 모달 (그리드 셀 렌더러에서 이벤트 발생)
  handleEdit = (event) => {
    const data = event.detail
    this.resetForm()
    this.modalTitleTarget.textContent = "품목 수정"

    this.fieldIdTarget.value = data.id
    this.fieldItemCdTarget.value = data.item_cd || ""
    this.fieldItemCdTarget.readOnly = true
    this.fieldItemNmTarget.value = data.item_nm || ""
    this.fieldItemTypeTarget.value = data.item_type || ""
    this.fieldUnitTarget.value = data.unit || ""
    this.fieldSpecTarget.value = data.spec || ""
    this.fieldDescriptionTarget.value = data.description || ""

    // 라디오 버튼 설정
    if (String(data.use_yn || "Y") === "N") {
      this.formTarget.querySelectorAll("input[type='radio'][name='item[use_yn]']").forEach((radio) => {
        radio.checked = radio.value === "N"
      })
    }

    this.mode = "update"
    this.openModal()
  }

  // 폼 초기화
  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.formTarget.querySelectorAll("input[type='radio'][name='item[use_yn]']").forEach((radio) => {
      radio.checked = radio.value === "Y"
    })
  }
}
```

### Rails Controller

```ruby
# app/controllers/system/items_controller.rb
class System::ItemsController < System::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: items_scope.map { |item| item_json(item) } }
    end
  end

  def create
    item = Item.new(item_params)
    if item.save
      render json: { success: true, message: "품목이 추가되었습니다.", item: item_json(item) }
    else
      render json: { success: false, errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    item = find_item
    attrs = item_params.to_h
    attrs.delete("item_cd")

    if item.update(attrs)
      render json: { success: true, message: "품목이 수정되었습니다.", item: item_json(item) }
    else
      render json: { success: false, errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    item = find_item
    item.destroy
    render json: { success: true, message: "품목이 삭제되었습니다." }
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:item_cd, :item_nm, :use_yn)
    end

    def items_scope
      scope = Item.ordered

      if search_params[:item_cd].present?
        scope = scope.where("item_cd LIKE ?", "%#{search_params[:item_cd]}%")
      end
      if search_params[:item_nm].present?
        scope = scope.where("item_nm LIKE ?", "%#{search_params[:item_nm]}%")
      end
      if search_params[:use_yn].present?
        scope = scope.where(use_yn: search_params[:use_yn])
      end

      scope
    end

    def item_params
      params.require(:item).permit(:item_cd, :item_nm, :item_type, :unit, :spec, :description, :use_yn)
    end

    def find_item
      Item.find_by!(item_cd: params[:id].to_s.strip.upcase)
    end

    def item_json(item)
      {
        id: item.item_cd,
        item_cd: item.item_cd,
        item_nm: item.item_nm,
        item_type: item.item_type,
        unit: item.unit,
        spec: item.spec,
        description: item.description,
        use_yn: item.use_yn,
        update_by: item.update_by,
        update_time: item.update_time,
        create_by: item.create_by,
        create_time: item.create_time
      }
    end
end
```

### Routes

```ruby
# config/routes.rb (namespace :system 내부에 추가)
resources :items, only: [:index, :create, :update, :destroy]
```

---

## 유형 4: 조회조건 + 그리드 + 탭 구성

상단에 공유 그리드, 하단에 탭별 독립 콘텐츠 영역을 구성합니다.

**기존 참조**: 신규 패턴 (기존 컴포넌트 조합으로 구현)
**예제 도메인**: 재고 관리 (inventory) — 현황/이력/조정 탭

### 파일 구성

```
app/components/system/inventory/page_component.rb
app/components/system/inventory/page_component.html.erb
app/javascript/controllers/inventory_grid_controller.js
app/controllers/system/inventories_controller.rb
app/models/inventory.rb
```

### PageComponent (Ruby)

```ruby
# app/components/system/inventory/page_component.rb
class System::Inventory::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_inventories_path(**)
    def member_path(id, **) = helpers.system_inventory_path(id, **)

    def history_url_template
      "/system/inventories/:id/histories.json"
    end

    def adjustment_url_template
      "/system/inventories/:id/adjustments.json"
    end

    def search_fields
      [
        { field: "item_cd", type: "input", label: "품목코드", placeholder: "품목코드 검색.." },
        { field: "item_nm", type: "input", label: "품목명", placeholder: "품목명 검색.." },
        { field: "zone_cd", type: "input", label: "구역코드", placeholder: "구역코드 검색.." }
      ]
    end

    def main_columns
      [
        { field: "item_cd", headerName: "품목코드", minWidth: 130 },
        { field: "item_nm", headerName: "품목명", minWidth: 200 },
        { field: "zone_cd", headerName: "구역코드", minWidth: 130 },
        { field: "lot_no", headerName: "LOT번호", minWidth: 150 },
        { field: "qty", headerName: "재고수량", minWidth: 120, type: "numericColumn" },
        { field: "unit", headerName: "단위", minWidth: 80 },
        { field: "update_time", headerName: "최종변경일시", minWidth: 170, formatter: "datetime" }
      ]
    end

    def history_columns
      [
        { field: "history_type", headerName: "유형", minWidth: 100 },
        { field: "qty_change", headerName: "변동수량", minWidth: 120, type: "numericColumn" },
        { field: "qty_after", headerName: "변동후수량", minWidth: 120, type: "numericColumn" },
        { field: "reason", headerName: "사유", minWidth: 200 },
        { field: "create_by", headerName: "처리자", minWidth: 100 },
        { field: "create_time", headerName: "처리일시", minWidth: 170, formatter: "datetime" }
      ]
    end

    def adjustment_columns
      [
        { field: "adjust_type", headerName: "조정유형", minWidth: 130 },
        { field: "adjust_qty", headerName: "조정수량", minWidth: 120, type: "numericColumn" },
        { field: "adjust_reason", headerName: "조정사유", minWidth: 250 },
        { field: "status", headerName: "상태", minWidth: 100 },
        { field: "create_by", headerName: "요청자", minWidth: 100 },
        { field: "create_time", headerName: "요청일시", minWidth: 170, formatter: "datetime" }
      ]
    end
end
```

### ERB 템플릿

```erb
<%# app/components/system/inventory/page_component.html.erb %>
<div data-controller="inventory-grid"
     data-action="ag-grid:ready->inventory-grid#registerGrid"
     data-inventory-grid-history-url-template-value="<%= history_url_template %>"
     data-inventory-grid-adjustment-url-template-value="<%= adjustment_url_template %>">
  <%= render Ui::SearchFormComponent.new(
    url: create_url,
    fields: search_fields,
    cols: 3,
    enable_collapse: true
  ) %>

  <%# 상단: 메인 재고 그리드 %>
  <%= render Ui::GridHeaderComponent.new(
    icon: "boxes", title: "재고 현황", grid_id: "inventory-main"
  ) %>

  <%= render Ui::AgGridComponent.new(
    columns: main_columns,
    url: grid_url,
    height: "calc(50vh - 250px)",
    pagination: false,
    row_selection: "single",
    grid_id: "inventory-main",
    data: { inventory_grid_target: "mainGrid" }
  ) %>

  <%# 하단: 탭 영역 %>
  <div class="mt-3">
    <div class="flex border-b border-border">
      <button type="button"
              class="px-4 py-2 text-sm font-medium border-b-2 border-primary text-primary"
              data-inventory-grid-target="tabBtn"
              data-action="click->inventory-grid#switchTab"
              data-tab="history">이력</button>
      <button type="button"
              class="px-4 py-2 text-sm font-medium border-b-2 border-transparent text-text-secondary hover:text-text-primary"
              data-inventory-grid-target="tabBtn"
              data-action="click->inventory-grid#switchTab"
              data-tab="adjustment">조정</button>
    </div>

    <%# 이력 탭 %>
    <div data-inventory-grid-target="tabPanel" data-tab="history">
      <%= render Ui::GridHeaderComponent.new(
        icon: "history", title: "재고 이력", grid_id: "inventory-history"
      ) %>
      <%= render Ui::AgGridComponent.new(
        columns: history_columns,
        row_data: [],
        height: "calc(50vh - 280px)",
        pagination: false,
        grid_id: "inventory-history",
        data: { inventory_grid_target: "historyGrid" }
      ) %>
    </div>

    <%# 조정 탭 %>
    <div data-inventory-grid-target="tabPanel" data-tab="adjustment" hidden>
      <%= render Ui::GridHeaderComponent.new(
        icon: "sliders-horizontal", title: "재고 조정", grid_id: "inventory-adjustment"
      ) %>
      <%= render Ui::AgGridComponent.new(
        columns: adjustment_columns,
        row_data: [],
        height: "calc(50vh - 280px)",
        pagination: false,
        grid_id: "inventory-adjustment",
        data: { inventory_grid_target: "adjustmentGrid" }
      ) %>
    </div>
  </div>
</div>
```

### Stimulus Controller (JS)

```javascript
// app/javascript/controllers/inventory_grid_controller.js
import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, fetchJson, setGridRowData, buildTemplateUrl } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "mainGrid", "historyGrid", "adjustmentGrid",
    "tabBtn", "tabPanel"
  ]

  static values = {
    ...BaseGridController.values,
    historyUrlTemplate: String,
    adjustmentUrlTemplate: String
  }

  connect() {
    super.connect()
    this.mainGridEvents = new GridEventManager()
    this.#gridApis = {}
    this.#activeTab = "history"
    this.#selectedId = null
  }

  disconnect() {
    this.mainGridEvents.unbindAll()
    super.disconnect()
  }

  // Manager 없이 읽기 전용
  configureManager() { return null }

  // 그리드 등록
  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

    if (gridElement === this.mainGridTarget) {
      super.registerGrid(event)
      this.#gridApis.main = api
      this.mainGridEvents.bind(api, "rowClicked", this.#handleMainRowClicked)
    } else if (gridElement === this.historyGridTarget) {
      this.#gridApis.history = api
    } else if (gridElement === this.adjustmentGridTarget) {
      this.#gridApis.adjustment = api
    }
  }

  // 탭 전환
  switchTab(event) {
    const tab = event.currentTarget.dataset.tab
    this.#activeTab = tab

    // 탭 버튼 스타일 전환
    this.tabBtnTargets.forEach((btn) => {
      const isActive = btn.dataset.tab === tab
      btn.classList.toggle("border-primary", isActive)
      btn.classList.toggle("text-primary", isActive)
      btn.classList.toggle("border-transparent", !isActive)
      btn.classList.toggle("text-text-secondary", !isActive)
    })

    // 탭 패널 표시/숨김
    this.tabPanelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tab !== tab
    })

    // 선택된 행이 있으면 해당 탭 데이터 로드
    if (this.#selectedId) {
      this.#loadTabData(tab, this.#selectedId)
    }
  }

  // ─── Private ───

  #gridApis
  #activeTab
  #selectedId

  #handleMainRowClicked = async (event) => {
    const rowData = rowDataFromGridEvent(this.#gridApis.main, event)
    if (!rowData?.id) return

    this.#selectedId = rowData.id
    await this.#loadTabData(this.#activeTab, rowData.id)
  }

  async #loadTabData(tab, id) {
    try {
      if (tab === "history") {
        const url = buildTemplateUrl(this.historyUrlTemplateValue, ":id", id)
        const rows = await fetchJson(url)
        if (isApiAlive(this.#gridApis.history)) {
          setGridRowData(this.#gridApis.history, rows)
        }
      } else if (tab === "adjustment") {
        const url = buildTemplateUrl(this.adjustmentUrlTemplateValue, ":id", id)
        const rows = await fetchJson(url)
        if (isApiAlive(this.#gridApis.adjustment)) {
          setGridRowData(this.#gridApis.adjustment, rows)
        }
      }
    } catch {
      alert(`${tab} 데이터 조회에 실패했습니다.`)
    }
  }
}
```

### Routes

```ruby
# config/routes.rb (namespace :system 내부에 추가)
resources :inventories, only: [:index] do
  member do
    get :histories
    get :adjustments
  end
end
```

---

## 유형 5: 조회조건 + 마스터 그리드 + 디테일 탭

유형2(마스터-디테일) + 유형4(탭) 결합. 마스터 행 선택 시 하단 탭 전체가 갱신됩니다.

**기존 참조**: `app/components/wm/gr_prars/page_component.rb` (입고관리 실구현 P4-4 패턴)
**예제 도메인**: 입고 관리 (inbound) — 마스터 + 하단 탭(상세/이력)

> **P4-4 패턴 특징**: 마스터 그리드 읽기 전용 + 탭 내 커스텀 액션버튼(저장/확정/취소) + AG Grid 탭 전환 시 sizeColumnsToFit 호출

### 파일 구성

```
app/components/system/inbound/page_component.rb
app/components/system/inbound/page_component.html.erb
app/javascript/controllers/inbound_grid_controller.js
app/controllers/system/inbounds_controller.rb
app/models/inbound.rb
app/models/inbound_detail.rb
```

### PageComponent (Ruby)

```ruby
# app/components/system/inbound/page_component.rb
class System::Inbound::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_inbounds_path(**)
    def member_path(id, **) = helpers.system_inbound_path(id, **)

    def detail_batch_save_url_template
      "/system/inbounds/:id/details/batch_save"
    end

    def search_fields
      [
        { field: "inbound_no", type: "input", label: "입고번호", placeholder: "입고번호 검색.." },
        { field: "partner_nm", type: "input", label: "거래처명", placeholder: "거래처명 검색.." },
        { field: "inbound_date", type: "date_range", label: "입고일자" }
      ]
    end

    def master_columns
      [
        { field: "inbound_no", headerName: "입고번호", minWidth: 150 },
        { field: "inbound_date", headerName: "입고일자", minWidth: 120 },
        { field: "partner_cd", headerName: "거래처코드", minWidth: 130 },
        { field: "partner_nm", headerName: "거래처명", minWidth: 180 },
        { field: "status", headerName: "상태", minWidth: 100 },
        { field: "total_qty", headerName: "총수량", minWidth: 100, type: "numericColumn" },
        { field: "create_by", headerName: "등록자", minWidth: 100 },
        { field: "create_time", headerName: "등록일시", minWidth: 170, formatter: "datetime" }
      ]
    end

    def detail_columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "item_cd", headerName: "품목코드", minWidth: 130, editable: true },
        { field: "item_nm", headerName: "품목명", minWidth: 200, editable: true },
        { field: "qty", headerName: "입고수량", minWidth: 120, editable: true, type: "numericColumn" },
        { field: "unit", headerName: "단위", minWidth: 80, editable: true },
        { field: "lot_no", headerName: "LOT번호", minWidth: 150, editable: true },
        { field: "zone_cd", headerName: "입고구역", minWidth: 130, editable: true },
        { field: "rmk", headerName: "비고", minWidth: 200, editable: true }
      ]
    end

    def history_columns
      [
        { field: "action", headerName: "작업", minWidth: 100 },
        { field: "description", headerName: "내용", minWidth: 300 },
        { field: "create_by", headerName: "처리자", minWidth: 100 },
        { field: "create_time", headerName: "처리일시", minWidth: 170, formatter: "datetime" }
      ]
    end
end
```

### ERB 템플릿

```erb
<%# app/components/system/inbound/page_component.html.erb %>
<div data-controller="inbound-grid"
     data-action="ag-grid:ready->inbound-grid#registerGrid"
     data-inbound-grid-detail-batch-url-template-value="<%= detail_batch_save_url_template %>"
     data-inbound-grid-detail-list-url-template-value="/system/inbounds/:id/details.json"
     data-inbound-grid-history-url-template-value="/system/inbounds/:id/histories.json">
  <%= render Ui::SearchFormComponent.new(
    url: create_url,
    fields: search_fields,
    cols: 3,
    enable_collapse: true
  ) %>

  <%# 상단: 마스터 입고 그리드 %>
  <%= render Ui::GridHeaderComponent.new(
    icon: "package-check", title: "입고 목록", grid_id: "inbound-master"
  ) %>

  <%= render Ui::AgGridComponent.new(
    columns: master_columns,
    url: grid_url,
    height: "calc(40vh - 200px)",
    pagination: false,
    row_selection: "single",
    grid_id: "inbound-master",
    data: { inbound_grid_target: "masterGrid" }
  ) %>

  <%# 하단: 디테일 탭 영역 %>
  <div class="mt-3">
    <div class="flex items-center justify-between border-b border-border">
      <div class="flex">
        <button type="button"
                class="px-4 py-2 text-sm font-medium border-b-2 border-primary text-primary"
                data-inbound-grid-target="tabBtn"
                data-action="click->inbound-grid#switchTab"
                data-tab="detail">입고상세</button>
        <button type="button"
                class="px-4 py-2 text-sm font-medium border-b-2 border-transparent text-text-secondary hover:text-text-primary"
                data-inbound-grid-target="tabBtn"
                data-action="click->inbound-grid#switchTab"
                data-tab="history">처리이력</button>
      </div>
      <p class="text-text-secondary text-xs pr-2" data-inbound-grid-target="selectedLabel">입고를 선택하세요.</p>
    </div>

    <%# 상세 탭 (인라인 편집 그리드) %>
    <div data-inbound-grid-target="tabPanel" data-tab="detail">
      <%= render Ui::GridHeaderComponent.new(
        icon: "list", title: "입고 상세", grid_id: "inbound-detail",
        buttons: [
          { label: "행추가", class: "btn btn-sm btn-primary", action: "click->inbound-grid#addDetailRow" },
          { label: "행삭제", class: "btn btn-sm btn-danger", action: "click->inbound-grid#deleteDetailRows" },
          { label: "저장", class: "btn btn-sm btn-success", action: "click->inbound-grid#saveDetailRows" }
        ]
      ) %>
      <%= render Ui::AgGridComponent.new(
        columns: detail_columns,
        row_data: [],
        height: "calc(40vh - 200px)",
        pagination: false,
        row_selection: "multiple",
        grid_id: "inbound-detail",
        data: { inbound_grid_target: "detailGrid" }
      ) %>
    </div>

    <%# 이력 탭 (읽기 전용 그리드) %>
    <div data-inbound-grid-target="tabPanel" data-tab="history" hidden>
      <%= render Ui::GridHeaderComponent.new(
        icon: "history", title: "처리 이력", grid_id: "inbound-history"
      ) %>
      <%= render Ui::AgGridComponent.new(
        columns: history_columns,
        row_data: [],
        height: "calc(40vh - 200px)",
        pagination: false,
        grid_id: "inbound-history",
        data: { inbound_grid_target: "historyGrid" }
      ) %>
    </div>
  </div>
</div>
```

### Stimulus Controller (JS)

```javascript
// app/javascript/controllers/inbound_grid_controller.js
import BaseGridController from "controllers/base_grid_controller"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, postJson, hasChanges, fetchJson, setGridRowData, setManagerRowData, buildTemplateUrl, refreshSelectionLabel } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid", "detailGrid", "historyGrid",
    "tabBtn", "tabPanel", "selectedLabel"
  ]

  static values = {
    ...BaseGridController.values,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    historyUrlTemplate: String
  }

  connect() {
    super.connect()
    this.masterGridEvents = new GridEventManager()
    this.detailManager = null
    this.#gridApis = {}
    this.#activeTab = "detail"
    this.#selectedId = null
  }

  disconnect() {
    this.masterGridEvents.unbindAll()
    if (this.detailManager) {
      this.detailManager.detach()
      this.detailManager = null
    }
    super.disconnect()
  }

  // 마스터는 읽기 전용
  configureManager() { return null }

  // 디테일 그리드 CRUD 설정
  configureDetailManager() {
    return {
      pkFields: ["id"],
      fields: {
        item_cd: "trimUpper",
        item_nm: "trim",
        qty: "number",
        unit: "trim",
        lot_no: "trimUpper",
        zone_cd: "trimUpper",
        rmk: "trim"
      },
      defaultRow: { item_cd: "", item_nm: "", qty: 0, unit: "", lot_no: "", zone_cd: "", rmk: "" },
      blankCheckFields: ["item_cd"],
      comparableFields: ["item_cd", "item_nm", "qty", "unit", "lot_no", "zone_cd", "rmk"],
      firstEditCol: "item_cd",
      pkLabels: { id: "ID" }
    }
  }

  // 그리드 등록 분기
  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api, controller } = registration

    if (gridElement === this.masterGridTarget) {
      super.registerGrid(event)
      this.#gridApis.master = api
      this.masterGridEvents.bind(api, "rowClicked", this.#handleMasterRowClicked)
    } else if (gridElement === this.detailGridTarget) {
      if (this.detailManager) this.detailManager.detach()
      this.detailManager = new GridCrudManager(this.configureDetailManager())
      this.detailManager.attach(api)
      this.#gridApis.detail = api
    } else if (gridElement === this.historyGridTarget) {
      this.#gridApis.history = api
    }
  }

  // 탭 전환
  switchTab(event) {
    const tab = event.currentTarget.dataset.tab
    this.#activeTab = tab

    this.tabBtnTargets.forEach((btn) => {
      const isActive = btn.dataset.tab === tab
      btn.classList.toggle("border-primary", isActive)
      btn.classList.toggle("text-primary", isActive)
      btn.classList.toggle("border-transparent", !isActive)
      btn.classList.toggle("text-text-secondary", !isActive)
    })

    this.tabPanelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.tab !== tab
    })

    if (this.#selectedId) {
      this.#loadTabData(tab, this.#selectedId)
    }
  }

  // ─── 디테일 CRUD 액션 ───

  addDetailRow() {
    if (!this.detailManager) return
    if (!this.#selectedId) {
      alert("입고를 먼저 선택해주세요.")
      return
    }
    this.detailManager.addRow({ inbound_id: this.#selectedId })
  }

  deleteDetailRows() {
    if (!this.detailManager) return
    this.detailManager.deleteRows()
  }

  async saveDetailRows() {
    if (!this.detailManager) return
    if (!this.#selectedId) {
      alert("입고를 먼저 선택해주세요.")
      return
    }

    this.detailManager.stopEditing()
    const operations = this.detailManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":id", this.#selectedId)
    const ok = await postJson(batchUrl, operations)
    if (!ok) return

    alert("입고상세 데이터가 저장되었습니다.")
    await this.#loadDetailRows(this.#selectedId)
  }

  // ─── Private ───

  #gridApis
  #activeTab
  #selectedId

  #handleMasterRowClicked = async (event) => {
    const rowData = rowDataFromGridEvent(this.#gridApis.master, event)
    if (!rowData?.id) return

    this.#selectedId = rowData.id
    this.#refreshSelectedLabel(rowData.inbound_no)

    // 활성 탭 데이터 로드
    await this.#loadTabData(this.#activeTab, rowData.id)
  }

  async #loadTabData(tab, id) {
    try {
      if (tab === "detail") {
        await this.#loadDetailRows(id)
      } else if (tab === "history") {
        const url = buildTemplateUrl(this.historyUrlTemplateValue, ":id", id)
        const rows = await fetchJson(url)
        if (isApiAlive(this.#gridApis.history)) {
          setGridRowData(this.#gridApis.history, rows)
        }
      }
    } catch {
      alert(`${tab} 데이터 조회에 실패했습니다.`)
    }
  }

  async #loadDetailRows(id) {
    if (!isApiAlive(this.detailManager?.api)) return

    try {
      const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":id", id)
      const rows = await fetchJson(url)
      setManagerRowData(this.detailManager, rows)
    } catch {
      alert("입고상세 조회에 실패했습니다.")
    }
  }

  #refreshSelectedLabel(displayValue) {
    if (!this.hasSelectedLabelTarget) return
    refreshSelectionLabel(this.selectedLabelTarget, displayValue, "입고", "입고를 선택하세요.")
  }
}
```

### Routes

```ruby
# config/routes.rb (namespace :system 내부에 추가)
resources :inbounds, only: [:index, :create, :update] do
  member do
    get :histories
    resources :details, controller: :inbound_details, only: [:index] do
      post :batch_save, on: :collection
    end
  end
end
```

### P4-4 실구현 핵심 포인트 (입고관리 wm_gr_prars)

#### ERB — 커스텀 액션버튼 + absolute 탭 패널

탭 패널을 `absolute inset-0`으로 쌓아 DOM을 유지(AG Grid 인스턴스 보존)하고
CSS `hidden`으로 표시/숨김을 제어합니다. 액션버튼은 탭 헤더 행 오른쪽에 배치합니다.

```erb
<%# 전체 레이아웃: flex flex-col로 영역 비율 고정 %>
<div class="flex flex-col gap-3 h-[calc(100vh-220px)]"
     data-controller="wm-gr-prar-grid"
     data-action="ag-grid:ready->wm-gr-prar-grid#registerGrid"
     data-wm-gr-prar-grid-save-url-template-value="<%= save_url_template %>"
     data-wm-gr-prar-grid-confirm-url-template-value="<%= confirm_url_template %>"
     data-wm-gr-prar-grid-cancel-url-template-value="<%= cancel_url_template %>">

  <%# 마스터 그리드 영역 (40%) %>
  <div class="flex flex-col" style="flex: 0 0 40%">
    <%= render Ui::AgGridComponent.new(
      columns: master_columns,
      url: grid_url,
      row_selection: "single",
      data: { wm_gr_prar_grid_target: "masterGrid" }
    ) %>
  </div>

  <%# 탭 + 디테일 영역 (60%) %>
  <div class="flex flex-col flex-1 min-h-0">

    <%# 탭 헤더 행: 탭버튼 왼쪽 + 액션버튼 오른쪽 %>
    <div class="flex items-center justify-between border-b border-border">
      <div class="flex">
        <button type="button"
                class="px-4 py-2 text-sm font-medium border-b-2 border-primary text-primary"
                data-wm-gr-prar-grid-target="tab1Btn"
                data-action="click->wm-gr-prar-grid#switchTab"
                data-tab="detail">입고예정상세</button>
        <button type="button"
                class="px-4 py-2 text-sm font-medium border-b-2 border-transparent text-text-secondary"
                data-wm-gr-prar-grid-target="tab2Btn"
                data-action="click->wm-gr-prar-grid#switchTab"
                data-tab="exec_result">입고처리내역</button>
      </div>

      <%# 액션버튼 그룹 %>
      <div class="flex items-center gap-2 pr-2">
        <span class="text-xs text-text-secondary" data-wm-gr-prar-grid-target="selectedMasterLabel">
          <%= selected_master_label %>
        </span>
        <button type="button" class="btn btn-sm btn-primary"
                data-action="click->wm-gr-prar-grid#saveGr">저장</button>
        <button type="button" class="btn btn-sm btn-success"
                data-action="click->wm-gr-prar-grid#confirmGr">입고확정</button>
        <button type="button" class="btn btn-sm btn-danger"
                data-action="click->wm-gr-prar-grid#cancelGr">입고취소</button>
      </div>
    </div>

    <%# 탭 패널: relative 컨테이너 + absolute inset-0으로 DOM 유지 %>
    <div class="relative flex-1 min-h-0">
      <div class="absolute inset-0" data-wm-gr-prar-grid-target="tab1Panel">
        <%= render Ui::AgGridComponent.new(
          columns: detail_columns, row_data: [],
          data: { wm_gr_prar_grid_target: "detailGrid" }
        ) %>
      </div>
      <div class="absolute inset-0 hidden" data-wm-gr-prar-grid-target="tab2Panel">
        <%= render Ui::AgGridComponent.new(
          columns: exec_result_columns, row_data: [],
          data: { wm_gr_prar_grid_target: "execRsltGrid" }
        ) %>
      </div>
    </div>
  </div>
</div>
```

#### Stimulus — switchTab에서 sizeColumnsToFit 호출

AG Grid는 `hidden` 상태에서 크기 계산을 못합니다. 탭을 보이게 한 후 `setTimeout`으로 컬럼 너비를 재조정합니다.

```javascript
switchTab(event) {
  const tab = event.currentTarget.dataset.tab
  this.#activeTab = tab

  // 탭 버튼 스타일 전환
  ;[
    [this.tab1BtnTarget, "detail"],
    [this.tab2BtnTarget, "exec_result"]
  ].forEach(([btn, t]) => {
    const isActive = t === tab
    btn.classList.toggle("border-primary", isActive)
    btn.classList.toggle("text-primary", isActive)
    btn.classList.toggle("border-transparent", !isActive)
    btn.classList.toggle("text-text-secondary", !isActive)
  })

  // 탭 패널 표시/숨김
  this.tab1PanelTarget.classList.toggle("hidden", tab !== "detail")
  this.tab2PanelTarget.classList.toggle("hidden", tab !== "exec_result")

  // AG Grid: 숨겨진 후 보이게 되면 컬럼 너비 재조정 필수
  setTimeout(() => {
    const api = tab === "detail"
      ? this.#detailGridController?.gridApi
      : this.#execRsltGridController?.gridApi
    if (api) api.sizeColumnsToFit()
  }, 50)
}
```

#### Stimulus — 커스텀 트랜잭션 액션 (저장/확정/취소)

```javascript
async saveGr() {
  if (!this.#selectedMasterData) {
    alert("입고예정을 먼저 선택해주세요.")
    return
  }

  const detailApi = this.#detailGridController?.gridApi
  if (!isApiAlive(detailApi)) return

  // 전체 행 수집 (변경 여부 불문, 서버에서 UPSERT)
  const rows = []
  detailApi.forEachNode(node => { if (node.data) rows.push(node.data) })

  // 검증: gr_qty > 0 인 행만 전송 가능
  const validRows = rows.filter(r => (r.gr_qty || 0) > 0)
  if (validRows.length === 0) {
    alert("입고물량이 0보다 큰 행이 없습니다.")
    return
  }

  const url = buildTemplateUrl(this.saveUrlTemplateValue, ":gr_prar_id", this.#selectedMasterData.gr_prar_no)
  const result = await postJson(url, { details: validRows })
  if (result?.success) {
    alert("저장되었습니다.")
    await this.#loadDetailRows(this.#selectedMasterData.gr_prar_no)
  }
}

async confirmGr() {
  if (!this.#selectedMasterData) {
    alert("입고예정을 먼저 선택해주세요.")
    return
  }
  if (this.#selectedMasterData.gr_stat_cd !== "20") {
    alert("입고처리 완료(상태코드 20) 상태에서만 확정할 수 있습니다.")
    return
  }
  if (!confirm("입고확정 처리하시겠습니까?")) return

  const url = buildTemplateUrl(this.confirmUrlTemplateValue, ":gr_prar_id", this.#selectedMasterData.gr_prar_no)
  const result = await postJson(url, {})
  if (result?.success) {
    alert("입고확정 처리되었습니다.")
    // 마스터 그리드 재조회
    this.#masterGridController?.search()
  }
}
```

#### Routes — 커스텀 member 액션

```ruby
# config/routes.rb
namespace :wm do
  resources :gr_prars, only: [:index] do
    collection do
      get :staged_locations  # 스테이징 로케이션 목록
    end
    member do
      get  :details          # 디테일 목록 (JSON)
      get  :exec_results     # 처리내역 목록 (JSON)
      post :save_gr          # 입고저장 (트랜잭션)
      post :confirm          # 입고확정
      post :cancel           # 입고취소
    end
  end
end
```

---

## 부록 A: 복합 PK 마이그레이션 (SQLite3)

SQLite3는 `create_table`의 `primary_key:` 배열을 지원하지 않으므로 `execute`로 처리합니다.

```ruby
# db/migrate/XXXXXXXX_create_wm_some_table.rb
class CreateWmSomeTable < ActiveRecord::Migration[8.1]
  def change
    create_table :tb_wm02002, id: false do |t|
      t.string :gr_prar_no, null: false, limit: 20  # FK
      t.integer :lineno, null: false                 # 복합PK 구성요소
      t.string :item_cd, null: false, limit: 40
      t.decimal :gr_prar_qty, precision: 15, scale: 3
      # ... 기타 컬럼
      t.timestamps null: false
    end

    # SQLite3 복합 PK: ALTER TABLE로 추가, rescue nil로 중복 실행 방지
    execute "ALTER TABLE tb_wm02002 ADD PRIMARY KEY (gr_prar_no, lineno)" rescue nil
    add_index :tb_wm02002, :gr_prar_no
  end
end
```

**주의**:
- `id: false` 필수 (Rails 자동 PK 비활성화)
- `rescue nil`은 SQLite3에서 이미 PK가 있을 때의 오류를 무시
- PostgreSQL 등 다른 DB는 `create_table :tb_..., primary_key: [:col1, :col2]` 사용 가능

---

## 부록 B: UPSERT 모델 패턴

재고, 실적 등 "있으면 업데이트, 없으면 생성" 패턴. 서비스 객체 없이 모델 클래스 메서드로 구현합니다.

```ruby
# app/models/wm/stock_attr_qty.rb
class Wm::StockAttrQty < ApplicationRecord
  self.table_name = "tb_wm04002"

  # UPSERT 클래스 메서드: 있으면 증감, 없으면 생성
  def self.upsert_qty(corp_cd:, workpl_cd:, stock_attr_no:, qty_delta:, actor:)
    record = find_or_initialize_by(
      corp_cd: corp_cd,
      workpl_cd: workpl_cd,
      stock_attr_no: stock_attr_no
    )

    if record.new_record?
      record.qty = qty_delta
      record.alloc_qty = 0
      record.pick_qty = 0
      record.create_by = actor
      record.create_time = Time.current
    else
      record.qty = (record.qty || 0) + qty_delta
    end

    record.update_by = actor
    record.update_time = Time.current
    record.save!
    record
  end

  def available_qty
    qty - alloc_qty - pick_qty
  end
end
```

**UPSERT 일괄 처리 (Rails 6+)**:
```ruby
# ActiveRecord::Base.upsert_all을 사용하는 경우 (충돌 컬럼 지정 필요)
Wm::StockAttrQty.upsert_all(
  rows,
  unique_by: [:corp_cd, :workpl_cd, :stock_attr_no],
  update_only: [:qty, :update_by, :update_time]
)
```

---

## 부록 C: 복잡한 트랜잭션 컨트롤러 액션

비즈니스 로직이 복잡한 저장/확정/취소 액션 패턴. 모든 처리는 `transaction` 블록 내에서 실행합니다.

```ruby
# app/controllers/wm/gr_prars_controller.rb
class Wm::GrPrarsController < Wm::BaseController
  # GET /wm/gr_prars (HTML/JSON 분기)
  def index
    if request.format.json?
      q = params.fetch(:q, {}).permit(
        :workpl_cd, :cust_cd, :gr_type_cd, :gr_stat_cd,
        :prar_ymd_from, :prar_ymd_to, :item_cd, :ord_no
      )
      @records = Wm::GrPrar.search(q).order(prar_ymd: :desc)
      render json: @records
    end
  end

  # GET /wm/gr_prars/:id/details.json
  def details
    @gr_prar = Wm::GrPrar.find(params[:id])
    render json: @gr_prar.gr_prar_dtls.order(:lineno)
  end

  # POST /wm/gr_prars/:id/save_gr — 입고저장 (핵심 트랜잭션)
  def save_gr
    @gr_prar = Wm::GrPrar.find(params[:id])
    details_params = params.require(:details).map { |d| d.permit(...) }

    ActiveRecord::Base.transaction do
      details_params.each do |dp|
        dtl = @gr_prar.gr_prar_dtls.find_by!(lineno: dp[:lineno])

        # 1단계: 재고속성 조회/생성
        stock_attr = Wm::StockAttr.find_or_create_for(
          corp_cd: @gr_prar.corp_cd,
          cust_cd: @gr_prar.cust_cd,
          item_cd: dtl.item_cd,
          attrs: dp.slice(*Wm::GrPrarDtl::STOCK_ATTR_COLS),
          actor: current_user.user_id
        )

        # 2단계: 재고 3테이블 UPSERT (재고속성별/속성+로케이션별/로케이션별)
        Wm::StockAttrQty.upsert_qty(
          corp_cd: @gr_prar.corp_cd, workpl_cd: @gr_prar.workpl_cd,
          stock_attr_no: stock_attr.stock_attr_no, qty_delta: dp[:gr_qty].to_d,
          actor: current_user.user_id
        )

        # 3단계: 실행실적 생성
        Wm::ExceRslt.create!(
          exce_rslt_no: Wm::ExceRslt.generate_no,
          gr_prar_no: @gr_prar.gr_prar_no,
          lineno: dtl.lineno,
          exce_rslt_type: Wm::ExceRslt::EXCE_RSLT_TYPE_DP,
          rslt_qty: dp[:gr_qty],
          create_by: current_user.user_id,
          create_time: Time.current
        )

        # 4단계: 상세 수정
        dtl.update!(gr_qty: dp[:gr_qty], gr_loc_cd: dp[:gr_loc_cd])
      end

      # 5단계: 헤더 상태 변경
      @gr_prar.update!(gr_stat_cd: Wm::GrPrar::GR_STAT_PROCESSED)
    end

    render json: { success: true, message: "저장되었습니다." }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, message: e.message }, status: :not_found
  rescue => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  # POST /wm/gr_prars/:id/confirm — 입고확정
  def confirm
    @gr_prar = Wm::GrPrar.find(params[:id])

    unless @gr_prar.processed?
      return render json: { success: false, message: "입고처리 완료 상태에서만 확정할 수 있습니다." },
                    status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @gr_prar.update!(gr_stat_cd: Wm::GrPrar::GR_STAT_CONFIRMED)
      # 외부 시스템 연동은 별도 메서드로 분리 (스텁)
      notify_order_system_for_confirm(@gr_prar)
    end

    render json: { success: true, message: "입고확정 처리되었습니다." }
  rescue => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  # POST /wm/gr_prars/:id/cancel — 입고취소
  def cancel
    @gr_prar = Wm::GrPrar.find(params[:id])

    ActiveRecord::Base.transaction do
      # 재고 차감 (입고된 물량 역방향 처리)
      @gr_prar.gr_prar_dtls.each do |dtl|
        next if (dtl.gr_qty || 0) <= 0

        Wm::StockAttrQty.upsert_qty(
          corp_cd: @gr_prar.corp_cd, workpl_cd: @gr_prar.workpl_cd,
          stock_attr_no: dtl.stock_attr_no, qty_delta: -dtl.gr_qty.to_d,
          actor: current_user.user_id
        )
      end

      @gr_prar.update!(gr_stat_cd: Wm::GrPrar::GR_STAT_CANCELLED)
    end

    render json: { success: true, message: "입고취소 처리되었습니다." }
  rescue => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  private
    def notify_order_system_for_confirm(gr_prar)
      # TODO: 외부 오더 시스템 연동 구현
    end
end
```

**핵심 규칙**:
- 복잡한 트랜잭션은 `ActiveRecord::Base.transaction` 블록 사용
- 각 액션은 `rescue => e`로 `{ success: false, message: }` 반환
- 외부 시스템 연동은 private 메서드(스텁)로 분리해 나중에 구현
- 상태 상수는 모델에 정의: `GR_STAT_PENDING = "10"`, `GR_STAT_PROCESSED = "20"` 등

---

## 부록 D: 메뉴 및 사용자 권한 시드 패턴

**중요**: `AdmMenu`는 `parent_id`가 아니라 `parent_cd` 컬럼을 사용합니다.

```ruby
# db/seeds/wm_some_menu.rb
puts "메뉴 등록 시작..."

# 1. 상위 폴더 확인 (WM 그룹)
wms_menu = AdmMenu.find_by(menu_cd: "WM_GROUP")
raise "WM_GROUP 메뉴를 찾을 수 없습니다." unless wms_menu

# 2. 메뉴 등록/업데이트
menu = AdmMenu.find_or_initialize_by(menu_cd: "WM_SOME_MENU")
menu.menu_nm    = "화면명"
menu.menu_type  = "MENU"
menu.parent_cd  = wms_menu.menu_cd   # ✅ parent_cd 사용 (parent_id 아님)
menu.menu_url   = "/wm/some_path"
menu.use_yn     = "Y"
menu.sort_order = 120
menu.menu_icon  = "icon-name"        # lucide icon 이름
menu.menu_level = wms_menu.menu_level + 1
menu.save!
puts "메뉴 등록: id=#{menu.id}"

# 3. 활성 사용자 권한 등록
# AdmUserMenuPermission.find_or_initialize_by(user_id:, menu_cd:) 패턴 사용
user_count = 0
User.where(work_status: "ACTIVE").each do |user|
  begin
    perm = AdmUserMenuPermission.find_or_initialize_by(
      user_id: user.id,
      menu_cd: menu.menu_cd
    )
    perm.use_yn = "Y"
    perm.save!
    user_count += 1
  rescue => e
    puts "  권한 설정 오류(user #{user.id}): #{e.message}"
  end
end

puts "권한 설정 완료: #{user_count}명"
puts "✅ 메뉴 등록 완료"
```

**실행**:
```bash
bin/rails runner db/seeds/wm_some_menu.rb
```

**오류 사례 및 해결**:
- `unknown attribute 'parent_id' for AdmMenu` → `parent_cd`로 변경
- `uninitialized constant AdmMenuAthr` → `AdmUserMenuPermission` 사용
- `User.find_each` vs `User.each`: 대용량이면 `find_each`, 소용량은 `each` 모두 가능

---

## 새 화면 추가 체크리스트

### 1. 유형 결정
- [ ] 유형 1: 단순 인라인 편집 그리드 (행추가/삭제/일괄저장)
- [ ] 유형 2: 마스터-디테일 그리드 (1:N 관계, 각각 독립 저장)
- [ ] 유형 3: 그리드 + 모달 CRUD (등록/수정/삭제를 팝업으로)
- [ ] 유형 4: 그리드 + 탭 (상단 그리드 공유 + 하단 탭별 콘텐츠)
- [ ] 유형 5: 마스터 그리드 + 디테일 탭 (유형2 + 유형4 결합)

### 2. 파일 생성
- [ ] Migration 생성 및 실행: `bin/rails generate migration CreateXxx`
- [ ] Model 생성: `app/models/<model>.rb`
- [ ] Rails Controller 생성: `app/controllers/<namespace>/<module>_controller.rb`
- [ ] PageComponent 생성: `app/components/<namespace>/<module>/page_component.rb`
- [ ] ERB 템플릿 생성: `app/components/<namespace>/<module>/page_component.html.erb`
- [ ] Stimulus Controller 생성: `app/javascript/controllers/<module>_grid_controller.js` 또는 `<module>_crud_controller.js`

### 3. 설정/등록
- [ ] Routes 추가: `config/routes.rb`에 리소스 추가
- [ ] Importmap pin 확인: `config/importmap.rb`에 컨트롤러 자동 인식 확인
- [ ] TabRegistry 등록: `app/models/tab_registry.rb`에 탭 Entry 추가
- [ ] 메뉴 등록: `adm_menus` 테이블에 메뉴 데이터 추가

### 4. 커스텀 셀 렌더러 (필요 시)
- [ ] `app/javascript/controllers/ag_grid/renderers.js`의 `RENDERER_REGISTRY`에 렌더러 추가
- [ ] 액션 셀 렌더러: 편집/삭제 버튼 → 커스텀 이벤트 dispatch

### 5. 검증
- [ ] `bin/rails server`로 화면 정상 렌더링 확인
- [ ] 검색 동작 확인
- [ ] CRUD 동작 확인 (생성/조회/수정/삭제)
- [ ] `bin/rubocop`으로 린트 통과 확인
- [ ] 테스트 작성 및 통과 확인

### 6. WM 도메인 추가 체크리스트

- [ ] **공통코드 확인**: 숫자 코드 그룹(예: "152", "153")은 `common_code_options("숫자", include_all: true)` 사용
- [ ] **복합 PK 테이블**: `id: false` + `execute "ALTER TABLE ... ADD PRIMARY KEY (...)" rescue nil`
- [ ] **UPSERT 패턴**: 재고/실적 테이블은 `find_or_initialize_by` 기반 클래스 메서드 구현
- [ ] **트랜잭션 액션**: `save_gr` / `confirm` / `cancel` 등은 `ActiveRecord::Base.transaction` + `rescue => e`
- [ ] **메뉴 시드**: `parent_cd = wms_menu.menu_cd` (parent_id 아님), `AdmUserMenuPermission` 사용
- [ ] **AG Grid 탭 전환**: `hidden` CSS + `setTimeout(() => api.sizeColumnsToFit(), 50)`
- [ ] **탭 패널 레이아웃**: DOM 유지 시 `absolute inset-0` + CSS `hidden` (display:none 방식보다 안정적)
- [ ] **Stimulus private 필드**: `#activeTab`, `#selectedMasterData` 등 `#` 접두사 사용
- [ ] **뷰 파일 turbo_frame 래퍼 필수**: `index.html.erb`에 반드시 `turbo_frame_tag "main-content"` 래퍼 추가
- [ ] **메뉴 시드 실행**: `bin/rails runner db/seeds/wm_xxx_menu.rb`

---

## 자주 발생하는 오류 및 해결법

### ❌ Turbo Frame `main-content` 누락 오류

**증상:**

```
Uncaught (in promise) Nt: The response (200) did not contain the expected
<turbo-frame id="main-content"> and will be ignored.
```

**원인:**

탭 시스템의 동작 흐름:
1. 사이드바 메뉴 클릭 → POST `/tabs` (Turbo Stream 요청)
2. `TabsController#render_tab_update`가 Turbo Stream으로 `<turbo-frame id="main-content" src="/wm/...">` 삽입
3. Turbo가 해당 URL로 GET 요청
4. **응답 HTML에 `<turbo-frame id="main-content">`가 없으면 오류 발생 → 화면 로드 실패**

**해결법:**

모든 화면의 `index.html.erb`는 반드시 `turbo_frame_tag "main-content"`로 감싸야 합니다.

```erb
<%# ✅ 올바른 형태 %>
<%= turbo_frame_tag "main-content" do %>
  <%= render Wm::SomeModule::PageComponent.new(query_params: request.query_parameters) %>
<% end %>
```

```erb
<%# ❌ 잘못된 형태 - turbo-frame 래퍼 없음 %>
<%= render Wm::SomeModule::PageComponent.new(query_params: request.query_parameters) %>
```

**확인 방법:**

```bash
# turbo_frame_tag "main-content" 누락 파일 검색
grep -rL 'turbo_frame_tag "main-content"' app/views/wm/ app/views/system/ --include="index.html.erb"
```

---

### ❌ 마스터-디테일 레이아웃에서 AG Grid가 렌더링되지 않는 오류

**증상:**

- 마스터 그리드(상단)에 페이지네이션 바만 표시되고 헤더·행이 보이지 않음
- 하단 탭 패널의 그리드도 동일하게 빈 상태로 표시
- 탭 클릭 시 그리드가 나타나지 않음

**원인:**

AG Grid는 컨테이너 높이가 `0`이면 헤더와 바디를 렌더링하지 않습니다.
`flex` 레이아웃에서 `min-h-0` 없이 `style="flex: 0 0 40%"` 등을 사용하면 flex item이
컨테이너 높이를 올바르게 상속하지 못해 그리드 컨테이너 높이가 `0`이 됩니다.

```html
<!-- ❌ 잘못된 형태 - min-h-0 없음, style 인라인 사용 -->
<div class="flex flex-col gap-3 h-[calc(100vh-220px)]">
  <section class="flex flex-col" style="flex: 0 0 40%;">   <!-- ← min-h-0 없음! -->
    ...
  </section>
  <section class="flex flex-col min-h-0" style="flex: 1 1 0%;">
    ...
  </section>
</div>
```

**해결법: `grid grid-rows-[...]` 레이아웃으로 전환**

```html
<!-- ✅ 올바른 형태 - CSS Grid + min-h-0 -->
<div class="grid grid-rows-[40%_1fr] gap-3 h-[calc(100vh-220px)]">
  <section class="min-h-0 flex flex-col">
    ...
  </section>
  <section class="min-h-0 flex flex-col">
    ...
  </section>
</div>
```

**핵심 규칙:**

- 마스터-디테일 레이아웃은 `flex` 대신 `grid grid-rows-[비율_1fr]` 사용
- 각 `section`에 반드시 `min-h-0` 클래스 추가
- `style=""` 인라인 속성으로 비율 지정하지 말 것 (Tailwind 클래스 사용)
- 그리드 자체에 `height: "100%"` 설정 필수

---

### ❌ 탭 전환 시 그리드 컬럼 너비가 맞지 않는 문제

**증상:**

탭 전환 후 그리드가 표시되지만 컬럼 너비가 이상하게 작거나 맞지 않음.

**원인:**

AG Grid는 DOM이 숨겨진(`hidden`) 상태에서 컨테이너 크기를 계산할 수 없어 컬럼 너비가 틀어집니다.

**해결법:**

탭 패널이 노출된 직후 `sizeColumnsToFit()`를 `setTimeout`으로 호출합니다.

```javascript
#activateTab(tab) {
    // ... 패널 show/hide 처리 후 ...
    setTimeout(() => {
        if (tab === "detail") {
            this.#detailGridController?.api?.sizeColumnsToFit()
        } else if (tab === "exec") {
            this.#execRsltGridController?.api?.sizeColumnsToFit()
        }
    }, 50)
}
```

---

## 멀티탭 그리드 패턴 (마스터-디테일 탭)

마스터 그리드 + 하단 탭(여러 디테일 그리드)으로 구성된 화면 패턴입니다.
입고관리(`wm/gr_prars`) 화면이 참조 구현입니다.

### 레이아웃 구조 (ERB)

```html
<%# 전체 레이아웃: 마스터 그리드 + 탭 디테일 %>
<div class="grid grid-rows-[40%_1fr] gap-3 h-[calc(100vh-220px)]">

  <%# 마스터 섹션 %>
  <section class="min-h-0 flex flex-col">
    <%= render Ui::GridHeaderComponent.new(icon: "package-open", title: "목록", grid_id: "master") %>
    <div class="flex-1 min-h-0">
      <%= render Ui::AgGridComponent.new(
        columns: master_columns,
        url: collection_path(format: :json),
        height: "100%",
        pagination: true,
        row_selection: "single",
        grid_id: "master",
        data: { my_controller_target: "masterGrid" }
      ) %>
    </div>
  </section>

  <%# 디테일 섹션 (탭 구조) %>
  <section class="min-h-0 flex flex-col">

    <%# 탭 헤더 + 액션 버튼 %>
    <div class="flex items-center justify-between border-b border-border px-1 pb-0">
      <div class="std-client-tabs" role="tablist">
        <button type="button" role="tab" aria-selected="true"
                class="std-client-tab is-active"
                data-my-controller-target="tabButton"
                data-action="click->my-controller#switchTab"
                data-tab="detail">
          상세목록
        </button>
        <button type="button" role="tab" aria-selected="false"
                class="std-client-tab"
                data-my-controller-target="tabButton"
                data-action="click->my-controller#switchTab"
                data-tab="history">
          처리내역
        </button>
      </div>

      <%# 선택 마스터 라벨 %>
      <p class="text-xs text-text-secondary px-2"
         data-my-controller-target="selectedMasterLabel">
        <%= selected_master_label %>
      </p>

      <%# 액션 버튼 %>
      <div class="flex gap-2 py-1">
        <button type="button" class="btn btn-sm btn-primary"
                data-action="click->my-controller#save">저장</button>
      </div>
    </div>

    <%# 탭 패널 영역 %>
    <div class="flex-1 min-h-0 relative">

      <%# Tab 1: 상세목록 (기본 표시) %>
      <div class="absolute inset-0 flex flex-col"
           data-my-controller-target="tabPanel"
           data-tab-panel="detail">
        <div class="flex-1 min-h-0">
          <%= render Ui::AgGridComponent.new(
            columns: detail_columns,
            row_data: [],
            height: "100%",
            pagination: false,
            grid_id: "detail",
            data: { my_controller_target: "detailGrid" }
          ) %>
        </div>
      </div>

      <%# Tab 2: 처리내역 (초기 숨김) %>
      <div class="absolute inset-0 flex flex-col hidden"
           data-my-controller-target="tabPanel"
           data-tab-panel="history">
        <div class="flex-1 min-h-0">
          <%= render Ui::AgGridComponent.new(
            columns: history_columns,
            row_data: [],
            height: "100%",
            pagination: false,
            grid_id: "history",
            data: { my_controller_target: "historyGrid" }
          ) %>
        </div>
      </div>

    </div>
  </section>
</div>
```

**포인트:**

- 외부 컨테이너: `grid grid-rows-[40%_1fr]` (비율은 화면에 맞게 조정)
- 각 섹션: `min-h-0 flex flex-col` 필수
- 탭 버튼: `std-client-tabs` / `std-client-tab` / `is-active` 클래스 사용
- 탭 패널: `absolute inset-0` + `data-tab-panel="키"` 속성 필수
- 초기 숨김 패널: `hidden` 클래스 추가

---

### Stimulus 컨트롤러 패턴 (멀티탭 그리드)

```javascript
import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, resolveAgGridRegistration, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"

export default class extends BaseGridController {
    static targets = [
        ...BaseGridController.targets,
        "masterGrid", "detailGrid", "historyGrid",
        "selectedMasterLabel",
        "tabButton", "tabPanel"   // ← 개별(tab1Btn 등) 아닌 통합 타겟 사용
    ]

    static values = {
        ...BaseGridController.values,
        detailListUrlTemplate: String,
        historyUrlTemplate:    String,
        selectedMaster:        String
    }

    connect() {
        super.connect()
        this.#activeTab = "detail"          // 문자열 키 사용
        this.#masterGridEvents = new GridEventManager()
        this.#detailGridController = null
        this.#historyGridController = null
        this.#activateTab("detail")         // connect 시점에 초기 탭 활성화
    }

    disconnect() {
        this.#masterGridEvents.unbindAll()
        super.disconnect()
    }

    registerGrid(event) {
        const { gridElement, api, controller } = resolveAgGridRegistration(event) ?? {}
        if (!gridElement) return

        if (gridElement === this.masterGridTarget) {
            super.registerGrid(event)
            this.#bindMasterRowClick()
        } else if (gridElement === this.detailGridTarget) {
            this.#detailGridController = controller
        } else if (gridElement === this.historyGridTarget) {
            this.#historyGridController = controller
        }
    }

    // --- 탭 전환 (public action) ---

    switchTab(event) {
        const tab = event.currentTarget?.dataset?.tab
        if (!tab || tab === this.#activeTab) return
        this.#activateTab(tab)
    }

    // --- Private ---

    #activeTab = "detail"
    #masterGridEvents = null
    #detailGridController = null
    #historyGridController = null

    #activateTab(tab) {
        this.#activeTab = tab

        // 버튼: is-active 토글 + aria-selected 업데이트
        this.tabButtonTargets.forEach(btn => {
            const isActive = btn.dataset.tab === tab
            btn.classList.toggle("is-active", isActive)
            btn.setAttribute("aria-selected", isActive ? "true" : "false")
        })

        // 패널: data-tab-panel 속성으로 대상 특정
        this.tabPanelTargets.forEach(panel => {
            panel.classList.toggle("hidden", panel.dataset.tabPanel !== tab)
        })

        // 탭 전환 후 컬럼 너비 재조정 (50ms 지연 필수)
        setTimeout(() => {
            if (tab === "detail") {
                this.#detailGridController?.api?.sizeColumnsToFit()
            } else if (tab === "history") {
                this.#historyGridController?.api?.sizeColumnsToFit()
            }
        }, 50)
    }

    #bindMasterRowClick() {
        this.#masterGridEvents.unbindAll()
        this.#masterGridEvents.bind(this.manager?.api, "rowClicked", this.#handleMasterRowClicked)
    }

    #handleMasterRowClicked = (event) => {
        const rowData = rowDataFromGridEvent(event)
        if (!rowData) return
        this.#selectMaster(rowData)
    }

    #selectMaster(rowData) {
        this.selectedMasterValue = rowData.pk_field
        // 디테일 데이터 로드
        // this.#detailGridController?.loadData(url)
        // this.#historyGridController?.loadData(url)
    }
}
```

**핵심 규칙 정리:**

| 항목 | ❌ 잘못된 방법 | ✅ 올바른 방법 |
|---|---|---|
| 탭 타겟 선언 | `"tab1Btn", "tab2Btn", "tab1Panel", "tab2Panel"` | `"tabButton", "tabPanel"` |
| 탭 식별자 | 숫자 (`1`, `2`) | 문자열 키 (`"detail"`, `"exec"`) |
| 탭 버튼 클래스 | `border-b-2 border-primary text-primary` | `std-client-tab is-active` |
| 탭 버튼 컨테이너 | `flex gap-0` | `std-client-tabs` |
| 패널 식별 | 타겟 이름 (`tab1PanelTarget`) | `data-tab-panel` 속성 |
| 레이아웃 | `flex + style="flex: 0 0 40%"` | `grid grid-rows-[40%_1fr]` |
| 섹션 높이 | `flex flex-col` (min-h-0 없음) | `min-h-0 flex flex-col` |

**적용 범위:** 탭 시스템으로 열리는 모든 화면 (`wm/`, `system/`, `std/`, `om/` 등 전 네임스페이스)
