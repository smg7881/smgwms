import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static resourceName = "zipcode"
  static deleteConfirmKey = "zipCodeLabel"
  static entityLabel = "우편번호"

  static targets = [
    ...BaseGridController.targets,
    "overlay", "modal", "modalTitle", "form",
    "fieldId", "fieldCtryCd", "fieldZipcd", "fieldSeqNo"
  ]

  static values = {
    ...BaseGridController.values,
    createUrl: String,
    updateUrl: String,
    deleteUrl: String
  }

  connect() {
    super.connect()
    // handleDelete는 ModalMixin에서 일반 메서드로 정의되어 있으므로 this 바인딩이 필요합니다.
    this.handleDelete = this.handleDelete.bind(this)
    this.connectBase({
      events: [
        { name: "std-zipcode-crud:edit", handler: this.handleEdit },
        { name: "std-zipcode-crud:delete", handler: this.handleDelete }
      ]
    })
  }

  disconnect() {
    this.disconnectBase()
    super.disconnect()
  }

  openCreate() {
    this.resetForm()
    this.modalTitleTarget.textContent = "우편번호 등록"
    this.mode = "create"

    this.fieldCtryCdTarget.readOnly = false
    this.fieldZipcdTarget.readOnly = false
    this.fieldSeqNoTarget.readOnly = false

    this.setFieldValues({
      ctry_cd: this.selectedCountryCodeFromSearch() || "KR",
      ctry_lookup: this.selectedCountryNameFromSearch(),
      seq_no: 1,
      use_yn_cd: "Y"
    })
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

    this.setFieldValues({
      ctry_cd: data.ctry_cd || "",
      ctry_lookup: data.ctry_nm || data.ctry_cd || "",
      zipcd: data.zipcd || "",
      seq_no: data.seq_no ?? "",
      zipaddr: data.zipaddr || "",
      sido: data.sido || "",
      sgng: data.sgng || "",
      eupdiv: data.eupdiv || "",
      addr_ri: data.addr_ri || "",
      iland_san: data.iland_san || "",
      san_houseno: data.san_houseno || "",
      apt_bild_nm: data.apt_bild_nm || "",
      strt_houseno_wek: data.strt_houseno_wek || "",
      strt_houseno_mnst: data.strt_houseno_mnst || "",
      end_houseno_wek: data.end_houseno_wek || "",
      end_houseno_mnst: data.end_houseno_mnst || "",
      dong_rng_strt: data.dong_rng_strt || "",
      dong_houseno_end: data.dong_houseno_end || "",
      chg_ymd: this.normalizeDateValue(data.chg_ymd),
      use_yn_cd: data.use_yn_cd || "Y"
    })
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

    this.setFieldValues({
      ctry_lookup: "",
      seq_no: 1,
      addr_ri: "",
      iland_san: "",
      san_houseno: "",
      apt_bild_nm: "",
      strt_houseno_wek: "",
      strt_houseno_mnst: "",
      end_houseno_wek: "",
      end_houseno_mnst: "",
      dong_rng_strt: "",
      dong_houseno_end: "",
      chg_ymd: "",
      use_yn_cd: "Y",
      create_by: "",
      create_time: "",
      update_by: "",
      update_time: ""
    })
    this.syncPopupDisplaysFromCodes()
  }

  selectedCountryCodeFromSearch() {
    return this.getSearchFormValue("ctry_cd")
  }

  selectedCountryNameFromSearch() {
    return this.getSearchFormValue("ctry_nm", { toUpperCase: false })
  }

  setAuditPreviewForCreate() {
    const nowText = this.formatDateTime(new Date())
    const actor = this.currentActor()
    this.setFieldValue("create_by", actor)
    this.setFieldValue("create_time", nowText)
    this.setFieldValue("update_by", actor)
    this.setFieldValue("update_time", nowText)
  }

  setAuditValues(data) {
    this.setFieldValue("create_by", data.create_by || "")
    this.setFieldValue("create_time", this.formatDateTime(data.create_time))
    this.setFieldValue("update_by", data.update_by || "")
    this.setFieldValue("update_time", this.formatDateTime(data.update_time))
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
