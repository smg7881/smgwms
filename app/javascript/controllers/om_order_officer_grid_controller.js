import BaseGridController from "controllers/base_grid_controller"
import { getCsrfToken, getSearchFieldValue } from "controllers/grid/grid_utils"

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
        ofcr_cd: "trimUpper",
        ofcr_nm: "trim",
        tel_no: "trim",
        mbp_no: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        id: null,
        ord_chrg_dept_cd: "",
        ord_chrg_dept_nm: "",
        cust_cd: "",
        cust_nm: "",
        exp_imp_dom_sctn_cd: "DOMESTIC",
        ofcr_cd: "",
        ofcr_nm: "",
        tel_no: "",
        mbp_no: "",
        use_yn: "Y"
      },
      blankCheckFields: ["ord_chrg_dept_cd", "cust_cd", "ofcr_cd"],
      comparableFields: [
        "ord_chrg_dept_cd",
        "ord_chrg_dept_nm",
        "cust_cd",
        "cust_nm",
        "exp_imp_dom_sctn_cd",
        "ofcr_cd",
        "ofcr_nm",
        "tel_no",
        "mbp_no",
        "use_yn"
      ],
      firstEditCol: "ord_chrg_dept_cd",
      pkLabels: { id: "오더담당자 ID" },
      onCellValueChanged: (event) => this.handleLookupFieldChange(event)
    }
  }

  buildNewRowOverrides() {
    const deptCode = getSearchFieldValue(this.element, "dept_cd")
    const custCode = getSearchFieldValue(this.element, "cust_cd")
    const expImpDomSctnCd = getSearchFieldValue(this.element, "exp_imp_dom_sctn_cd") || "DOMESTIC"

    return {
      ord_chrg_dept_cd: deptCode,
      cust_cd: custCode,
      exp_imp_dom_sctn_cd: expImpDomSctnCd.toUpperCase()
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
    if (field === "ofcr_cd" && event.newValue !== event.oldValue) {
      event.node.setDataValue("ofcr_nm", "")
      event.node.setDataValue("tel_no", "")
      event.node.setDataValue("mbp_no", "")
    }
  }

  handleLookupSelected(event) {
    const rowNode = event?.detail?.rowNode
    const colDef = event?.detail?.colDef
    const selection = event?.detail?.selection || {}

    if (!rowNode || !colDef) return

    const nameField = colDef?.context?.lookup_name_field || colDef.field
    const codeField = colDef?.context?.lookup_code_field
    if (codeField !== "ofcr_cd") return

    const selectedName = String(selection.name ?? selection.display ?? "").trim()
    const selectedPhone = String(
      selection.phone ?? selection.tel_no ?? selection.ofic_telno_cd ?? ""
    ).trim()
    const selectedMobile = String(
      selection.mobile_phone ?? selection.mbp_no ?? selection.mbp_no_cd ?? selectedPhone
    ).trim()

    if (nameField) {
      rowNode.setDataValue(nameField, selectedName)
    }
    rowNode.setDataValue("tel_no", selectedPhone)
    rowNode.setDataValue("mbp_no", selectedMobile)
  }

  get saveMessage() {
    return "오더담당자 정보가 저장되었습니다."
  }
}
