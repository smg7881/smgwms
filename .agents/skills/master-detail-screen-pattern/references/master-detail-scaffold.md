# Master-Detail Scaffold

아래 템플릿을 복사한 뒤 화면별 이름과 필드로 치환해서 사용합니다.

## Standard Terms
- Contract Registry: `config/master_detail_screen_contracts.yml`
- Contract Test: `test/contracts/master_detail_pattern_contract_test.rb`
- PR Gate: `.github/PULL_REQUEST_TEMPLATE.md` + `.github/CODEOWNERS`

## 1. Routes

```ruby
namespace :<ns> do
  resources :<master_resource>, only: [ :index ] do
    post :batch_save, on: :collection

    resources :details, controller: :<detail_controller>, only: [ :index ], param: :<detail_param> do
      post :batch_save, on: :collection
    end
  end
end
```

## 2. PageComponent (`app/components/<ns>/<module>/page_component.rb`)

```ruby
class <Ns>::<Module>::PageComponent <<Ns>::BasePageComponent
  def initialize(query_params:, selected_master:)
    super(query_params: query_params)
    @selected_master = selected_master.presence
  end

  private
    attr_reader :selected_master

    def collection_path(**) = helpers.<ns>_<master_resource>_path(**)
    def member_path(id, **) = helpers.<ns>_<master_singular>_path(id, **)
    def detail_collection_path(id, **) = helpers.<ns>_<master_singular>_details_path(id, **)

    def detail_grid_url
      if selected_master.present?
        detail_collection_path(selected_master, format: :json)
      else
        nil
      end
    end

    def master_batch_save_url
      helpers.batch_save_<ns>_<master_resource>_path
    end

    def detail_batch_save_url_template
      "/<ns>/<master_resource>/:id/details/batch_save"
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
     data-<name>-grid-selected-master-value="<%= selected_master.to_s %>">
  <%= render Ui::SearchFormComponent.new(url: create_url, fields: search_fields, cols: 3, enable_collapse: true) %>

  <%= render Ui::AgGridComponent.new(
    columns: master_columns,
    url: grid_url,
    grid_id: "<name>-master",
    data: { <name>_grid_target: "masterGrid" }
  ) %>

  <%= render Ui::AgGridComponent.new(
    columns: detail_columns,
    row_data: [],
    grid_id: "<name>-detail",
    data: { <name>_grid_target: "detailGrid" }
  ) %>
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
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedMasterLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedMaster: String
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "<master_key>"
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        detailLoader: async (rowData) => {
          const masterKey = rowData?.<master_key>
          const hasLoadableKey = Boolean(masterKey) && !rowData?.__is_deleted && !rowData?.__is_new
          if (!hasLoadableKey) return []

          try {
            const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":id", masterKey)
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

  async saveMasterRows() {
    await this.saveRowsWith({
      manager: this.gridManager("master"),
      batchUrl: this.masterBatchUrlValue,
      saveMessage: "마스터 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  async saveDetailRows() {
    if (this.blockDetailActionIfMasterChanged()) return
    if (!this.selectedMasterValue) {
      showAlert("마스터를 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":id", this.selectedMasterValue)
    await this.saveRowsWith({
      manager: this.gridManager("detail"),
      batchUrl,
      saveMessage: "상세 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.gridManager("master"), "마스터")
  }
}
```

## 5. Master Controller Skeleton

```ruby
def index
  @selected_master = params[:selected_master].presence

  respond_to do |format|
    format.html
    format.json { render json: records_scope.map { |row| record_json(row) } }
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
    render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
  else
    render json: { success: true, data: result }
  end
end
```

## 6. Detail Controller Skeleton

```ruby
def index
  master = find_master
  if master.nil?
    render json: []
  else
    render json: master.details.ordered.map { |row| detail_json(row) }
  end
end

def batch_save
  operations = batch_save_params
  master = find_master!
  result = { inserted: 0, updated: 0, deleted: 0 }
  errors = []

  ActiveRecord::Base.transaction do
    process_detail_inserts(master, operations[:rowsToInsert], result, errors)
    process_detail_updates(master, operations[:rowsToUpdate], result, errors)
    process_detail_deletes(master, operations[:rowsToDelete], result, errors)
    raise ActiveRecord::Rollback if errors.any?
  end

  if errors.any?
    render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
  else
    render json: { success: true, data: result }
  end
end
```

## Mandatory Gate (Required)
1. Contract Registry 등록
- 신규 화면을 `config/master_detail_screen_contracts.yml`에 추가
2. Contract Test 통과
- `ruby bin/rails test test/contracts/master_detail_pattern_contract_test.rb`
- 또는 `ruby bin/rails wm:contracts:master_detail`
3. PR Gate 통과
- `.github/PULL_REQUEST_TEMPLATE.md`의 Master-Detail 체크
- `.github/CODEOWNERS` 승인 조건 확인
4. 하나라도 실패하면 merge 금지
