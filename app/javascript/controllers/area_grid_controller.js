import BaseGridController from "controllers/base_grid_controller"

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
      defaultRow: { workpl_cd: "", workpl_nm: "", area_cd: "", area_nm: "", area_desc: "", use_yn: "Y" },
      blankCheckFields: ["workpl_cd", "area_cd", "area_nm"],
      comparableFields: ["area_nm", "area_desc", "use_yn"],
      firstEditCol: "area_cd",
      pkLabels: { workpl_cd: "작업장코드", area_cd: "AREA코드" },
      onCellValueChanged: (event) => this.syncWorkplaceName(event)
    }
  }

  addRow() {
    if (!this.manager) return

    const workplCd = this.selectedWorkplaceCodeFromSearch()
    const startCol = workplCd ? "area_cd" : "workpl_cd"

    this.manager.addRow(
      { workpl_cd: workplCd, workpl_nm: this.resolveWorkplaceName(workplCd) },
      { startCol }
    )
  }

  syncWorkplaceName(event) {
    if (event?.colDef?.field !== "workpl_cd") return
    if (!event?.node?.data) return

    const row = event.node.data
    row.workpl_cd = (row.workpl_cd || "").trim().toUpperCase()
    row.workpl_nm = this.resolveWorkplaceName(row.workpl_cd)

    if (row.__is_new && row.workpl_cd && !row.workpl_nm) {
      row.workpl_cd = ""
      row.workpl_nm = ""
      alert("유효한 작업장코드를 선택하세요.")
    }

    this.manager.api.refreshCells({
      rowNodes: [event.node],
      columns: ["workpl_cd", "workpl_nm"],
      force: true
    })
  }

  resolveWorkplaceName(workplCd) {
    if (!workplCd) return ""
    return this.workplaceNameMap[workplCd] || ""
  }

  selectedWorkplaceCodeFromSearch() {
    const field = this.element.querySelector("[name='q[workpl_cd]']")
    if (!field) return ""
    return (field.value || "").trim().toUpperCase()
  }

  get saveMessage() {
    return "구역 데이터가 저장되었습니다."
  }
}
