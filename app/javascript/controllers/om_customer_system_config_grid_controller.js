import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["setup_unit_cd", "cust_cd", "lclas_cd", "mclas_cd", "sclas_cd", "setup_sctn_cd"],
      fields: {
        setup_unit_cd: "trimUpperDefault:SYSTEM",
        cust_cd: "trimUpper",
        lclas_cd: "trimUpper",
        mclas_cd: "trimUpper",
        sclas_cd: "trimUpper",
        setup_sctn_cd: "trimUpper",
        module_nm: "trim",
        setup_value: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        setup_unit_cd: "SYSTEM",
        cust_cd: "",
        lclas_cd: "",
        mclas_cd: "",
        sclas_cd: "",
        setup_sctn_cd: "VALIDATE",
        module_nm: "",
        setup_value: "",
        use_yn: "Y"
      },
      blankCheckFields: ["lclas_cd", "mclas_cd", "sclas_cd", "setup_sctn_cd"],
      comparableFields: [
        "module_nm", "setup_value", "use_yn"
      ],
      firstEditCol: "setup_unit_cd",
      pkLabels: {
        setup_unit_cd: "설정단위",
        cust_cd: "고객코드",
        lclas_cd: "대분류",
        mclas_cd: "중분류",
        sclas_cd: "소분류",
        setup_sctn_cd: "설정구분"
      }
    }
  }

  buildNewRowOverrides() {
    const setupUnitField = this.element.querySelector("[name='q[setup_unit_cd]']")
    const customerField = this.element.querySelector("[name='q[cust_cd]']")

    const setupUnit = (setupUnitField?.value || "SYSTEM").toString().trim().toUpperCase()
    const customerCode = (customerField?.value || "").toString().trim().toUpperCase()

    if (setupUnit === "CUSTOMER") {
      return {
        setup_unit_cd: "CUSTOMER",
        cust_cd: customerCode
      }
    }

    return {
      setup_unit_cd: "SYSTEM",
      cust_cd: ""
    }
  }

  get saveMessage() {
    return "고객별 시스템 설정이 저장되었습니다."
  }
}
