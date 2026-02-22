import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  configureManager() {
    return {
      pkFields: ["ctry_cd", "fnc_or_cd", "std_ymd", "anno_dgrcnt", "mon_cd"],
      fields: {
        ctry_cd: "trimUpper",
        fnc_or_cd: "trimUpper",
        std_ymd: "trim",
        anno_dgrcnt: "trimUpper",
        mon_cd: "trimUpper",
        cash_buy: "number",
        cash_sell: "number",
        sendmoney_sndg: "number",
        sendmoney_rcvng: "number",
        tc_buy: "number",
        fcur_check_sell: "number",
        tradg_std_rt: "number",
        convmoney_rt: "number",
        usd_conv_rt: "number",
        if_yn_cd: "trimUpperDefault:N",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        ctry_cd: "",
        fnc_or_cd: "",
        std_ymd: "",
        anno_dgrcnt: "FIRST",
        mon_cd: "",
        cash_buy: null,
        cash_sell: null,
        sendmoney_sndg: null,
        sendmoney_rcvng: null,
        tc_buy: null,
        fcur_check_sell: null,
        tradg_std_rt: null,
        convmoney_rt: null,
        usd_conv_rt: null,
        if_yn_cd: "N",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["mon_cd"],
      comparableFields: [
        "cash_buy", "cash_sell", "sendmoney_sndg", "sendmoney_rcvng", "tc_buy",
        "fcur_check_sell", "tradg_std_rt", "convmoney_rt", "usd_conv_rt", "if_yn_cd", "use_yn_cd"
      ],
      firstEditCol: "ctry_cd",
      pkLabels: {
        ctry_cd: "Country",
        fnc_or_cd: "Financial Org",
        std_ymd: "Standard Date",
        anno_dgrcnt: "Announcement Degree",
        mon_cd: "Currency"
      }
    }
  }

  buildNewRowOverrides() {
    return {
      ctry_cd: this.currentCountryCode || "KR",
      fnc_or_cd: this.currentFinancialOrg,
      std_ymd: this.currentStandardDate || this.yesterdayDate,
      anno_dgrcnt: this.currentAnnouncementDegree || "FIRST"
    }
  }

  get currentCountryCode() {
    const field = this.element.querySelector("[name='q[ctry_cd]']")
    return field?.value?.toString().trim().toUpperCase() || ""
  }

  get currentFinancialOrg() {
    const field = this.element.querySelector("[name='q[fnc_or_cd]']")
    return field?.value?.toString().trim().toUpperCase() || ""
  }

  get currentAnnouncementDegree() {
    const field = this.element.querySelector("[name='q[anno_dgrcnt]']")
    return field?.value?.toString().trim().toUpperCase() || ""
  }

  get currentStandardDate() {
    const field = this.element.querySelector("[name='q[std_ymd]']")
    return field?.value?.toString().trim() || ""
  }

  get yesterdayDate() {
    const date = new Date()
    date.setDate(date.getDate() - 1)
    const yyyy = date.getFullYear()
    const mm = `${date.getMonth() + 1}`.padStart(2, "0")
    const dd = `${date.getDate()}`.padStart(2, "0")
    return `${yyyy}-${mm}-${dd}`
  }

  get saveMessage() {
    return "Exchange rate data saved."
  }
}
