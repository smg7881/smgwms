import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["bzac_cd"],
      fields: {
        bzac_cd: "trimUpper",
        bzac_nm: "trim",
        compreg_slip: "trim",
        bizman_yn_cd: "trimUpper",
        store_nm_cd: "trim",
        rptr_nm_cd: "trim",
        corp_reg_no_cd: "trim",
        bizcond_cd: "trim",
        indstype_cd: "trim",
        dup_bzac_yn_cd: "trimUpperDefault:N",
        zip_cd: "trim",
        zipaddr_cd: "trim",
        dtl_addr_cd: "trim",
        rmk: "trim",
        clbiz_ymd: "trim",
        attached_file_nm: "trim",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        bzac_cd: "",
        bzac_nm: "",
        compreg_slip: "",
        bizman_yn_cd: "BUSINESS",
        store_nm_cd: "",
        rptr_nm_cd: "",
        corp_reg_no_cd: "",
        bizcond_cd: "",
        indstype_cd: "",
        dup_bzac_yn_cd: "N",
        zip_cd: "",
        zipaddr_cd: "",
        dtl_addr_cd: "",
        rmk: "",
        clbiz_ymd: "",
        attached_file_nm: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["compreg_slip"],
      comparableFields: [
        "bzac_nm", "compreg_slip", "bizman_yn_cd", "store_nm_cd", "rptr_nm_cd",
        "corp_reg_no_cd", "bizcond_cd", "indstype_cd", "dup_bzac_yn_cd",
        "zip_cd", "zipaddr_cd", "dtl_addr_cd", "rmk", "clbiz_ymd",
        "attached_file_nm", "use_yn_cd"
      ],
      firstEditCol: "bzac_cd",
      pkLabels: { bzac_cd: "Client Code" }
    }
  }

  get saveMessage() {
    return "Business certificate data saved."
  }
}
