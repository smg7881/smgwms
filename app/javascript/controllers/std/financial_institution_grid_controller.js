import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["fnc_or_cd"],
      fields: {
        fnc_or_cd: "trimUpper",
        fnc_or_nm: "trim",
        fnc_or_eng_nm: "trim",
        ctry_cd: "trimUpper",
        ctry_nm: "trim",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        fnc_or_cd: "",
        fnc_or_nm: "",
        fnc_or_eng_nm: "",
        ctry_cd: "",
        ctry_nm: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["fnc_or_cd", "fnc_or_nm"],
      comparableFields: ["fnc_or_nm", "fnc_or_eng_nm", "ctry_cd", "ctry_nm", "use_yn_cd"],
      firstEditCol: "fnc_or_cd",
      pkLabels: { fnc_or_cd: "금융기관코드" }
    }
  }

  get saveMessage() {
    return "금융기관 정보가 저장되었습니다."
  }
}
