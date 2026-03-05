# Master-Detail Scaffold

아래 스캐폴드를 복사해 새 화면에 맞게 이름/필드만 교체한다.

## 1. Routes

```ruby
namespace :system do
  resources :<master_resource>, only: [ :index, :create, :update, :destroy ], param: :id do
    post :batch_save, on: :collection

    resources :details, controller: :<detail_controller>, only: [ :index, :create, :update, :destroy ], param: :detail_code do
      post :batch_save, on: :collection
    end
  end
end
```

## 2. PageComponent (`app/components/<ns>/<module>/page_component.rb`)

```ruby
class <Ns>::<Module>::PageComponent <<Ns>::BasePageComponent
  def initialize(query_params:, selected_key:)
    super(query_params: query_params)
    @selected_key = selected_key.presence
  end

  private
    attr_reader :selected_key

    def collection_path(**) = helpers.<ns>_<master_resource>_path(**)
    def member_path(id, **) = helpers.<ns>_<master_singular>_path(id, **)
    def detail_collection_path(id, **) = helpers.<ns>_<master_singular>_details_path(id, **)

    def detail_grid_url
      if selected_key.present?
        detail_collection_path(selected_key, format: :json)
      end
    end

    def master_batch_save_url
      helpers.batch_save_<ns>_<master_resource>_path
    end

    def detail_batch_save_url_template
      "/<ns>/<master_resource>/:id/details/batch_save"
    end

    def selected_label
      selected_key.present? ? "선택 값: #{selected_key}" : "마스터를 먼저 선택하세요."
    end

    def search_fields
      [
        { field: "<master_code>", type: "input", label: "코드", placeholder: "코드 검색.." },
        { field: "<master_name>", type: "input", label: "명칭", placeholder: "명칭 검색.." },
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
      [ { field: "<master_code>", headerName: "코드", editable: true } ]
    end

    def detail_columns
      [ { field: "<detail_code>", headerName: "상세코드", editable: true } ]
    end
end
```

## 3. ERB (`app/components/<ns>/<module>/page_component.html.erb`)

```erb
<div data-controller="<name>-grid"
     data-action="ag-grid:ready-><name>-grid#registerGrid"
     data-<name>-grid-master-batch-url-value="<%= master_batch_save_url %>"
     data-<name>-grid-detail-batch-url-template-value="<%= detail_batch_save_url_template %>"
     data-<name>-grid-detail-list-url-template-value="/<ns>/<master_resource>/:id/details.json"
     data-<name>-grid-selected-key-value="<%= selected_key.to_s %>">
  <%= render Ui::SearchFormComponent.new(url: create_url, fields: search_fields, cols: 3, enable_collapse: true) %>

  <%= render Ui::AgGridComponent.new(columns: master_columns, url: grid_url, grid_id: "<name>-master", data: { <name>_grid_target: "masterGrid" }) %>
  <%= render Ui::AgGridComponent.new(columns: detail_columns, row_data: [], grid_id: "<name>-detail", data: { <name>_grid_target: "detailGrid" }) %>
</div>
```

## 4. Stimulus (`app/javascript/controllers/<ns>/<name>_grid_controller.js`)

