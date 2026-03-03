import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["ctry_cd"],
      fields: {
        ctry_cd: "trimUpper",
        ctry_nm: "trim",
        ctry_eng_nm: "trim",
        ctry_ar_cd: "trimUpper",
        ctry_telno: "trim",
        corp_cd: "trimUpper",
        corp_nm: "trim",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        ctry_cd: "",
        ctry_nm: "",
        ctry_eng_nm: "",
        ctry_ar_cd: "ASIA",
        ctry_telno: "",
        corp_cd: "",
        corp_nm: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["ctry_nm"],
      comparableFields: ["ctry_nm", "ctry_eng_nm", "ctry_ar_cd", "ctry_telno", "corp_cd", "corp_nm", "use_yn_cd"],
      firstEditCol: "ctry_cd",
      pkLabels: { ctry_cd: "국가코드" }
    }
  }

  get saveMessage() {
    return "국가코드 데이터가 저장되었습니다."
  }
}
