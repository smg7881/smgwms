import ClientGridController from "controllers/std/client_grid_controller"
import { showAlert } from "components/ui/alert"
import {
  buildTemplateUrl,
  blockIfPendingChanges,
  refreshSelectionLabel
} from "controllers/grid/grid_utils"

export default class extends ClientGridController {
  masterManagerConfig() {
    const config = super.masterManagerConfig()
    const validationRules = config.validationRules || {}
    const fieldLabels = validationRules.fieldLabels || {}
    const pkLabels = config.pkLabels || {}

    return {
      ...config,
      pkLabels: {
        ...pkLabels,
        bzac_cd: "고객거래처코드"
      },
      validationRules: {
        ...validationRules,
        fieldLabels: {
          ...fieldLabels,
          bzac_nm: "고객거래처명",
          bzac_sctn_grp_cd: "고객거래처구분그룹",
          bzac_sctn_cd: "고객거래처구분",
          bzac_kind_cd: "고객거래처종류"
        }
      }
    }
  }

  async saveMasterRows() {
    await this.saveRowsWith({
      manager: this.masterManager,
      batchUrl: this.masterBatchUrlValue,
      saveMessage: "고객거래처 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("master")
    })
  }

  addContactRow() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("고객거래처를 먼저 선택해주세요.")
      return
    }

    this.addRow({ manager: this.contactManager })
  }

  async saveContactRows() {
    if (!this.contactManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("고객거래처를 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.contactBatchUrlTemplateValue, ":id", this.selectedClientValue)
    await this.saveRowsWith({
      manager: this.contactManager,
      batchUrl,
      saveMessage: "고객거래처 담당자 데이터가 저장되었습니다.",
      onSuccess: () => this.reloadContactRows(this.selectedClientValue)
    })
  }

  addWorkplaceRow() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("고객거래처를 먼저 선택해주세요.")
      return
    }

    this.addRow({ manager: this.workplaceManager })
  }

  async saveWorkplaceRows() {
    if (!this.workplaceManager) return
    if (this.blockDetailActionIfMasterChanged()) return

    if (!this.selectedClientValue) {
      showAlert("고객거래처를 먼저 선택해주세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.workplaceBatchUrlTemplateValue, ":id", this.selectedClientValue)
    await this.saveRowsWith({
      manager: this.workplaceManager,
      batchUrl,
      saveMessage: "고객거래처 작업장 데이터가 저장되었습니다.",
      onSuccess: () => this.reloadWorkplaceRows(this.selectedClientValue)
    })
  }

  refreshSelectedClientLabel() {
    if (!this.hasSelectedClientLabelTarget) return

    refreshSelectionLabel(this.selectedClientLabelTarget, this.selectedClientValue, "고객거래처", "고객거래처를 먼저 선택하세요.")
  }

  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.masterManager, "마스터 고객거래처")
  }
}
