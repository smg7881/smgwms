import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { getCsrfToken } from "controllers/grid/core/http_client"
import { attachDrag } from "controllers/popup/popup_drag_mixin"

export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "overlay",
    "modal",
    "modalTitle",
    "selectedRequestNo",
    "modalCorpCd",
    "modalMenuNm",
    "modalRequestNo",
    "modalRequester",
    "modalApprover",
    "modalApproverCode",
    "modalApproverDisplay",
    "modalRequestContents",
    "modalRequestYmd",
    "modalOpinion",
    "modalApproveYmd",
    "modalStatus",
    "modalType",
    "requestButton",
    "approveButton"
  ]

  static values = {
    ...BaseGridController.values,
    requestUrl: String,
    approveUrl: String,
    currentUserCode: String
  }

  connect() {
    super.connect()
    this.mode = "viewer"
    this._rowDoubleBound = false
  }

  disconnect() {
    this._dragInstance?.destroy()
    this._dragInstance = null
    this.unbindGridDoubleClick()
    super.disconnect()
  }

  configureManager() {
    return {
      pkFields: ["apv_req_no"],
      fields: {
        apv_req_no: "trimUpper",
        menu_nm: "trim",
        apv_req_ymd: "trim",
        apv_reqr: "trimUpper",
        apv_stat_cd: "trimUpper",
        asmt_apver: "trimUpper",
        apv_apv_ymd: "trim",
        apv_req_conts: "trim",
        apv_opi: "trim",
        update_by: "trimUpper",
        update_time: "trim"
      },
      defaultRow: {
      },
      blankCheckFields: ["apv_req_no"],
      comparableFields: [],
      firstEditCol: "apv_req_no",
      pkLabels: { apv_req_no: "결재요청번호" }
    }
  }

  registerGrid(event) {
    super.registerGrid(event)
    this.bindGridDoubleClick()
  }

  bindGridDoubleClick() {
    if (!this.manager?.api || this._rowDoubleBound) return
    this._onRowDoubleClicked = (event) => this.openDetailPopup(event?.data)
    this.manager.api.addEventListener("rowDoubleClicked", this._onRowDoubleClicked)
    this._rowDoubleBound = true
  }

  unbindGridDoubleClick() {
    if (!this.manager?.api || !this._rowDoubleBound || !this._onRowDoubleClicked) return
    this.manager.api.removeEventListener("rowDoubleClicked", this._onRowDoubleClicked)
    this._onRowDoubleClicked = null
    this._rowDoubleBound = false
  }

  async requestRows() {
    if (!this.manager?.api) return

    const selectedRows = this.manager.api.getSelectedRows()
    if (!selectedRows.length) {
      showAlert("처리할 행을 선택해주세요.")
      return
    }

    if (selectedRows.length === 1) {
      this.openDetailPopup(selectedRows[0])
      return
    }

    const apvReqNos = selectedRows.map((row) => row.apv_req_no).filter((value) => value)
    const inputContent = window.prompt("결재요청내용을 입력하세요.", "")
    if (inputContent === null) {
      return
    }

    await this.submitAction(this.requestUrlValue, {
      apv_req_nos: apvReqNos,
      apv_req_conts: inputContent
    })
  }

  async approveRows() {
    if (!this.manager?.api) return

    const selectedRows = this.manager.api.getSelectedRows()
    if (!selectedRows.length) {
      showAlert("처리할 행을 선택해주세요.")
      return
    }

    if (selectedRows.length === 1) {
      this.openDetailPopup(selectedRows[0])
      return
    }

    const apvReqNos = selectedRows.map((row) => row.apv_req_no).filter((value) => value)
    const inputOpinion = window.prompt("결재의견을 입력하세요.", "")
    if (inputOpinion === null) {
      return
    }

    await this.submitAction(this.approveUrlValue, {
      apv_req_nos: apvReqNos,
      apv_opi: inputOpinion
    })
  }

  submitRequestFromModal(event) {
    event.preventDefault()

    const reqNo = this.selectedRequestNoTarget.value
    if (!reqNo) {
      showAlert("결재요청번호를 확인해주세요.")
      return
    }

    if (this.mode !== "requester") {
      showAlert("요청 처리 권한이 없습니다.")
      return
    }

    const requestContents = this.modalRequestContentsTarget.value
    this.submitAction(this.requestUrlValue, {
      apv_req_nos: [reqNo],
      apv_req_conts: requestContents,
      apver_chg: this.modalApproverCodeTarget.value,
      apv_stat_cd: this.modalStatusTarget.value,
      apv_type_cd: this.modalTypeTarget.value
    }, { closeModal: true })
  }

  submitApproveFromModal(event) {
    event.preventDefault()

    const reqNo = this.selectedRequestNoTarget.value
    if (!reqNo) {
      showAlert("결재요청번호를 확인해주세요.")
      return
    }

    if (this.mode !== "approver") {
      showAlert("승인 처리 권한이 없습니다.")
      return
    }

    const opinion = this.modalOpinionTarget.value
    this.submitAction(this.approveUrlValue, {
      apv_req_nos: [reqNo],
      apv_opi: opinion,
      apver_chg: this.modalApproverCodeTarget.value,
      apv_stat_cd: this.modalStatusTarget.value,
      apv_type_cd: this.modalTypeTarget.value
    }, { closeModal: true })
  }

  openDetailPopup(row) {
    if (!row) return

    this.selectedRequestNoTarget.value = row.apv_req_no || ""
    this.modalCorpCdTarget.value = row.corp_cd || ""
    this.modalMenuNmTarget.value = row.menu_nm || ""
    this.modalRequestNoTarget.value = row.apv_req_no || ""
    this.modalRequesterTarget.value = row.apv_reqr || ""
    this.modalApproverTarget.value = row.asmt_apver || ""
    const changedApprover = row.apver_chg || row.asmt_apver || ""
    this.modalApproverCodeTarget.value = changedApprover
    this.modalApproverDisplayTarget.value = changedApprover
    this.modalRequestContentsTarget.value = row.apv_req_conts || ""
    this.modalRequestYmdTarget.value = this.formatDateTime(row.apv_req_ymd)
    this.modalOpinionTarget.value = row.apv_opi || ""
    this.modalApproveYmdTarget.value = this.formatDateTime(row.apv_apv_ymd)
    this.modalStatusTarget.value = row.apv_stat_cd || "REQUESTED"
    this.modalTypeTarget.value = row.apv_type_cd || ""
    this.modalTitleTarget.textContent = `결재요청승인 - ${row.apv_req_no || ""}`

    this.applyMode(row)
    this.openModal()
  }

  applyMode(row) {
    const currentUser = this.currentUserCodeValue.toString().trim().toUpperCase()
    const requester = (row.apv_reqr || "").toString().trim().toUpperCase()
    const approver = ((row.apver_chg || row.asmt_apver) || "").toString().trim().toUpperCase()

    if (currentUser && currentUser === requester) {
      this.mode = "requester"
    } else if (currentUser && currentUser === approver) {
      this.mode = "approver"
    } else {
      this.mode = "viewer"
    }

    this.requestButtonTarget.hidden = this.mode !== "requester"
    this.approveButtonTarget.hidden = this.mode !== "approver"

    this.modalRequestContentsTarget.readOnly = this.mode !== "requester"
    this.modalOpinionTarget.readOnly = this.mode !== "approver"
    this.modalApproverDisplayTarget.readOnly = this.mode !== "requester"
    this.modalStatusTarget.disabled = this.mode === "viewer"
    this.modalTypeTarget.readOnly = true
  }

  async submitAction(url, body, options = {}) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken()
        },
        body: JSON.stringify(body)
      })
      const result = await response.json()
      if (!response.ok || !result.success) {
        showAlert("처리 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "처리가 완료되었습니다.")
      if (options.closeModal) {
        this.closeModal()
      }
      this.reloadRows()
    } catch {
      showAlert("처리 실패: 네트워크 오류")
    }
  }

  openModal() {
    this.overlayTarget.hidden = false
    if (this.hasModalTarget) {
      const header = this.modalTarget.querySelector(".app-modal-header")
      if (header) this._dragInstance = attachDrag(this.modalTarget, header)
    }
  }

  closeModal() {
    this._dragInstance?.destroy()
    this._dragInstance = null
    this.overlayTarget.hidden = true
  }

  closeModalOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.closeModal()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  formatDateTime(value) {
    if (!value) return ""
    if (typeof value === "string") return value
    try {
      return new Date(value).toISOString().slice(0, 19).replace("T", " ")
    } catch {
      return ""
    }
  }
}

