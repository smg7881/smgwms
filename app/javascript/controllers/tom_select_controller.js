import { Controller } from "@hotwired/stimulus"

// TomSelect는 application.html.erb의 <script> 태그로 전역 로드됨 (window.TomSelect)

/**
 * TomSelectController
 *
 * <select> 요소에 Tom Select를 초기화합니다.
 *
 * Values:
 *   searchable   : 검색 입력 허용 여부 (기본: false)
 *   multi        : 다중 선택 허용 여부 (기본: false)
 *   placeholder  : 플레이스홀더 텍스트 (기본: "")
 */
export default class extends Controller {
  static values = {
    searchable: { type: Boolean, default: true },
    multi: { type: Boolean, default: false },
    placeholder: { type: String, default: "" },
  }

  connect() {
    const TS = window.TomSelect
    if (!TS) {
      console.error("[tom-select] window.TomSelect not found. Check <script> tag in application.html.erb")
      return
    }

    const config = {
      allowEmptyOption: true,
      placeholder: this.placeholderValue || undefined,
      dropdownParent: document.body,
      plugins: [],
    }

    if (this.multiValue) {
      config.plugins.push("remove_button")
      config.maxItems = null
    }

    if (!this.searchableValue) {
      config.controlInput = null  // 키 입력 차단 (검색 비활성화)
    }

    this.#ts = new TS(this.element, config)

    // single select: 닫힌 상태에서 검색 input 숨기고 선택값만 표시
    if (!this.multiValue) {
      this.#hideInput()
      this.#ts.on('dropdown_open', () => this.#showInput())
      this.#ts.on('dropdown_close', () => this.#hideInput())
    }

    // overflow:hidden 컨테이너 안에서도 드롭다운이 올바르게 표시되도록
    // positionDropdown을 fixed 포지셔닝 방식으로 재정의
    this.#ts.positionDropdown = () => {
      const dropdown = this.#ts.dropdown
      const wrapper = this.#ts.wrapper
      const rect = wrapper.getBoundingClientRect()
      const dropdownHeight = dropdown.offsetHeight || 200
      const spaceBelow = window.innerHeight - rect.bottom

      dropdown.style.position = 'fixed'
      dropdown.style.width  = rect.width + 'px'
      dropdown.style.left   = rect.left + 'px'
      dropdown.style.zIndex = '9999'

      if (spaceBelow >= dropdownHeight || spaceBelow >= rect.top) {
        dropdown.style.top    = rect.bottom + 'px'
        dropdown.style.bottom = ''
      } else {
        dropdown.style.top    = ''
        dropdown.style.bottom = (window.innerHeight - rect.top) + 'px'
      }
    }
  }

  disconnect() {
    this.#ts?.destroy()
    this.#ts = null
  }

  #ts = null

  #showInput() {
    const input = this.#ts?.control?.querySelector('input')
    const items = this.#ts?.control?.querySelectorAll('.item')
    if (input) input.style.cssText = ''
    items?.forEach(el => { el.style.display = 'none' })
  }

  #hideInput() {
    const input = this.#ts?.control?.querySelector('input')
    const items = this.#ts?.control?.querySelectorAll('.item')
    if (input) {
      input.style.width = '0'
      input.style.minWidth = '0'
      input.style.opacity = '0'
      input.style.position = 'absolute'
      input.style.pointerEvents = 'none'
    }
    items?.forEach(el => { el.style.display = '' })
  }
}
