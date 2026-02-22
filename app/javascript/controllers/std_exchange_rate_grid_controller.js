import BaseGridController from "controllers/base_grid_controller"
import { getSearchFieldValue } from "controllers/grid/grid_utils"

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
        ctry_cd: "국가코드",
        fnc_or_cd: "금융기관",
        std_ymd: "기준일자",
        anno_dgrcnt: "고시회차",
        mon_cd: "통화"
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
    return getSearchFieldValue(this.element, "ctry_cd")
  }

  get currentFinancialOrg() {
    return getSearchFieldValue(this.element, "fnc_or_cd")
  }

  get currentAnnouncementDegree() {
    return getSearchFieldValue(this.element, "anno_dgrcnt")
  }

  get currentStandardDate() {
    return getSearchFieldValue(this.element, "std_ymd", { toUpperCase: false })
  }

  get yesterdayDate() {
    const date = new Date()
    date.setDate(date.getDate() - 1)
    const yyyy = date.getFullYear()
    const mm = `${date.getMonth() + 1}`.padStart(2, "0")
    const dd = `${date.getDate()}`.padStart(2, "0")
    return `${yyyy}-${mm}-${dd}`
  }

  static values = {
    ...super.values,
    fetchUrl: String
  }

  async fetchRates() {
    if (!confirm("외부 API에서 환율 정보를 강제로 수집하시겠습니까? (최대 1~3초 소요)")) return

    try {
      const url = this.fetchUrlValue
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept": "application/json"
        }
      })
      const data = await response.json()
      if (data.success) {
        alert(data.message || "환율 정보가 성공적으로 수집/갱신되었습니다.")
        this.fetchData() // 그리드 새로 데이터 로드
      } else {
        alert(data.message || "환율 정보 수집 중 오류가 발생했습니다.")
      }
    } catch (e) {
      alert("서버와 통신 중 문제가 발생했습니다.")
    }
  }

  get saveMessage() {
    return "환율 정보가 저장되었습니다."
  }
}
