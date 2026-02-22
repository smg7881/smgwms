import BaseGridController from "controllers/base_grid_controller"
import { getCsrfToken, getSearchFieldValue } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    generateWeekendsUrl: String
  }

  configureManager() {
    return {
      pkFields: ["ctry_cd", "ymd"],
      fields: {
        ctry_cd: "trimUpper",
        ymd: "trim",
        holiday_nm_cd: "trim",
        sat_yn_cd: "trimUpperDefault:N",
        sunday_yn_cd: "trimUpperDefault:N",
        clsdy_yn_cd: "trimUpperDefault:N",
        asmt_holday_yn_cd: "trimUpperDefault:N",
        event_day_yn_cd: "trimUpperDefault:N",
        rmk_cd: "trim",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        ctry_cd: "",
        ymd: "",
        holiday_nm_cd: "",
        sat_yn_cd: "N",
        sunday_yn_cd: "N",
        clsdy_yn_cd: "N",
        asmt_holday_yn_cd: "N",
        event_day_yn_cd: "N",
        rmk_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["holiday_nm_cd"],
      comparableFields: [
        "holiday_nm_cd", "sat_yn_cd", "sunday_yn_cd", "clsdy_yn_cd",
        "asmt_holday_yn_cd", "event_day_yn_cd", "rmk_cd", "use_yn_cd"
      ],
      firstEditCol: "ymd",
      pkLabels: { ctry_cd: "국가코드", ymd: "일자" }
    }
  }

  buildNewRowOverrides() {
    return {
      ctry_cd: this.currentCountryCode,
      ymd: this.defaultYmd
    }
  }

  async generateWeekends() {
    const ctryCd = this.currentCountryCode
    const year = this.currentYear
    const month = this.currentMonth

    if (!ctryCd || !year || !month) {
      alert("국가코드/년도/월을 입력해주세요.")
      return
    }

    try {
      const response = await fetch(this.generateWeekendsUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken()
        },
        body: JSON.stringify({
          ctry_cd: ctryCd,
          year: year,
          month: month
        })
      })
      const result = await response.json()
      if (!response.ok || !result.success) {
        alert("토/일 생성 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "토/일 생성이 완료되었습니다.")
      this.reloadRows()
    } catch {
      alert("토/일 생성 실패: 네트워크 오류")
    }
  }

  get saveMessage() {
    return "공휴일 데이터가 저장되었습니다."
  }

  get currentCountryCode() {
    return getSearchFieldValue(this.element, "ctry_cd")
  }

  get currentYear() {
    return getSearchFieldValue(this.element, "year", { toUpperCase: false })
  }

  get currentMonth() {
    return getSearchFieldValue(this.element, "month", { toUpperCase: false })
  }

  get defaultYmd() {
    if (!this.currentYear || !this.currentMonth) {
      return ""
    }

    const normalizedMonth = this.currentMonth.padStart(2, "0")
    return `${this.currentYear}-${normalizedMonth}-01`
  }
}
