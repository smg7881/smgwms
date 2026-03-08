import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { refreshSelectionLabel } from "controllers/grid/grid_utils"
import { fetchJson } from "controllers/grid/core/http_client"
import { buildChainConfig, bindDependentSelects, unbindDependentSelects } from "controllers/grid/grid_dependent_select_utils"

const YES_NO_VALUES = ["Y", "N"]

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "areaGrid", "zoneGrid", "selectedAreaLabel"]

  static values = {
    ...BaseGridController.values,
    areasUrl: String,
    zonesUrl: String,
    selectedWorkplCd: String,
    selectedAreaCd: String,
    selectedAreaNm: String
  }

  connect() {
    super.connect()
    this.refreshSelectedLabel()
    this.bindSearchFields()
  }

  disconnect() {
    this.unbindSearchFields()
    super.disconnect()
  }

  bindSearchFields() {
    if (!this.hasAreasUrlValue) return
    bindDependentSelects(this, buildChainConfig(this.#dependentSelectChain()))
  }

  unbindSearchFields() {
    unbindDependentSelects(this)
  }

  #dependentSelectChain() {
    return [
      {
        field: "workpl_cd",
        childField: "area_cd",
        url: this.areasUrlValue,
        params: (vals) => ({ workpl_cd: vals.workpl_cd }),
        valueField: "area_cd",
        labelFields: ["area_cd", "area_nm"],
        errorMessage: "구역 목록 조회에 실패했습니다.",
      }
    ]
  }

  masterConfig() {
    return {
      role: "area",
      pendingEntityLabel: "구역",
      key: {
        field: "area_cd",
        stateProperty: "selectedAreaCdValue",
        labelTarget: "selectedAreaLabel",
        entityLabel: "구역",
        emptyMessage: "구역을 먼저 선택해주세요."
      },
      onRowChange: {
        trackCurrentRow: false,
        syncForm: false,
        afterChange: (rowData) => {
          this.selectedWorkplCdValue = rowData?.workpl_cd || ""
          this.selectedAreaNmValue = rowData?.area_nm || ""
          this.refreshSelectedLabel()
        }
      },
      beforeSearch: {
        clearValidation: false,
        clearForm: false
      }
    }
  }

  detailGrids() {
    return [{
      role: "zone",
      methodBaseName: "zone",
      masterKeyField: "area_cd",
      batchUrlTemplate: "batchUrlValue",
      entityLabel: "구역",
      selectionMessage: "좌측 목록에서 구역을 먼저 선택해주세요.",
      saveMessage: "보관 Zone 데이터가 저장되었습니다.",
      overrides: ({ selectedValue }) => ({
        workpl_cd: this.selectedWorkplCdValue,
        area_cd: selectedValue
      }),
      onSaveSuccess: () => this.refreshGrid("area")
    }]
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
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
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

  beforeSearchReset() {
    this.selectedWorkplCdValue = ""
    this.selectedAreaCdValue = ""
    this.selectedAreaNmValue = ""
    this.refreshSelectedLabel()
    this.clearZoneRows?.()
  }

  refreshSelectedLabel() {
    this.refreshSelectedAreaLabel()
  }

  refreshSelectedAreaLabel() {
    if (!this.hasSelectedAreaLabelTarget) return

    const hasAreaCode = Boolean(this.selectedAreaCdValue)
    const areaName = this.selectedAreaNmValue || ""
    const value = hasAreaCode ? `${this.selectedAreaCdValue} / ${areaName}` : ""

    refreshSelectionLabel(this.selectedAreaLabelTarget, value, "구역", "구역을 먼저 선택해주세요")
  }

  zoneKeywordFromSearch() {
    return this.getSearchFormValue("zone_cd", { toUpperCase: false })
  }

  useYnFromSearch() {
    return this.getSearchFormValue("use_yn")
  }
}
