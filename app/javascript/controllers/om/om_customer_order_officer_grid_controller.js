import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["id"],
      fields: {
        id: "number",
        ord_chrg_dept_cd: "trimUpper",
        ord_chrg_dept_nm: "trim",
        cust_cd: "trimUpper",
        cust_nm: "trim",
        exp_imp_dom_sctn_cd: "trimUpperDefault:DOMESTIC",
        cust_ofcr_nm: "trim",
        cust_ofcr_tel_no: "trim",
        cust_ofcr_mbp_no: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        id: null,
        ord_chrg_dept_cd: "",
        ord_chrg_dept_nm: "",
        cust_cd: "",
        cust_nm: "",
        exp_imp_dom_sctn_cd: "DOMESTIC",
        cust_ofcr_nm: "",
        cust_ofcr_tel_no: "",
        cust_ofcr_mbp_no: "",
        use_yn: "Y"
      },
      blankCheckFields: ["ord_chrg_dept_cd", "cust_cd", "cust_ofcr_nm", "cust_ofcr_tel_no"],
      comparableFields: [
        "ord_chrg_dept_cd",
        "ord_chrg_dept_nm",
        "cust_cd",
        "cust_nm",
        "exp_imp_dom_sctn_cd",
        "cust_ofcr_nm",
        "cust_ofcr_tel_no",
        "cust_ofcr_mbp_no",
        "use_yn"
      ],
      firstEditCol: "ord_chrg_dept_cd",
      pkLabels: { id: "고객오더담당자 ID" },
      onCellValueChanged: (event) => this.handleLookupFieldChange(event)
    }
  }

  handleLookupFieldChange(event) {
    if (!event?.node?.data) return

    const field = event?.colDef?.field
    if (field === "ord_chrg_dept_cd" && event.newValue !== event.oldValue) {
      event.node.setDataValue("ord_chrg_dept_nm", "")
    }
    if (field === "cust_cd" && event.newValue !== event.oldValue) {
      event.node.setDataValue("cust_nm", "")
    }
  }

  get saveMessage() {
    return "고객오더담당자 정보가 저장되었습니다."
  }
}
