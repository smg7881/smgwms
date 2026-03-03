import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { getCsrfToken } from "controllers/grid/grid_utils"

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
    this.dragState = null
    this.mode = "viewer"
    this._boundDragMove = this.handleDragMove.bind(this)
    this._boundEndDrag = this.endDrag.bind(this)
    window.addEventListener("mousemove", this._boundDragMove)
    window.addEventListener("mouseup", this._boundEndDrag)
    this._rowDoubleBound = false
  }

  disconnect() {
    window.removeEventListener("mousemove", this._boundDragMove)
    window.removeEventListener("mouseup", this._boundEndDrag)
    this.endDrag()
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
  }

  closeModal() {
    this.overlayTarget.hidden = true
    this.endDrag()
  }

  closeModalOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.closeModal()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  startDrag(event) {
    if (event.button !== 0) return
    if (!this.hasModalTarget) return
    if (event.target.closest("button")) return

    const modalRect = this.modalTarget.getBoundingClientRect()
    this.modalTarget.style.position = "absolute"
    this.modalTarget.style.left = `${modalRect.left}px`
    this.modalTarget.style.top = `${modalRect.top}px`
    this.modalTarget.style.margin = "0"

    this.dragState = {
      offsetX: event.clientX - modalRect.left,
      offsetY: event.clientY - modalRect.top
    }

    document.body.style.userSelect = "none"
    this.modalTarget.style.cursor = "grabbing"
    event.preventDefault()
  }

  handleDragMove(event) {
    if (!this.dragState || !this.hasModalTarget) return

    const maxLeft = Math.max(0, window.innerWidth - this.modalTarget.offsetWidth)
    const maxTop = Math.max(0, window.innerHeight - this.modalTarget.offsetHeight)
    const nextLeft = event.clientX - this.dragState.offsetX
    const nextTop = event.clientY - this.dragState.offsetY
    const clampedLeft = Math.min(Math.max(0, nextLeft), maxLeft)
    const clampedTop = Math.min(Math.max(0, nextTop), maxTop)

    this.modalTarget.style.left = `${clampedLeft}px`
    this.modalTarget.style.top = `${clampedTop}px`
  }

  endDrag() {
    this.dragState = null
    document.body.style.userSelect = ""
    if (this.hasModalTarget) {
      this.modalTarget.style.cursor = ""
    }
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

