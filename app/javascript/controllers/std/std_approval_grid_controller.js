import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["corp_cd", "menu_cd"],
      fields: {
        corp_cd: "trimUpper",
        corp_nm: "trim",
        menu_cd: "trimUpper",
        menu_nm: "trim",
        table_cd: "trimUpper",
        col1_cd: "trimUpper",
        col2_cd: "trimUpper",
        col3_cd: "trimUpper",
        col4_cd: "trimUpper",
        col5_cd: "trimUpper",
        asmt_apver_yn: "trimUpperDefault:Y",
        chrg_apver: "trimUpper",
        not_asmt_apver_resp: "trimUpper",
        apv_type_cd: "trimUpper",
        apv_delegt_yn: "trimUpperDefault:N",
        apv_delegate: "trimUpper",
        rmk: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        corp_cd: "",
        corp_nm: "",
        menu_cd: "",
        menu_nm: "",
        table_cd: "",
        col1_cd: "",
        col2_cd: "",
        col3_cd: "",
        col4_cd: "",
        col5_cd: "",
        asmt_apver_yn: "Y",
        chrg_apver: "",
        not_asmt_apver_resp: "",
        apv_type_cd: "CODE",
        apv_delegt_yn: "N",
        apv_delegate: "",
        rmk: "",
        use_yn: "Y"
      },
      blankCheckFields: ["menu_nm"],
      comparableFields: [
        "corp_nm", "menu_nm", "table_cd", "col1_cd", "col2_cd", "col3_cd", "col4_cd", "col5_cd",
        "asmt_apver_yn", "chrg_apver", "not_asmt_apver_resp", "apv_type_cd", "apv_delegt_yn",
        "apv_delegate", "rmk", "use_yn"
      ],
      firstEditCol: "corp_cd",
      pkLabels: { corp_cd: "법인코드", menu_cd: "메뉴코드" }
    }
  }

  get saveMessage() {
    return "결재관리 데이터가 저장되었습니다."
  }
}
