/**
 * role_grid_controller.js
 *
 * BaseGridController를 상속받아 역할(Role) 마스터 단일 그리드 CRUD 규칙을 정의합니다.
 */
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
    return "역할 데이터가 저장되었습니다."
  }
}