```javascript
import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import {
  fetchJson,
  setManagerRowData,
  hasPendingChanges,
  blockIfPendingChanges,
  buildTemplateUrl,
  refreshSelectionLabel
} from "controllers/grid/grid_utils"

const YES_NO_VALUES = ["Y", "N"]

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedKey: String
  }

  connect() {
    super.connect()
    this.refreshSelectedLabel()
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "<master_code>"
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => {
          this.selectedKeyValue = rowData?.<master_code> || ""
          this.refreshSelectedLabel()
          this.clearDetailRows()
        },
        detailLoader: async (rowData) => {
          const id = rowData?.<master_code>
          const hasLoadableId = Boolean(id) && !rowData?.__is_deleted && !rowData?.__is_new
          if (!hasLoadableId) return []

          try {
            const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":id", id)
            const rows = await fetchJson(url)
            return Array.isArray(rows) ? rows : []
          } catch {
            showAlert("상세 목록 조회에 실패했습니다.")
            return []
          }
        }
      }
    }
  }

  masterManagerConfig() {
    return {
      pkFields: ["<master_code>"],
      fields: { <master_code>: "trimUpper", <master_name>: "trim", use_yn: "trimUpperDefault:Y" },
      defaultRow: { <master_code>: "", <master_name>: "", use_yn: "Y" },
      blankCheckFields: ["<master_code>", "<master_name>"],
      comparableFields: ["<master_name>", "use_yn"],
      validationRules: {
        requiredFields: ["<master_code>", "<master_name>", "use_yn"],
        fieldRules: { use_yn: [{ type: "enum", values: YES_NO_VALUES }] }
      },
      firstEditCol: "<master_code>"
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["<detail_code>"],
      fields: { <detail_code>: "trimUpper", <detail_name>: "trim", use_yn: "trimUpperDefault:Y" },
      defaultRow: { <detail_code>: "", <detail_name>: "", use_yn: "Y" },
      blankCheckFields: ["<detail_code>", "<detail_name>"],
      comparableFields: ["<detail_name>", "use_yn"],
      validationRules: {
        requiredFields: ["<detail_code>", "<detail_name>", "use_yn"],
        fieldRules: { use_yn: [{ type: "enum", values: YES_NO_VALUES }] }
      },
      firstEditCol: "<detail_code>"
    }
  }

  get masterManager() { return this.gridManager("master") }
  get detailManager() { return this.gridManager("detail") }

  addMasterRow() { this.addRow({ manager: this.masterManager }) }
  deleteMasterRows() { this.deleteRows({ manager: this.masterManager }) }
  saveMasterRows() {
    return this.saveRowsWith({
      manager: this.masterManager,
      batchUrl: this.masterBatchUrlValue,
      saveMessage: "마스터 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  addDetailRow() {
    if (!this.selectedKeyValue) return showAlert("마스터를 먼저 선택해주세요.")
    if (this.blockDetailActionIfMasterChanged()) return
    this.addRow({ manager: this.detailManager, overrides: { <master_fk>: this.selectedKeyValue } })
  }

  deleteDetailRows() {
    if (this.blockDetailActionIfMasterChanged()) return
    this.deleteRows({ manager: this.detailManager })
  }

  saveDetailRows() {
    if (!this.selectedKeyValue) return showAlert("마스터를 먼저 선택해주세요.")
    if (this.blockDetailActionIfMasterChanged()) return
    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":id", this.selectedKeyValue)
    return this.saveRowsWith({
      manager: this.detailManager,
      batchUrl,
      saveMessage: "상세 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  beforeSearchReset() {
    this.selectedKeyValue = ""
    this.refreshSelectedLabel()
  }

  clearDetailRows() { setManagerRowData(this.detailManager, []) }
  hasMasterPendingChanges() { return hasPendingChanges(this.masterManager) }
  blockDetailActionIfMasterChanged() { return blockIfPendingChanges(this.masterManager, "마스터") }

  refreshSelectedLabel() {
    if (!this.hasSelectedLabelTarget) return
    refreshSelectionLabel(this.selectedLabelTarget, this.selectedKeyValue, "마스터", "마스터를 먼저 선택해주세요.")
  }
}
```

## 5. Master Controller 핵심 구조

```ruby
def index
  @selected_key = params[:selected_key].presence

  respond_to do |format|
    format.html
    format.json { render json: master_scope.map { |row| master_json(row) } }
  end
end

def batch_save
  operations = batch_save_params
  result = { inserted: 0, updated: 0, deleted: 0 }
  errors = []

  ActiveRecord::Base.transaction do
    process_inserts(operations[:rowsToInsert], result, errors)
    process_updates(operations[:rowsToUpdate], result, errors)
    process_deletes(operations[:rowsToDelete], result, errors)
    raise ActiveRecord::Rollback if errors.any?
  end

  if errors.any?
    render_failure(errors: errors.uniq)
  else
    render_success(message: "저장이 완료되었습니다.", payload: { data: result })
  end
end
```

## 6. Detail Controller 핵심 구조

```ruby
def index
  master = master_row
  if master.nil?
    render json: []
  else
    render json: master.details.ordered.map { |row| detail_json(row) }
  end
end

def batch_save
  operations = batch_save_params
  master = master_row!
  result = { inserted: 0, updated: 0, deleted: 0 }
  errors = []

  ActiveRecord::Base.transaction do
    process_detail_inserts(master, operations[:rowsToInsert], result, errors)
    process_detail_updates(master, operations[:rowsToUpdate], result, errors)
    process_detail_deletes(master, operations[:rowsToDelete], result, errors)
    raise ActiveRecord::Rollback if errors.any?
  end

  if errors.any?
    render_failure(errors: errors.uniq)
  else
    render_success(message: "상세 저장이 완료되었습니다.", payload: { data: result })
  end
end
```
