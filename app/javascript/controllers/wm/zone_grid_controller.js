import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { fetchJson, setManagerRowData, refreshSelectionLabel } from "controllers/grid/grid_utils"

const YES_NO_VALUES = ["Y", "N"]

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "areaGrid", "zoneGrid", "selectedAreaLabel"]

  static values = {
    ...BaseGridController.values,
    zonesUrl: String,
    selectedWorkplCd: String,
    selectedAreaCd: String,
    selectedAreaNm: String
  }

  connect() {
    super.connect()
    this.refreshSelectedAreaLabel()
  }

  gridRoles() {
    return {
      area: {
        target: "areaGrid",
        masterKeyField: "id"
      },
      zone: {
        target: "zoneGrid",
        manager: this.zoneManagerConfig(),
        parentGrid: "area",
        onMasterRowChange: (rowData) => {
          this.selectedWorkplCdValue = rowData?.workpl_cd || ""
          this.selectedAreaCdValue = rowData?.area_cd || ""
          this.selectedAreaNmValue = rowData?.area_nm || ""
          this.refreshSelectedAreaLabel()
          this.clearZoneRows()
        },
        detailLoader: async (rowData) => {
          const workplCd = rowData?.workpl_cd
          const areaCd = rowData?.area_cd
          const hasLoadableKey = Boolean(workplCd) && Boolean(areaCd) && !rowData?.__is_deleted && !rowData?.__is_new
          if (!hasLoadableKey) return []

          const query = new URLSearchParams({
            workpl_cd: workplCd,
            area_cd: areaCd
          })

          const zoneKeyword = this.zoneKeywordFromSearch()
          if (zoneKeyword) query.set("zone_cd", zoneKeyword)

          const useYn = this.useYnFromSearch()
          if (useYn) query.set("use_yn", useYn)

          try {
            const rows = await fetchJson(`${this.zonesUrlValue}?${query.toString()}`)
            return Array.isArray(rows) ? rows : []
          } catch {
            showAlert("보관 Zone 조회에 실패했습니다.")
            return []
          }
        }
      }
    }
  }

  zoneManagerConfig() {
    return {
      pkFields: ["workpl_cd", "area_cd", "zone_cd"],
      fields: {
        workpl_cd: "trimUpper",
        area_cd: "trimUpper",
        zone_cd: "trimUpper",
        zone_nm: "trim",
        zone_desc: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        workpl_cd: "",
        area_cd: "",
        zone_cd: "",
        zone_nm: "",
        zone_desc: "",
        use_yn: "Y"
      },
      blankCheckFields: ["zone_cd", "zone_nm"],
      validationRules: {
        requiredFields: ["zone_cd", "zone_nm", "use_yn"],
        fieldLabels: {
          zone_cd: "Zone 코드",
          zone_nm: "Zone 명",
          use_yn: "사용여부"
        },
        fieldRules: {
          use_yn: [{ type: "enum", values: YES_NO_VALUES }]
        }
      },
      comparableFields: ["zone_nm", "zone_desc", "use_yn"],
      firstEditCol: "zone_cd",
      pkLabels: { zone_cd: "Zone 코드" }
    }
  }

  get zoneManager() {
    return this.gridManager("zone")
  }

  beforeSearchReset() {
    this.selectedWorkplCdValue = ""
    this.selectedAreaCdValue = ""
    this.selectedAreaNmValue = ""
    this.refreshSelectedAreaLabel()
  }

  addZoneRow() {
    if (!this.zoneManager) return
    if (!this.hasSelectedArea()) {
      showAlert("좌측 목록에서 구역을 먼저 선택해주세요.")
      return
    }

    this.addRow({
      manager: this.zoneManager,
      overrides: {
        workpl_cd: this.selectedWorkplCdValue,
        area_cd: this.selectedAreaCdValue
      }
    })
  }

  deleteZoneRows() {
    if (!this.zoneManager) return
    if (!this.hasSelectedArea()) {
      showAlert("좌측 목록에서 구역을 먼저 선택해주세요.")
      return
    }

    this.deleteRows({ manager: this.zoneManager })
  }

  async saveZoneRows() {
    if (!this.zoneManager) return
    if (!this.hasSelectedArea()) {
      showAlert("좌측 목록에서 구역을 먼저 선택해주세요.")
      return
    }

    await this.saveRowsWith({
      manager: this.zoneManager,
      batchUrl: this.batchUrlValue,
      saveMessage: "보관 Zone 데이터가 저장되었습니다.",
      onSuccess: () => this.refreshGrid("area")
    })
  }

  clearZoneRows() {
    setManagerRowData(this.zoneManager, [])
  }

  refreshSelectedAreaLabel() {
    if (!this.hasSelectedAreaLabelTarget) return

    const hasAreaCode = Boolean(this.selectedAreaCdValue)
    const areaName = this.selectedAreaNmValue || ""
    const value = hasAreaCode ? `${this.selectedAreaCdValue} / ${areaName}` : ""

    refreshSelectionLabel(this.selectedAreaLabelTarget, value, "구역", "구역을 먼저 선택해주세요")
  }

  hasSelectedArea() {
    return Boolean(this.selectedWorkplCdValue && this.selectedAreaCdValue)
  }

  zoneKeywordFromSearch() {
    return this.getSearchFormValue("zone_cd", { toUpperCase: false })
  }

  useYnFromSearch() {
    return this.getSearchFormValue("use_yn")
  }
}
