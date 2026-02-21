import BaseGridController from "controllers/base_grid_controller"

// BaseGridController override: 작업장(workplace) 단일 그리드 CRUD 설정만 제공합니다.

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["workpl_cd"],
      fields: {
        workpl_cd: "trimUpper",
        workpl_nm: "trim",
        workpl_type: "trimUpper",
        nation_cd: "trimUpper",
        zip_cd: "trim",
        addr: "trim",
        addr_dtl: "trim",
        tel_no: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        workpl_cd: "", workpl_nm: "", workpl_type: "", nation_cd: "",
        zip_cd: "", addr: "", addr_dtl: "", tel_no: "", use_yn: "Y"
      },
      blankCheckFields: ["workpl_cd", "workpl_nm"],
      comparableFields: ["workpl_nm", "workpl_type", "nation_cd", "zip_cd", "addr", "addr_dtl", "tel_no", "use_yn"],
      firstEditCol: "workpl_cd",
      pkLabels: { workpl_cd: "작업장코드" }
    }
  }

  get saveMessage() {
    return "작업장 데이터가 저장되었습니다."
  }
}

