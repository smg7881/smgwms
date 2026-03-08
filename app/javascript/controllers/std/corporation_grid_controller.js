import BaseGridController from "controllers/base_grid_controller"
import { refreshGridCells } from "controllers/grid/grid_api_utils"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "countryGrid", "selectedCorpLabel"]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    countryBatchUrlTemplate: String,
    countryListUrlTemplate: String
  }

  connect() {
    super.connect()
    this.refreshSelectedLabel()
  }

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "법인 정보가 저장되었습니다.",
      pendingEntityLabel: "법인 정보",
      key: {
        field: "corp_cd",
        stateProperty: "selectedCorpCode",
        labelTarget: "selectedCorpLabel",
        entityLabel: "법인",
        emptyMessage: "법인을 먼저 선택하세요"
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
        role: "country",
        masterKeyField: "corp_cd",
        placeholder: ":id",
        listUrlTemplate: "countryListUrlTemplateValue",
        batchUrlTemplate: "countryBatchUrlTemplateValue",
        entityLabel: "법인",
        selectionMessage: "법인을 먼저 선택하세요.",
        saveMessage: "법인 국가 정보가 저장되었습니다.",
        fetchErrorMessage: "법인 국가 정보를 불러오지 못했습니다.",
        overrides: { ctry_cd: "KR", use_yn_cd: "Y", rpt_yn_cd: "N" },
        onSaveSuccess: () => this.reloadCountryRows(this.selectedCorpCode)
      }
    ]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: "configureManager",
        masterKeyField: "corp_cd"
      },
      country: {
        target: "countryGrid",
        manager: "configureCountryManager",
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("country", rowData)
      }
    }
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
      refreshGridCells(this.countryManager.api, {
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
      refreshGridCells(this.countryManager.api, {
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
}
