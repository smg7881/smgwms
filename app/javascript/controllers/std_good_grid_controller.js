import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["goods_cd"],
      fields: {
        goods_cd: "trimUpper",
        goods_nm: "trim",
        hatae_cd: "trimUpper",
        item_grp_cd: "trimUpper",
        item_cd: "trimUpper",
        hwajong_cd: "trimUpper",
        hwajong_grp_cd: "trimUpper",
        rmk_cd: "trim",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        goods_cd: "",
        goods_nm: "",
        hatae_cd: "",
        item_grp_cd: "",
        item_cd: "",
        hwajong_cd: "",
        hwajong_grp_cd: "",
        rmk_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["goods_nm"],
      comparableFields: ["goods_nm", "hatae_cd", "item_grp_cd", "item_cd", "hwajong_cd", "hwajong_grp_cd", "rmk_cd", "use_yn_cd"],
      firstEditCol: "goods_cd",
      pkLabels: { goods_cd: "Goods Code" }
    }
  }

  get saveMessage() {
    return "Goods data saved."
  }
}
