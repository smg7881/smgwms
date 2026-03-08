import BaseGridController from "controllers/base_grid_controller"
import { showAlert } from "components/ui/alert"
import { resolveNameFromMap } from "controllers/grid/grid_utils"
import { refreshGridCells } from "controllers/grid/grid_api_utils"

export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    workplaceMap: Object
  }

  connect() {
    super.connect()
    this.workplaceNameMap = this.hasWorkplaceMapValue ? this.workplaceMapValue : {}
  }

  configureManager() {
    return {
      pkFields: ["workpl_cd", "area_cd"],
      fields: {
        workpl_cd: "trimUpper",
        area_cd: "trimUpper",
        area_nm: "trim",
        area_desc: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        area_cd: "",
        area_nm: "",
        area_desc: "",
        use_yn: "Y"
      },
      blankCheckFields: ["workpl_cd", "area_cd", "area_nm"],
      comparableFields: ["area_nm", "area_desc", "use_yn"],
      firstEditCol: "area_cd",
      pkLabels: { workpl_cd: "작업장코드", area_cd: "AREA코드" },
      onCellValueChanged: (event) => this.syncWorkplaceName(event)
    }
  }

  addRow(event) {
    if (event) event.preventDefault()

    const workplCd = this.getSearchFormValue("workpl_cd")
    const rowOverrides = {
      workpl_cd: workplCd,
      workpl_nm: this.resolveWorkplaceName(workplCd)
    }

    super.addRow({ overrides: rowOverrides })
  }

  syncWorkplaceName(event) {
    if (event?.colDef?.field !== "workpl_cd") return
    if (!event?.node?.data) return

    const row = event.node.data
    row.workpl_nm = this.resolveWorkplaceName(row.workpl_cd)

    if (row.__is_new && row.workpl_cd && !row.workpl_nm) {
      row.workpl_cd = ""
      row.workpl_nm = ""
      showAlert("유효한 작업장코드를 선택해주세요.")
    }

    refreshGridCells(this.manager.api, {
      rowNodes: [event.node],
      columns: ["workpl_cd", "workpl_nm"],
      force: true
    })
  }

  resolveWorkplaceName(workplCd) {
    return resolveNameFromMap(this.workplaceNameMap, workplCd)
  }

  get saveMessage() {
    return "구역 데이터가 저장되었습니다."
  }
}
