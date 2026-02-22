import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
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
        regn_cd: "",
        regn_nm_cd: "",
        regn_eng_nm_cd: "",
        upper_regn_cd: "",
        rmk_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["regn_nm_cd"],
      comparableFields: ["corp_cd", "regn_nm_cd", "regn_eng_nm_cd", "upper_regn_cd", "rmk_cd", "use_yn_cd"],
      firstEditCol: "regn_cd",
      pkLabels: { regn_cd: "권역코드" }
    }
  }

  get saveMessage() {
    return "권역 데이터가 저장되었습니다."
  }
}
