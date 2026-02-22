import { Controller } from "@hotwired/stimulus"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { fetchJson, hasChanges, isApiAlive, postJson, setManagerRowData } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = ["masterGrid", "countryGrid", "selectedCorpLabel"]

  static values = {
    masterBatchUrl: String,
    countryBatchUrlTemplate: String,
    countryListUrlTemplate: String
  }

  connect() {
    this.masterManager = null
    this.countryManager = null
    this.masterGridController = null
    this.selectedCorpCode = ""
    this.masterRowClickedHandler = (event) => this.handleMasterRowSelection(event)
    this.masterCellFocusedHandler = (event) => this.handleMasterRowSelection(event)
  }

  disconnect() {
    this.unbindMasterEvents()
    this.masterManager?.detach()
    this.countryManager?.detach()
    this.masterManager = null
    this.countryManager = null
    this.masterGridController = null
    this.selectedCorpCode = ""
  }

  registerGrid(event) {
    const { api, controller } = event.detail
    const gridElement = event.target

    if (gridElement === this.masterGridTarget) {
      this.masterGridController = controller
      this.masterManager?.detach()
      this.masterManager = new GridCrudManager(this.masterConfig)
      this.masterManager.attach(api)
      this.bindMasterEvents(api)
    }

    if (gridElement === this.countryGridTarget) {
      this.countryManager?.detach()
      this.countryManager = new GridCrudManager(this.countryConfig)
      this.countryManager.attach(api)
      this.clearCountryRows()
    }

    if (this.masterManager?.api && this.countryManager?.api) {
      this.syncMasterSelection()
    }
  }

  addMasterRow() {
    if (!this.masterManager) return

    const txResult = this.masterManager.addRow()
    const rowNode = txResult?.add?.[0]
    if (!rowNode?.data) return

    this.selectedCorpCode = rowNode.data.corp_cd || ""
    this.refreshSelectedCorpLabel()
    this.clearCountryRows()
  }

  deleteMasterRows() {
    if (!this.masterManager) return
    this.masterManager.deleteRows()
  }

  async saveMasterRows() {
    if (!this.masterManager) return

    this.masterManager.stopEditing()
    const operations = this.masterManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("No changed data.")
      return
    }

    const ok = await postJson(this.masterBatchUrlValue, operations)
    if (!ok) return

    alert("Corporation data saved.")
    await this.reloadMasterRows()
  }

  addCountryRow() {
    if (!this.countryManager) return
    if (!this.selectedCorpCode) {
      alert("Select corporation first.")
      return
    }
    if (this.hasMasterPendingChanges()) {
      alert("Save corporation changes first.")
      return
    }
    this.countryManager.addRow({ ctry_cd: "KR", use_yn_cd: "Y", rpt_yn_cd: "N" })
  }

  deleteCountryRows() {
    if (!this.countryManager) return
    if (!this.selectedCorpCode) return
    this.countryManager.deleteRows()
  }

  async saveCountryRows() {
    if (!this.countryManager) return
    if (!this.selectedCorpCode) {
      alert("Select corporation first.")
      return
    }
    if (this.hasMasterPendingChanges()) {
      alert("Save corporation changes first.")
      return
    }

    this.countryManager.stopEditing()
    const operations = this.countryManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("No changed data.")
      return
    }

    const url = this.countryBatchUrlTemplateValue.replace(":id", encodeURIComponent(this.selectedCorpCode))
    const ok = await postJson(url, operations)
    if (!ok) return

    alert("Corporation country data saved.")
    await this.loadCountryRows(this.selectedCorpCode)
  }

  get masterConfig() {
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
      pkLabels: { corp_cd: "Corporation Code" }
    }
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
      pkLabels: { seq: "Seq" },
      onCellValueChanged: (event) => this.handleCountryCellChanged(event)
    }
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

  bindMasterEvents(api) {
    this.unbindMasterEvents()
    api.addEventListener("rowClicked", this.masterRowClickedHandler)
    api.addEventListener("cellFocused", this.masterCellFocusedHandler)
  }

  unbindMasterEvents() {
    if (!isApiAlive(this.masterManager?.api)) return

    this.masterManager.api.removeEventListener("rowClicked", this.masterRowClickedHandler)
    this.masterManager.api.removeEventListener("cellFocused", this.masterCellFocusedHandler)
  }

  async handleMasterRowSelection(event) {
    if (!isApiAlive(this.masterManager?.api)) return

    let rowData = null
    if (event?.data) {
      rowData = event.data
    } else if (typeof event?.rowIndex === "number" && event.rowIndex >= 0) {
      rowData = this.masterManager.api.getDisplayedRowAtIndex(event.rowIndex)?.data
    }
    if (!rowData) return

    this.selectedCorpCode = rowData.corp_cd || ""
    this.refreshSelectedCorpLabel()

    if (!this.selectedCorpCode || rowData.__is_new || rowData.__is_deleted) {
      this.clearCountryRows()
      return
    }

    await this.loadCountryRows(this.selectedCorpCode)
  }

  async reloadMasterRows() {
    if (!isApiAlive(this.masterManager?.api)) return
    if (!this.masterGridController?.urlValue) return

    try {
      const rows = await fetchJson(this.masterGridController.urlValue)
      setManagerRowData(this.masterManager, rows)
      await this.syncMasterSelection()
    } catch {
      alert("Failed to reload corporation list.")
    }
  }

  async syncMasterSelection() {
    if (!isApiAlive(this.masterManager?.api)) return

    const firstNode = this.masterManager.api.getDisplayedRowAtIndex(0)
    if (!firstNode?.data) {
      this.selectedCorpCode = ""
      this.refreshSelectedCorpLabel()
      this.clearCountryRows()
      return
    }

    const firstCol = this.masterManager.api.getAllDisplayedColumns()?.[0]
    if (firstCol) {
      this.masterManager.api.setFocusedCell(0, firstCol.getColId())
    }

    this.selectedCorpCode = firstNode.data.corp_cd || ""
    this.refreshSelectedCorpLabel()
    if (this.selectedCorpCode && !firstNode.data.__is_new && !firstNode.data.__is_deleted) {
      await this.loadCountryRows(this.selectedCorpCode)
    } else {
      this.clearCountryRows()
    }
  }

  async loadCountryRows(corpCode) {
    if (!isApiAlive(this.countryManager?.api)) return
    if (!corpCode) {
      this.clearCountryRows()
      return
    }

    try {
      const url = this.countryListUrlTemplateValue.replace(":id", encodeURIComponent(corpCode))
      const rows = await fetchJson(url)
      setManagerRowData(this.countryManager, rows)
    } catch {
      alert("Failed to load corporation country rows.")
    }
  }

  clearCountryRows() {
    setManagerRowData(this.countryManager, [])
  }

  hasMasterPendingChanges() {
    if (!this.masterManager) return false
    return hasChanges(this.masterManager.buildOperations())
  }

  refreshSelectedCorpLabel() {
    if (!this.hasSelectedCorpLabelTarget) return
    if (this.selectedCorpCode) {
      this.selectedCorpLabelTarget.textContent = `Selected corporation: ${this.selectedCorpCode}`
    } else {
      this.selectedCorpLabelTarget.textContent = "Select corporation first"
    }
  }
}
