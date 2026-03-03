import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["if_cd"],
      fields: {
        corp_cd: "trimUpper",
        if_cd: "trimUpper",
        if_meth_cd: "trimUpper",
        if_sctn_cd: "trimUpper",
        if_nm_cd: "trim",
        send_sys_cd: "trimUpper",
        rcv_sys_cd: "trimUpper",
        rcv_sctn_cd: "trimUpper",
        use_yn_cd: "trimUpperDefault:Y",
        if_bzac_cd: "trimUpper",
        bzac_nm: "trim",
        bzac_sys_nm_cd: "trim",
        if_desc_cd: "trim"
      },
      defaultRow: {
        corp_cd: "",
        if_cd: "",
        if_meth_cd: "API",
        if_sctn_cd: "INTERNAL",
        if_nm_cd: "",
        send_sys_cd: "",
        rcv_sys_cd: "",
        rcv_sctn_cd: "BOTH",
        use_yn_cd: "Y",
        if_bzac_cd: "",
        bzac_nm: "",
        bzac_sys_nm_cd: "",
        if_desc_cd: ""
      },
      blankCheckFields: ["if_nm_cd"],
      comparableFields: [
        "corp_cd", "if_meth_cd", "if_sctn_cd", "if_nm_cd", "send_sys_cd", "rcv_sys_cd",
        "rcv_sctn_cd", "use_yn_cd", "if_bzac_cd", "bzac_nm", "bzac_sys_nm_cd", "if_desc_cd"
      ],
      firstEditCol: "corp_cd",
      pkLabels: { if_cd: "인터페이스코드" }
    }
  }

  get saveMessage() {
    return "인터페이스 정보가 저장되었습니다."
  }
}
