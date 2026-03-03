import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["workpl_cd"],
      fields: {
        corp_cd: "trimUpper",
        workpl_cd: "trimUpper",
        upper_workpl_cd: "trimUpper",
        dept_cd: "trimUpper",
        workpl_nm: "trim",
        workpl_sctn_cd: "trimUpper",
        capa_spec_unit_cd: "trimUpper",
        max_capa: "number",
        adpt_capa: "number",
        dimem_spec_unit_cd: "trimUpper",
        dimem: "number",
        wm_yn_cd: "trimUpperDefault:N",
        bzac_cd: "trimUpper",
        ctry_cd: "trimUpper",
        zip_cd: "trim",
        addr_cd: "trim",
        dtl_addr_cd: "trim",
        use_yn_cd: "trimUpperDefault:Y",
        remk_cd: "trim"
      },
      defaultRow: {
        corp_cd: "",
        workpl_cd: "",
        upper_workpl_cd: "",
        dept_cd: "",
        workpl_nm: "",
        workpl_sctn_cd: "",
        capa_spec_unit_cd: "",
        max_capa: null,
        adpt_capa: null,
        dimem_spec_unit_cd: "",
        dimem: null,
        wm_yn_cd: "N",
        bzac_cd: "",
        ctry_cd: "KR",
        zip_cd: "",
        addr_cd: "",
        dtl_addr_cd: "",
        use_yn_cd: "Y",
        remk_cd: ""
      },
      blankCheckFields: ["workpl_nm", "dept_cd"],
      comparableFields: [
        "corp_cd", "upper_workpl_cd", "dept_cd", "workpl_nm", "workpl_sctn_cd",
        "capa_spec_unit_cd", "max_capa", "adpt_capa", "dimem_spec_unit_cd",
        "dimem", "wm_yn_cd", "bzac_cd", "ctry_cd", "zip_cd", "addr_cd",
        "dtl_addr_cd", "use_yn_cd", "remk_cd"
      ],
      firstEditCol: "workpl_cd",
      pkLabels: { workpl_cd: "작업장코드" }
    }
  }

  get saveMessage() {
    return "작업장 데이터가 저장되었습니다."
  }
}
