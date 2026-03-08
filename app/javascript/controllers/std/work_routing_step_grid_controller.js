import BaseGridController from "controllers/base_grid_controller"
import { refreshGridCells } from "controllers/grid/grid_api_utils"

const YES_NO_VALUES = ["Y", "N"]

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedWorkRoutingLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedWorkRouting: String,
    workType1Map: Object,
    workType2Map: Object,
    workStepLevel2Map: Object
  }

  connect() {
    super.connect()
    this.refreshSelectedLabel()
  }

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "기준작업경로 정보가 저장되었습니다.",
      pendingEntityLabel: "마스터 작업경로",
      key: {
        field: "wrk_rt_cd",
        stateProperty: "selectedWorkRoutingValue",
        labelTarget: "selectedWorkRoutingLabel",
        entityLabel: "작업경로",
        emptyMessage: "작업경로를 먼저 선택해주세요."
      },
      onRowChange: {
        trackCurrentRow: false,
        syncForm: false
      },
      onSaveSuccess: () => this.refreshGrid("master"),
      onAdded: (rowData) => this.onMasterRowChanged(rowData)
    }
  }

  detailGrids() {
    return [
      {
        role: "detail",
        masterKeyField: "wrk_rt_cd",
        placeholder: ":id",
        listUrlTemplate: "detailListUrlTemplateValue",
        batchUrlTemplate: "detailBatchUrlTemplateValue",
        entityLabel: "작업경로",
        selectionMessage: "작업경로를 먼저 선택해주세요.",
        saveMessage: "작업경로별 작업단계 정보가 저장되었습니다.",
        fetchErrorMessage: "작업경로별 작업단계 목록 조회에 실패했습니다.",
        overrides: ({ selectedValue }) => ({ wrk_rt_cd: selectedValue }),
        onSaveSuccess: () => this.refreshGrid("master")
      }
    ]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: "masterManagerConfig",
        masterKeyField: "wrk_rt_cd"
      },
      detail: {
        target: "detailGrid",
        manager: "detailManagerConfig",
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("detail", rowData)
      }
    }
  }

  masterManagerConfig() {
    return {
      pkFields: ["wrk_rt_cd"],
      fields: {
        wrk_rt_cd: "trimUpper",
        wrk_rt_nm: "trim",
        hwajong_cd: "trimUpper",
        wrk_type1_cd: "trimUpper",
        wrk_type2_cd: "trimUpper",
        use_yn_cd: "trimUpperDefault:Y",
        rmk_cd: "trim"
      },
      defaultRow: {
        wrk_rt_cd: "",
        wrk_rt_nm: "",
        hwajong_cd: "",
        wrk_type1_cd: "",
        wrk_type2_cd: "",
        use_yn_cd: "Y",
        rmk_cd: ""
      },
      blankCheckFields: ["wrk_rt_cd", "wrk_rt_nm"],
      validationRules: {
        requiredFields: ["wrk_rt_cd", "wrk_rt_nm", "hwajong_cd", "wrk_type1_cd", "wrk_type2_cd", "use_yn_cd"],
        fieldLabels: {
          wrk_rt_cd: "작업경로코드",
          wrk_rt_nm: "작업경로명",
          hwajong_cd: "화종",
          wrk_type1_cd: "작업유형1",
          wrk_type2_cd: "작업유형2",
          use_yn_cd: "사용여부"
        },
        fieldRules: {
          use_yn_cd: [{ type: "enum", values: YES_NO_VALUES }]
        },
        rowRules: [
          {
            code: "wrk_type1_dependency",
            field: "wrk_type1_cd",
            message: "작업유형1은 선택된 화종에 매핑된 코드만 선택할 수 있습니다.",
            validate: ({ normalizedRow }) => this.validChildCode(this.workType1MapValue, normalizedRow.hwajong_cd, normalizedRow.wrk_type1_cd)
          },
          {
            code: "wrk_type2_dependency",
            field: "wrk_type2_cd",
            message: "작업유형2는 선택된 작업유형1에 매핑된 코드만 선택할 수 있습니다.",
            validate: ({ normalizedRow }) => this.validChildCode(this.workType2MapValue, normalizedRow.wrk_type1_cd, normalizedRow.wrk_type2_cd)
          }
        ]
      },
      comparableFields: ["wrk_rt_nm", "hwajong_cd", "wrk_type1_cd", "wrk_type2_cd", "use_yn_cd", "rmk_cd"],
      firstEditCol: "wrk_rt_cd",
      pkLabels: { wrk_rt_cd: "작업경로코드" },
      onCellValueChanged: (event) => this.handleMasterCellValueChanged(event)
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["seq_no"],
      fields: {
        wrk_rt_cd: "trimUpper",
        seq_no: "number",
        work_step_cd: "trimUpper",
        work_step_level1_cd: "trimUpper",
        work_step_level2_cd: "trimUpper",
        use_yn_cd: "trimUpperDefault:Y",
        rmk_cd: "trim"
      },
      defaultRow: {
        wrk_rt_cd: "",
        seq_no: null,
        work_step_cd: "",
        work_step_nm: "",
        work_step_level1_cd: "",
        work_step_level2_cd: "",
        use_yn_cd: "Y",
        rmk_cd: ""
      },
      blankCheckFields: ["work_step_cd", "work_step_level1_cd", "work_step_level2_cd"],
      validationRules: {
        requiredFields: ["work_step_cd", "work_step_level1_cd", "work_step_level2_cd", "use_yn_cd"],
        fieldLabels: {
          work_step_cd: "작업단계코드",
          work_step_level1_cd: "작업단계Level1",
          work_step_level2_cd: "작업단계Level2",
          use_yn_cd: "사용여부"
        },
        fieldRules: {
          use_yn_cd: [{ type: "enum", values: YES_NO_VALUES }]
        },
        rowRules: [
          {
            code: "work_step_level2_dependency",
            field: "work_step_level2_cd",
            message: "작업단계Level2는 선택된 작업단계Level1에 매핑된 코드만 선택할 수 있습니다.",
            validate: ({ normalizedRow }) => this.validChildCode(this.workStepLevel2MapValue, normalizedRow.work_step_level1_cd, normalizedRow.work_step_level2_cd)
          }
        ]
      },
      comparableFields: ["work_step_cd", "work_step_level1_cd", "work_step_level2_cd", "use_yn_cd", "rmk_cd"],
      firstEditCol: "work_step_cd",
      pkLabels: { seq_no: "순서" },
      onCellValueChanged: (event) => this.handleDetailCellValueChanged(event)
    }
  }

  handleLookupSelected(event) {
    const rowNode = event?.detail?.rowNode
    const colDef = event?.detail?.colDef
    const selection = event?.detail?.selection || {}
    if (!rowNode || !colDef) {
      return
    }

    const popupType = colDef?.context?.lookup_popup_type
    const field = colDef?.field
    const codeField = colDef?.context?.lookup_code_field || field
    if (popupType !== "work_step" || (codeField !== "work_step_cd" && field !== "work_step_cd")) {
      return
    }

    const selectedWorkStepNm = String(
      selection.work_step_nm ?? selection.name ?? selection.display ?? ""
    ).trim()
    const selectedLevel1Code = String(
      selection.work_step_level1_cd ?? selection.workStepLevel1Cd ?? ""
    ).trim().toUpperCase()
    const selectedLevel2Code = String(
      selection.work_step_level2_cd ?? selection.workStepLevel2Cd ?? ""
    ).trim().toUpperCase()

    rowNode.setDataValue("work_step_nm", selectedWorkStepNm)
    rowNode.setDataValue("work_step_level1_cd", selectedLevel1Code)
    rowNode.setDataValue("work_step_level2_cd", selectedLevel2Code)

    refreshGridCells(this.detailManager?.api, {
      rowNodes: [rowNode],
      columns: ["work_step_cd", "work_step_level1_cd", "work_step_level2_cd"],
      force: true
    })
  }

  handleMasterCellValueChanged(event) {
    const field = event?.colDef?.field
    const row = event?.node?.data
    if (!field || !row || !this.masterManager?.api) {
      return
    }

    if (field === "hwajong_cd") {
      if (!this.validChildCode(this.workType1MapValue, row.hwajong_cd, row.wrk_type1_cd)) {
        row.wrk_type1_cd = ""
      }
      if (!this.validChildCode(this.workType2MapValue, row.wrk_type1_cd, row.wrk_type2_cd)) {
        row.wrk_type2_cd = ""
      }
      refreshGridCells(this.masterManager.api, {
        rowNodes: [event.node],
        columns: ["wrk_type1_cd", "wrk_type2_cd"],
        force: true
      })
      return
    }

    if (field === "wrk_type1_cd") {
      if (!this.validChildCode(this.workType2MapValue, row.wrk_type1_cd, row.wrk_type2_cd)) {
        row.wrk_type2_cd = ""
      }
      refreshGridCells(this.masterManager.api, {
        rowNodes: [event.node],
        columns: ["wrk_type2_cd"],
        force: true
      })
    }
  }

  handleDetailCellValueChanged(event) {
    const field = event?.colDef?.field
    const row = event?.node?.data
    if (!field || !row || !this.detailManager?.api) {
      return
    }

    if (field === "work_step_level1_cd") {
      if (!this.validChildCode(this.workStepLevel2MapValue, row.work_step_level1_cd, row.work_step_level2_cd)) {
        row.work_step_level2_cd = ""
      }
      refreshGridCells(this.detailManager.api, {
        rowNodes: [event.node],
        columns: ["work_step_level2_cd"],
        force: true
      })
    }
  }

  validChildCode(codeMap, parentCode, childCode) {
    const parent = (parentCode || "").toString().trim().toUpperCase()
    const child = (childCode || "").toString().trim().toUpperCase()
    if (!parent || !child) return true

    const rawMap = codeMap || {}
    const allowed = rawMap[parent]
    if (!Array.isArray(allowed) || allowed.length === 0) return true

    return allowed.includes(child)
  }
}
