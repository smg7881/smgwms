import { Controller } from "@hotwired/stimulus"

// flatpickr는 application.html.erb의 <script> 태그로 전역 로드됨 (window.flatpickr)

// 한국어 로케일
const Korean = {
  firstDayOfWeek: 1,
  weekdays: {
    shorthand: ["일", "월", "화", "수", "목", "금", "토"],
    longhand: ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"],
  },
  months: {
    shorthand: ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"],
    longhand: ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"],
  },
  rangeSeparator: " ~ ",
  weekAbbreviation: "주",
  scrollTitle: "스크롤하세요",
  toggleTitle: "클릭하세요",
  amPM: ["오전", "오후"],
  yearAriaLabel: "년",
  time_24hr: true,
}

/**
 * FlatpickrController
 *
 * 날짜/날짜범위 피커를 초기화합니다.
 *
 * Values:
 *   mode    : "date" | "datetime" | "range" (기본: "date")
 *   format  : 날짜 포맷 문자열 (기본: "Y-m-d")
 *   min     : 최소 날짜 (선택)
 *   max     : 최대 날짜 (선택)
 *
 * Targets (range 모드 전용):
 *   from    : 시작일 hidden input
 *   to      : 종료일 hidden input
 */
export default class extends Controller {
  static values = {
    mode:   { type: String, default: "date" },
    format: { type: String, default: "Y-m-d" },
    min:    String,
    max:    String,
  }

  static targets = ["from", "to"]

  connect() {
    const fp = window.flatpickr
    if (!fp) {
      console.error("[flatpickr] window.flatpickr not found. Check <script> tag in application.html.erb")
      return
    }

    const config = {
      locale: Korean,
      dateFormat: this.formatValue,
      allowInput: true,
      disableMobile: true,
    }

    if (this.minValue) config.minDate = this.minValue
    if (this.maxValue) config.maxDate = this.maxValue

    if (this.modeValue === "datetime") {
      config.enableTime = true
      config.dateFormat = "Y-m-d H:i"
      config.time_24hr = true
    }

    if (this.modeValue === "range") {
      config.mode = "range"
      config.onClose = this.#onRangeClose.bind(this)
    }

    // <dialog> 내부에서 사용 시: 달력을 dialog에 append해야 top-layer 위에 표시됨
    const dialogEl = this.element.closest("dialog")
    if (dialogEl) {
      config.appendTo = dialogEl
    }

    // 컨테이너 div에 붙은 경우 내부 text input을 찾아 초기화
    const inputEl = this.element.tagName === "INPUT"
      ? this.element
      : this.element.querySelector("input:not([type='hidden'])")

    if (inputEl) {
      this.#fp = fp(inputEl, config)
    }
  }

  disconnect() {
    this.#fp?.destroy()
    this.#fp = null
  }

  // 달력 토글 버튼에서 호출 (data-action="click->flatpickr#open")
  open() {
    this.#fp?.open()
  }

  // range 모드: 선택 완료 시 from/to hidden input에 값 세팅
  #onRangeClose(selectedDates) {
    if (this.hasFromTarget && selectedDates[0]) {
      this.fromTarget.value = this.#fp.formatDate(selectedDates[0], "Y-m-d")
    }
    if (this.hasToTarget && selectedDates[1]) {
      this.toTarget.value = this.#fp.formatDate(selectedDates[1], "Y-m-d")
    }
  }

  #fp = null
}
