import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static resourceName = "std_zip_code"
  static deleteConfirmKey = "zipCodeLabel"
  static entityLabel = "우편번호"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCtryCd", "fieldZipcd", "fieldSeqNo",
    "fieldZipaddr", "fieldSido", "fieldSgng", "fieldEupdiv",
    "fieldAddrRi", "fieldIlandSan", "fieldSanHouseno", "fieldAptBildNm",
    "fieldStrtHousenoWek", "fieldStrtHousenoMnst", "fieldEndHousenoWek", "fieldEndHousenoMnst",
    "fieldDongRngStrt", "fieldDongHousenoEnd", "fieldChgYmd",
    "fieldUseYnCd", "fieldCreateBy", "fieldCreateTime", "fieldUpdateBy", "fieldUpdateTime"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    super.connect()
    this.connectModal({
      events: [
        { name: "std-zipcode-crud:edit", handler: this.handleEdit },
        { name: "std-zipcode-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectModal()
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "우편번호 등록"
    this.mode = "create"

    this.fieldCtryCdTarget.readOnly = false
    this.fieldZipcdTarget.readOnly = false
    this.fieldSeqNoTarget.readOnly = false
    this.fieldCtryCdTarget.value = this.selectedCountryCodeFromSearch() || "KR"
    this.fieldSeqNoTarget.value = 1
    this.fieldUseYnCdTarget.value = "Y"
    this.setAuditPreviewForCreate()
    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  handleEdit = (event) => {
    const data = event.detail.zipcodeData || {}

    this.resetForm()
    this.modalTitleTarget.textContent = "우편번호 수정"
    this.mode = "update"

    this.fieldIdTarget.value = data.id || ""
    this.fieldCtryCdTarget.readOnly = true
    this.fieldZipcdTarget.readOnly = true
    this.fieldSeqNoTarget.readOnly = true

    this.fieldCtryCdTarget.value = data.ctry_cd || ""
    this.fieldZipcdTarget.value = data.zipcd || ""
    this.fieldSeqNoTarget.value = data.seq_no ?? ""
    this.fieldZipaddrTarget.value = data.zipaddr || ""
    this.fieldSidoTarget.value = data.sido || ""
    this.fieldSgngTarget.value = data.sgng || ""
    this.fieldEupdivTarget.value = data.eupdiv || ""
    this.fieldAddrRiTarget.value = data.addr_ri || ""
    this.fieldIlandSanTarget.value = data.iland_san || ""
    this.fieldSanHousenoTarget.value = data.san_houseno || ""
    this.fieldAptBildNmTarget.value = data.apt_bild_nm || ""
    this.fieldStrtHousenoWekTarget.value = data.strt_houseno_wek || ""
    this.fieldStrtHousenoMnstTarget.value = data.strt_houseno_mnst || ""
    this.fieldEndHousenoWekTarget.value = data.end_houseno_wek || ""
    this.fieldEndHousenoMnstTarget.value = data.end_houseno_mnst || ""
    this.fieldDongRngStrtTarget.value = data.dong_rng_strt || ""
    this.fieldDongHousenoEndTarget.value = data.dong_houseno_end || ""
    this.fieldChgYmdTarget.value = this.normalizeDateValue(data.chg_ymd)
    this.fieldUseYnCdTarget.value = data.use_yn_cd || "Y"

    this.setAuditValues(data)

    this.syncPopupDisplaysFromCodes()
    this.openModal()
  }

  resetForm() {
    this.formTarget.reset()
    this.fieldIdTarget.value = ""
    this.fieldCtryCdTarget.readOnly = false
    this.fieldZipcdTarget.readOnly = false
    this.fieldSeqNoTarget.readOnly = false
    this.fieldCtryCdTarget.value = ""
    this.fieldZipcdTarget.value = ""
    this.fieldSeqNoTarget.value = 1
    this.fieldZipaddrTarget.value = ""
    this.fieldSidoTarget.value = ""
    this.fieldSgngTarget.value = ""
    this.fieldEupdivTarget.value = ""
    this.fieldAddrRiTarget.value = ""
    this.fieldIlandSanTarget.value = ""
    this.fieldSanHousenoTarget.value = ""
    this.fieldAptBildNmTarget.value = ""
    this.fieldStrtHousenoWekTarget.value = ""
    this.fieldStrtHousenoMnstTarget.value = ""
    this.fieldEndHousenoWekTarget.value = ""
    this.fieldEndHousenoMnstTarget.value = ""
    this.fieldDongRngStrtTarget.value = ""
    this.fieldDongHousenoEndTarget.value = ""
    this.fieldChgYmdTarget.value = ""
    this.fieldUseYnCdTarget.value = "Y"
    this.fieldCreateByTarget.value = ""
    this.fieldCreateTimeTarget.value = ""
    this.fieldUpdateByTarget.value = ""
    this.fieldUpdateTimeTarget.value = ""
    this.syncPopupDisplaysFromCodes()
  }

  selectedCountryCodeFromSearch() {
    return this.getSearchFormValue("ctry_cd")
  }

  setAuditPreviewForCreate() {
    const nowText = this.formatDateTime(new Date())
    const actor = this.currentActor()
    this.fieldCreateByTarget.value = actor
    this.fieldCreateTimeTarget.value = nowText
    this.fieldUpdateByTarget.value = actor
    this.fieldUpdateTimeTarget.value = nowText
  }

  setAuditValues(data) {
    this.fieldCreateByTarget.value = data.create_by || ""
    this.fieldCreateTimeTarget.value = this.formatDateTime(data.create_time)
    this.fieldUpdateByTarget.value = data.update_by || ""
    this.fieldUpdateTimeTarget.value = this.formatDateTime(data.update_time)
  }

  normalizeDateValue(value) {
    if (!value) return ""
    if (value instanceof Date && !Number.isNaN(value.getTime())) {
      return value.toISOString().slice(0, 10)
    }
    return String(value).slice(0, 10)
  }

  currentActor() {
    const userLabel = document.querySelector(".sidebar .text-text-muted")
    const value = String(userLabel?.textContent || "").trim()
    if (value) return value

    return "현재로그인사용자"
  }
}
