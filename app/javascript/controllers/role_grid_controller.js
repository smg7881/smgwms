import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["role_cd"],
      fields: {
        role_cd: "trim",
        role_nm: "trim",
        description: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: { role_cd: "", role_nm: "", description: "", use_yn: "Y" },
      blankCheckFields: ["role_cd", "role_nm"],
      comparableFields: ["role_nm", "description", "use_yn"],
      firstEditCol: "role_cd",
      pkLabels: { role_cd: "역할코드" }
    }
  }

  get saveMessage() {
    return "역할 저장이 완료되었습니다."
  }
}
