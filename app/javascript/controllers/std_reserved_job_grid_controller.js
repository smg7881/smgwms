import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["rsv_work_no"],
      fields: {
        sys_sctn_cd: "trimUpper",
        rsv_work_no: "trimUpper",
        rel_menu_cd: "trimUpper",
        rel_menu_nm: "trim",
        rsv_work_nm_cd: "trim",
        rsv_work_desc_cd: "trim",
        rel_pgm_cd: "trimUpper",
        rel_pgm_nm: "trim",
        pgm_sctn_cd: "trimUpper",
        rsv_work_cycle_cd: "trimUpper",
        hms_unit_min: "number",
        rmk_cd: "trim",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        sys_sctn_cd: "WMS",
        rsv_work_no: "",
        rel_menu_cd: "",
        rel_menu_nm: "",
        rsv_work_nm_cd: "",
        rsv_work_desc_cd: "",
        rel_pgm_cd: "",
        rel_pgm_nm: "",
        pgm_sctn_cd: "BATCH",
        rsv_work_cycle_cd: "DAILY",
        hms_unit_min: null,
        rmk_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["rsv_work_nm_cd"],
      comparableFields: [
        "sys_sctn_cd", "rel_menu_cd", "rel_menu_nm", "rsv_work_nm_cd", "rsv_work_desc_cd",
        "rel_pgm_cd", "rel_pgm_nm", "pgm_sctn_cd", "rsv_work_cycle_cd", "hms_unit_min",
        "rmk_cd", "use_yn_cd"
      ],
      firstEditCol: "sys_sctn_cd",
      pkLabels: { rsv_work_no: "Reserved Job No" }
    }
  }

  get saveMessage() {
    return "Reserved job data saved."
  }
}
