import BaseGridController from "controllers/base_grid_controller"
import { fetchJson, isApiAlive, registerGridInstance } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  connect() {
    super.connect()
    this.lookupMapPromise = null
    this.corpNameByCode = {}
    this.regionNameByCode = {}
    this.rowDataUpdatedHandler = () => {
      this.populateDisplayNames()
    }
  }

  disconnect() {
    const api = this.manager?.api
    if (isApiAlive(api) && this.rowDataUpdatedHandler) {
      api.removeEventListener("rowDataUpdated", this.rowDataUpdatedHandler)
    }
    super.disconnect()
  }

  registerGrid(event) {
    super.registerGrid(event)

    const api = this.manager?.api
    if (!isApiAlive(api)) {
      return
    }

    if (this.rowDataUpdatedHandler) {
      api.removeEventListener("rowDataUpdated", this.rowDataUpdatedHandler)
      api.addEventListener("rowDataUpdated", this.rowDataUpdatedHandler)
    }

    this.populateDisplayNames()
  }

  configureManager() {
    return {
      pkFields: ["regn_cd"],
      fields: {
        corp_cd: "trimUpper",
        regn_cd: "trimUpper",
        regn_nm_cd: "trim",
        regn_eng_nm_cd: "trim",
        upper_regn_cd: "trimUpper",
        rmk_cd: "trim",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        corp_cd: "",
        corp_nm: "",
        regn_cd: "",
        regn_nm_cd: "",
        regn_eng_nm_cd: "",
        upper_regn_cd: "",
        upper_regn_nm: "",
        rmk_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["regn_nm_cd"],
      comparableFields: ["corp_cd", "regn_nm_cd", "regn_eng_nm_cd", "upper_regn_cd", "rmk_cd", "use_yn_cd"],
      firstEditCol: "regn_cd",
      pkLabels: { regn_cd: "권역코드" }
    }
  }

  async ensureLookupMaps() {
    if (this.lookupMapPromise) {
      await this.lookupMapPromise
      return
    }

    this.lookupMapPromise = (async () => {
      try {
        const corpRows = await fetchJson("/search_popups/corp.json")
        this.corpNameByCode = this.buildCodeNameMap(corpRows)
      } catch {
        this.corpNameByCode = {}
      }

      try {
        const regionRows = await fetchJson("/search_popups/region.json")
        this.regionNameByCode = this.buildCodeNameMap(regionRows)
      } catch {
        this.regionNameByCode = {}
      }
    })()

    await this.lookupMapPromise
  }

  buildCodeNameMap(rows) {
    const map = {}
    if (Array.isArray(rows)) {
      rows.forEach((row) => {
        const code = (row?.code || "").toString().trim().toUpperCase()
        const name = (row?.name || "").toString().trim()
        if (code && name) {
          map[code] = name
        }
      })
    }
    return map
  }

  async populateDisplayNames() {
    const api = this.manager?.api
    if (!isApiAlive(api)) {
      return
    }

    await this.ensureLookupMaps()

    const rowNodes = []
    api.forEachNode((node) => {
      const row = node?.data
      if (!row) {
        return
      }

      let changed = false

      const corpCd = (row.corp_cd || "").toString().trim().toUpperCase()
      if (corpCd && !row.corp_nm) {
        const corpNm = this.corpNameByCode[corpCd]
        if (corpNm) {
          row.corp_nm = corpNm
          changed = true
        }
      }

      const upperRegnCd = (row.upper_regn_cd || "").toString().trim().toUpperCase()
      if (upperRegnCd && !row.upper_regn_nm) {
        const upperRegnNm = this.regionNameByCode[upperRegnCd]
        if (upperRegnNm) {
          row.upper_regn_nm = upperRegnNm
          changed = true
        }
      }

      if (changed) {
        rowNodes.push(node)
      }
    })

    if (rowNodes.length > 0) {
      api.refreshCells({
        rowNodes,
        columns: ["corp_nm", "upper_regn_nm"],
        force: true
      })
    }
  }

  get saveMessage() {
    return "권역 데이터가 저장되었습니다."
  }
}
