/**
 * code_grid_controller.js
 *
 * 그룹코드(마스터) + 상세코드(디테일) 관리 화면
 * - BaseGridController의 gridRoles(parentGrid) 기반 공통 마스터-디테일 연동 사용
 */
import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import {
  isApiAlive,
  fetchJson,
  setManagerRowData,
  hasPendingChanges,
  blockIfPendingChanges,
  buildTemplateUrl,
  refreshSelectionLabel
} from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedCodeLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedCode: String
  }

  connect() {
    super.connect()
    this.refreshSelectedCodeLabel()
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "code"
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => {
          this.selectedCodeValue = rowData?.code || ""
          this.refreshSelectedCodeLabel()
          this.clearDetailRows()
        },
        detailLoader: async (rowData) => {
          const code = rowData?.code
          const hasLoadableCode = Boolean(code) && !rowData?.__is_deleted && !rowData?.__is_new
          if (!hasLoadableCode) return []

          try {
            const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":code", code)
            const rows = await fetchJson(url)
            return Array.isArray(rows) ? rows : []
          } catch {
            showAlert("상세코드 목록 조회에 실패했습니다.")
            return []
          }
        }
      }
    }
  }

  masterManagerConfig() {
    return {
      pkFields: ["code"],
      fields: {
        code: "trim",
        code_name: "trim",
        sys_sctn_cd: "trimUpper",
        rmk: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { code: "", code_name: "", sys_sctn_cd: "", rmk: "", use_yn: "Y" },
      blankCheckFields: ["code", "code_name"],
      comparableFields: ["code_name", "sys_sctn_cd", "rmk", "use_yn"],
      firstEditCol: "code",
      pkLabels: { code: "코드" }
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["detail_code"],
      fields: {
        detail_code: "trim",
        detail_code_name: "trim",
        short_name: "trim",
        upper_code: "trimUpper",
        upper_detail_code: "trimUpper",
        rmk: "trim",
        attr1: "trim",
        attr2: "trim",
        attr3: "trim",
        attr4: "trim",
        attr5: "trim",
        sort_order: "number",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        code: "",
        detail_code: "",
        detail_code_name: "",
        short_name: "",
        upper_code: "",
        upper_detail_code: "",
        rmk: "",
        attr1: "",
        attr2: "",
        attr3: "",
        attr4: "",
        attr5: "",
        sort_order: 0,
        use_yn: "Y"
      },
      blankCheckFields: ["detail_code", "detail_code_name"],
      comparableFields: ["detail_code_name", "short_name", "upper_code", "upper_detail_code", "rmk", "attr1", "attr2", "attr3", "attr4", "attr5", "sort_order", "use_yn"],
      firstEditCol: "detail_code",
      pkLabels: { detail_code: "상세코드" }
    }
  }

  get masterManager() {
    return this.gridManager("master")
  }

  get detailManager() {
    return this.gridManager("detail")
  }

  beforeSearchReset() {
    this.selectedCodeValue = ""
    this.refreshSelectedCodeLabel()
  }

  addMasterRow() {
    this.addRow({
      manager: this.masterManager,
      onAdded: (rowData) => {
        this.selectedCodeValue = rowData?.code || ""
        this.refreshSelectedCodeLabel()
        this.clearDetailRows()
      }
    })
  }

  deleteMasterRows() {
    this.deleteRows({ manager: this.masterManager })
  }

  async saveMasterRows() {
    await this.saveRowsWith({
      manager: this.masterManager,
      batchUrl: this.masterBatchUrlValue,
      saveMessage: "코드 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  addDetailRow() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedCodeValue) {
      showAlert("코드를 먼저 선택해주세요.")
      return
    }

    this.addRow({
      manager: this.detailManager,
      overrides: { code: this.selectedCodeValue }
    })
  }

  deleteDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    this.deleteRows({ manager: this.detailManager })
  }

  async saveDetailRows() {
    if (!this.detailManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedCodeValue) {
      showAlert("코드를 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":code", this.selectedCodeValue)
    await this.saveRowsWith({
      manager: this.detailManager,
      batchUrl,
      saveMessage: "상세코드 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  clearDetailRows() {
    setManagerRowData(this.detailManager, [])
  }

  refreshSelectedCodeLabel() {
    if (!this.hasSelectedCodeLabelTarget) return
    refreshSelectionLabel(this.selectedCodeLabelTarget, this.selectedCodeValue, "코드", "코드를 먼저 선택해주세요.")
  }

  hasMasterPendingChanges() {
    return hasPendingChanges(this.masterManager)
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.masterManager, "마스터 코드")
  }
}
