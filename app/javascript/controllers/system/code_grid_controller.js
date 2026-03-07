import BaseGridController from "controllers/base_grid_controller"

const YES_NO_VALUES = ["Y", "N"]

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedCodeLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedCode: String
  }

  connect() {
    super.connect()
    this.refreshSelectedLabel()
  }

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "코드 데이터가 저장되었습니다.",
      pendingEntityLabel: "마스터 코드",
      key: {
        field: "code",
        stateProperty: "selectedCodeValue",
        labelTarget: "selectedCodeLabel",
        entityLabel: "코드",
        emptyMessage: "코드를 먼저 선택해주세요."
      },
      onRowChange: {
        trackCurrentRow: false,
        syncForm: false
      },
      beforeSearch: {
        clearValidation: false,
        clearForm: false
      },
      onAdded: (rowData) => {
        this.selectedCodeValue = rowData?.code || ""
        this.refreshSelectedLabel()
        this.clearDetailRows?.()
      }
    }
  }

  detailGrids() {
    return [{
      role: "detail",
      masterKeyField: "code",
      placeholder: ":code",
      listUrlTemplate: "detailListUrlTemplateValue",
      batchUrlTemplate: "detailBatchUrlTemplateValue",
      entityLabel: "코드",
      selectionMessage: "코드를 먼저 선택해주세요.",
      saveMessage: "상세코드 데이터가 저장되었습니다.",
      fetchErrorMessage: "상세코드 목록 조회에 실패했습니다.",
      overrides: ({ selectedValue }) => ({ code: selectedValue }),
      onSaveSuccess: () => this.refreshGrid("master")
    }]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "code"
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("detail", rowData)
      }
    }
  }

  masterManagerConfig() {
    return {
      pkFields: ["code"],
      fields: {
        code: "trim",
        code_name: "trim",
        sys_sctn_cd: "trimUpper",
        rmk: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        code: "",
        code_name: "",
        sys_sctn_cd: "",
        rmk: "",
        use_yn: "Y"
      },
      blankCheckFields: ["code", "code_name"],
      validationRules: {
        requiredFields: ["code", "code_name", "sys_sctn_cd", "use_yn"],
        fieldLabels: {
          code: "코드",
          code_name: "코드명",
          sys_sctn_cd: "시스템구분",
          use_yn: "사용여부"
        },
        fieldRules: {
          use_yn: [{ type: "enum", values: YES_NO_VALUES }]
        }
      },
      comparableFields: [
        "code_name",
        "sys_sctn_cd",
        "rmk",
        "use_yn"
      ],
      firstEditCol: "code",
      pkLabels: { code: "코드" }
    }
  }

  detailManagerConfig() {
    return {
      pkFields: ["detail_code"],
      fields: {
        detail_code: "trim",
        detail_code_name: "trim",
        short_name: "trim",
        upper_code: "trimUpper",
        upper_detail_code: "trimUpper",
        rmk: "trim",
        attr1: "trim",
        attr2: "trim",
        attr3: "trim",
        attr4: "trim",
        attr5: "trim",
        sort_order: "number",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        code: "",
        detail_code: "",
        detail_code_name: "",
        short_name: "",
        upper_code: "",
        upper_detail_code: "",
        rmk: "",
        attr1: "",
        attr2: "",
        attr3: "",
        attr4: "",
        attr5: "",
        sort_order: 0,
        use_yn: "Y"
      },
      blankCheckFields: ["detail_code", "detail_code_name"],
      validationRules: {
        requiredFields: ["detail_code", "detail_code_name", "sort_order", "use_yn"],
        fieldLabels: {
          detail_code: "상세코드",
          detail_code_name: "상세코드명",
          sort_order: "정렬순서",
          use_yn: "사용여부"
        },
        fieldRules: {
          use_yn: [{ type: "enum", values: YES_NO_VALUES }]
        }
      },
      comparableFields: [
        "detail_code_name",
        "short_name",
        "upper_code",
        "upper_detail_code",
        "rmk",
        "attr1",
        "attr2",
        "attr3",
        "attr4",
        "attr5",
        "sort_order",
        "use_yn"
      ],
      firstEditCol: "detail_code",
      pkLabels: { detail_code: "상세코드" }
    }
  }
}
