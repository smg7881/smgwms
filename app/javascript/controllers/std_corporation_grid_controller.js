import MasterDetailGridController from "controllers/master_detail_grid_controller"
import { showAlert } from "components/ui/alert"
import { fetchJson, isApiAlive, setManagerRowData, hasPendingChanges, buildTemplateUrl, refreshSelectionLabel, focusFirstRow } from "controllers/grid/grid_utils"

export default class extends MasterDetailGridController {
  static targets = [...MasterDetailGridController.targets, "countryGrid", "selectedCorpLabel"]

  static values = {
    ...MasterDetailGridController.values,
    masterBatchUrl: String,
    countryBatchUrlTemplate: String,
    countryListUrlTemplate: String
  }

  connect() {
    super.connect()
    this.countryManager = null
    this.selectedCorpCode = ""
  }

  disconnect() {
    this.countryManager?.detach()
    this.countryManager = null
    this.selectedCorpCode = ""
    super.disconnect()
  }

  configureManager() {
    return {
      pkFields: ["corp_cd"],
      fields: {
        corp_cd: "trimUpper",
        corp_nm: "trim",
        indstype_cd: "trim",
        bizcond_cd: "trim",
        rptr_nm_cd: "trim",
        compreg_slip_cd: "trim",
        upper_corp_cd: "trimUpper",
        zip_cd: "trim",
        addr_cd: "trim",
        dtl_addr_cd: "trim",
        vat_sctn_cd: "trimUpper",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        corp_cd: "",
        corp_nm: "",
        indstype_cd: "",
        bizcond_cd: "",
        rptr_nm_cd: "",
        compreg_slip_cd: "",
        upper_corp_cd: "",
        zip_cd: "",
        addr_cd: "",
        dtl_addr_cd: "",
        vat_sctn_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["corp_nm"],
      comparableFields: [
        "corp_nm", "indstype_cd", "bizcond_cd", "rptr_nm_cd", "compreg_slip_cd",
        "upper_corp_cd", "zip_cd", "addr_cd", "dtl_addr_cd", "vat_sctn_cd", "use_yn_cd"
      ],
      firstEditCol: "corp_cd",
      pkLabels: { corp_cd: "법인코드" },
      onRowDataUpdated: () => {
        this.countryManager?.resetTracking?.()
        this.selectFirstMasterRow()
      }
    }
  }

  configureCountryManager() {
    return this.countryConfig
  }

  isDetailReady() {
    return isApiAlive(this.countryManager?.api)
  }

  addMasterRow() {
    this.addRow({
      manager: this.manager,
      onAdded: (rowData) => {
        this.handleMasterRowChange(rowData)
      }
    })
  }

  deleteMasterRows() {
    this.deleteRows()
  }

  async saveMasterRows() {
    await this.saveRowsWith({
      manager: this.manager,
      batchUrl: this.batchUrlValue,
      saveMessage: this.saveMessage,
      onSuccess: () => this.afterSaveSuccess()
    })
  }

  get batchUrlValue() {
    return this.masterBatchUrlValue
  }

  get saveMessage() {
    return "법인 정보가 저장되었습니다."
  }

  async afterSaveSuccess() {
    if (!isApiAlive(this.manager?.api) || !this.gridController?.urlValue) return
    try {
      const rows = await fetchJson(this.gridController.urlValue)
      setManagerRowData(this.manager, rows)
      this.selectFirstMasterRow()
    } catch {
      // 마스터 재조회 실패 시 무시
    }
  }

  addCountryRow() {
    if (!this.countryManager) return
    if (!this.selectedCorpCode) {
      showAlert("법인을 먼저 선택하세요.")
      return
    }
    if (hasPendingChanges(this.manager)) {
      showAlert("법인 정보를 먼저 저장하세요.")
      return
    }

    this.addRow({
      manager: this.countryManager,
      overrides: { ctry_cd: "KR", use_yn_cd: "Y", rpt_yn_cd: "N" }
    })
  }

  deleteCountryRows() {
    if (!this.countryManager) return
    if (!this.selectedCorpCode) return
    this.deleteRows({ manager: this.countryManager })
  }

  async saveCountryRows() {
    if (!this.countryManager) return
    if (!this.selectedCorpCode) {
      showAlert("법인을 먼저 선택하세요.")
      return
    }
    if (hasPendingChanges(this.manager)) {
      showAlert("법인 정보를 먼저 저장하세요.")
      return
    }

    const batchUrl = buildTemplateUrl(this.countryBatchUrlTemplateValue, ":id", this.selectedCorpCode)
    await this.saveRowsWith({
      manager: this.countryManager,
      batchUrl,
      saveMessage: "법인 국가 정보가 저장되었습니다.",
      onSuccess: () => this.loadCountryRows(this.selectedCorpCode)
    })
  }

  get countryConfig() {
    return {
      pkFields: ["seq"],
      fields: {
        seq: "number",
        ctry_cd: "trimUpper",
        aply_mon_unit_cd: "trimUpper",
        timezone_cd: "trim",
        std_time: "trim",
        summer_time: "trim",
        sys_lang_slc: "trimUpper",
        vat_rt: "number",
        rpt_yn_cd: "trimUpperDefault:N",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        seq: null,
        ctry_cd: "",
        aply_mon_unit_cd: "",
        timezone_cd: "",
        std_time: "",
        summer_time: "",
        sys_lang_slc: "KO",
        vat_rt: null,
        rpt_yn_cd: "N",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["ctry_cd"],
      comparableFields: [
        "ctry_cd", "aply_mon_unit_cd", "timezone_cd", "std_time", "summer_time",
        "sys_lang_slc", "vat_rt", "rpt_yn_cd", "use_yn_cd"
      ],
      firstEditCol: "ctry_cd",
      pkLabels: { seq: "순번" },
      registration: {
        targetName: "countryGrid",
        managerKey: "countryManager"
      },
      onCellValueChanged: (event) => this.handleCountryCellChanged(event)
    }
  }

  async handleMasterRowChange(rowData) {
    if (!this.isDetailReady()) return

    this.selectedCorpCode = rowData?.corp_cd || ""
    this.refreshSelectedCorpLabel()
    this.clearCountryRows()

    const code = rowData?.corp_cd
    const hasLoadableCode = Boolean(code) && !rowData?.__is_deleted && !rowData?.__is_new
    if (!hasLoadableCode) return

    await this.loadCountryRows(code)
  }



  handleCountryCellChanged(event) {
    const field = event?.colDef?.field
    const row = event?.node?.data
    if (!field || !row || !this.countryManager?.api) {
      return
    }

    if (field === "timezone_cd") {
      const { stdTime, summerTime } = this.timezoneMeta(row.timezone_cd)
      row.std_time = stdTime
      row.summer_time = summerTime
      this.countryManager.api.refreshCells({
        rowNodes: [event.node],
        columns: ["std_time", "summer_time"],
        force: true
      })
    }

    if (field === "rpt_yn_cd" && row.rpt_yn_cd === "Y") {
      this.countryManager.api.forEachNode((node) => {
        if (node === event.node || !node.data) {
          return
        }
        if (node.data.rpt_yn_cd === "Y") {
          node.data.rpt_yn_cd = "N"
        }
      })
      this.countryManager.api.refreshCells({
        force: true,
        columns: ["rpt_yn_cd"]
      })
    }
  }

  timezoneMeta(timezoneCode) {
    const normalized = (timezoneCode || "").toString().trim().toUpperCase()
    const map = {
      ASIA_SEOUL: { stdTime: "UTC+09:00", summerTime: "N" },
      ASIA_TOKYO: { stdTime: "UTC+09:00", summerTime: "N" },
      ASIA_SHANGHAI: { stdTime: "UTC+08:00", summerTime: "N" },
      AMERICA_NEW_YORK: { stdTime: "UTC-05:00", summerTime: "Y" }
    }
    return map[normalized] || { stdTime: "", summerTime: "" }
  }

  async loadCountryRows(corpCode) {
    if (!isApiAlive(this.countryManager?.api)) return
    if (!corpCode) {
      this.clearCountryRows()
      return
    }

    try {
      const url = buildTemplateUrl(this.countryListUrlTemplateValue, ":id", corpCode)
      const rows = await fetchJson(url)
      setManagerRowData(this.countryManager, rows)
    } catch {
      showAlert("법인 국가 정보를 불러오지 못했습니다.")
    }
  }

  clearCountryRows() {
    setManagerRowData(this.countryManager, [])
  }

  // 조회 직전 상세 그리드를 비웁니다.
  clearAllDetails() {
    this.clearCountryRows()
  }

  refreshSelectedCorpLabel() {
    if (!this.hasSelectedCorpLabelTarget) return
    refreshSelectionLabel(this.selectedCorpLabelTarget, this.selectedCorpCode, "법인", "법인을 먼저 선택하세요")
  }
}
