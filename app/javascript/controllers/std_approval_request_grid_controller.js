import BaseGridController from "controllers/base_grid_controller"
import { getCsrfToken } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    requestUrl: String,
    approveUrl: String
  }

  configureManager() {
    return {
      pkFields: ["apv_req_no"],
      fields: {
        apv_req_no: "trimUpper",
        corp_cd: "trimUpper",
        menu_cd: "trimUpper",
        menu_nm: "trim",
        apv_reqr: "trimUpper",
        asmt_apver: "trimUpper",
        apver_chg: "trimUpper",
        user_cd: "trimUpper",
        apv_req_conts: "trim",
        apv_req_ymd: "trim",
        apv_opi: "trim",
        apv_apv_ymd: "trim",
        apv_stat_cd: "trimUpperDefault:REQUESTED",
        apv_type_cd: "trimUpper",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        apv_req_no: "",
        corp_cd: "",
        menu_cd: "",
        menu_nm: "",
        apv_reqr: "",
        asmt_apver: "",
        apver_chg: "",
        user_cd: "",
        apv_req_conts: "",
        apv_req_ymd: "",
        apv_opi: "",
        apv_apv_ymd: "",
        apv_stat_cd: "REQUESTED",
        apv_type_cd: "CODE",
        use_yn: "Y"
      },
      blankCheckFields: ["menu_nm"],
      comparableFields: [
        "corp_cd", "menu_cd", "menu_nm", "apv_reqr", "asmt_apver", "apver_chg", "user_cd",
        "apv_req_conts", "apv_req_ymd", "apv_opi", "apv_apv_ymd", "apv_stat_cd", "apv_type_cd", "use_yn"
      ],
      firstEditCol: "menu_nm",
      pkLabels: { apv_req_no: "결재요청번호" }
    }
  }

  async requestRows() {
    if (!this.manager?.api) return

    const selectedRows = this.manager.api.getSelectedRows()
    if (!selectedRows.length) {
      alert("처리할 행을 선택해주세요.")
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
    }, "결재요청 처리가 완료되었습니다.")
  }

  async approveRows() {
    if (!this.manager?.api) return

    const selectedRows = this.manager.api.getSelectedRows()
    if (!selectedRows.length) {
      alert("처리할 행을 선택해주세요.")
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
    }, "결재승인 처리가 완료되었습니다.")
  }

  async submitAction(url, body, successMessage) {
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
        alert("처리 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || successMessage)
      this.reloadRows()
    } catch {
      alert("처리 실패: 네트워크 오류")
    }
  }

  get saveMessage() {
    return "결재요청 데이터가 저장되었습니다."
  }
}
