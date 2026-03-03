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
    searchable: { type: Boolean, default: false },
    multi: { type: Boolean, default: false },
    placeholder: { type: String, default: "" },
  }

  connect() {
    const TS = window.TomSelect
    if (!TS) {
      console.error("[tom-select] window.TomSelect not found. Check <script> tag in application.html.erb")
      return
    }

    // Turbo 캐시 복원 시 남은 고아 .ts-wrapper 제거 (이중 초기화 방지)
    this.element.parentElement
      ?.querySelectorAll('.ts-wrapper')
      .forEach(el => el.remove())

    // 이미 초기화된 경우 정리
    if (this.element.tomselect) {
      this.element.tomselect.destroy()
    }

    // <dialog> 내부에 있을 때: dialog는 CSS top-layer에 있으므로
    // 드롭다운도 dialog 안에 있어야 top-layer에서 렌더링됨
    const closestDialog = this.element.closest('dialog')
    const config = {
      allowEmptyOption: true,
      placeholder: this.placeholderValue || undefined,
      dropdownParent: closestDialog || document.body,
      plugins: [],
    }

    if (this.multiValue) {
      config.plugins.push("remove_button")
      config.maxItems = null
    }

    if (!this.searchableValue) {
      // readonly input: 문자 검색은 막고 포커스·화살표키 네비게이션은 허용
      const readonlyInput = document.createElement('input')
      readonlyInput.setAttribute('readonly', '')
      config.controlInput = readonlyInput
    }

    this.#ts = new TS(this.element, config)

    // single select: 닫힌 상태에서 검색 input 숨기고 선택값만 표시
    if (!this.multiValue) {
      this.#hideInput()
      if (this.searchableValue) {
        this.#ts.on('dropdown_open', () => {
          this.#showInput()
          this.#ts?.positionDropdown?.()
        })
        this.#ts.on('dropdown_close', () => this.#hideInput())
      } else {
        this.#ts.on('dropdown_open', () => this.#ts?.positionDropdown?.())
      }
    } else {
      this.#ts.on('dropdown_open', () => this.#ts?.positionDropdown?.())
    }

    // overflow:hidden 컨테이너 안에서도 드롭다운이 올바르게 표시되도록
    // positionDropdown을 fixed 포지셔닝 방식으로 재정의
    this.#ts.positionDropdown = () => {
      const dropdown = this.#ts.dropdown
      const wrapper = this.#ts.wrapper
      const rect = wrapper.getBoundingClientRect()
      const naturalHeight = Math.min(dropdown.scrollHeight || dropdown.offsetHeight || 220, 320)
      const spaceBelow = window.innerHeight - rect.bottom
      const spaceAbove = rect.top

      dropdown.style.position = 'fixed'
      dropdown.style.width = rect.width + 'px'
      dropdown.style.left = rect.left + 'px'
      dropdown.style.zIndex = '9999'

      const enoughBelow = spaceBelow >= naturalHeight
      const enoughAbove = spaceAbove >= naturalHeight
      const openUp = (!enoughBelow && enoughAbove) || (!enoughBelow && spaceAbove > spaceBelow)
      const availableSpace = openUp ? spaceAbove : spaceBelow
      const maxHeight = Math.max(140, Math.floor(availableSpace - 8))
      const visibleHeight = Math.min(naturalHeight, maxHeight)

      dropdown.style.maxHeight = `${maxHeight}px`
      dropdown.style.bottom = ''

      if (openUp) {
        dropdown.style.top = `${Math.max(8, Math.floor(rect.top - visibleHeight))}px`
      } else {
        dropdown.style.top = `${Math.floor(rect.bottom)}px`
      }
    }

    // Turbo 캐시 스냅샷 전에 Tom Select 정리 (스냅샷에 .ts-wrapper가 포함되지 않도록)
    document.addEventListener('turbo:before-cache', this.#handleBeforeCache)
  }

  disconnect() {
    document.removeEventListener('turbo:before-cache', this.#handleBeforeCache)
    this.#ts?.destroy()
    this.#ts = null
  }

  #ts = null

  // Turbo 캐시 직전 Tom Select 정리 → 스냅샷에 깨끗한 <select>만 남김
  #handleBeforeCache = () => {
    this.#ts?.destroy()
    this.#ts = null
  }

  #showInput() {
    const input = this.#ts?.control?.querySelector('input')
    const items = this.#ts?.control?.querySelectorAll('.item')
    if (input) {
      if (this.searchableValue) {
        input.style.cssText = ''
      } else {
        this.#hideInputCompletely(input)
      }
    }
    items?.forEach(el => { el.style.display = 'none' })
  }

  #hideInput() {
    const input = this.#ts?.control?.querySelector('input')
    const items = this.#ts?.control?.querySelectorAll('.item')
    if (input) {
      if (this.searchableValue) {
        input.style.width = '0'
        input.style.minWidth = '0'
        input.style.opacity = '0'
        input.style.position = 'absolute'
        input.style.pointerEvents = 'none'
      } else {
        this.#hideInputCompletely(input)
      }
    }
    items?.forEach(el => { el.style.display = '' })
  }

  #hideInputCompletely(input) {
    input.style.setProperty('display', 'none', 'important')
    input.style.width = '0'
    input.style.minWidth = '0'
    input.style.opacity = '0'
    input.style.position = 'absolute'
    input.style.pointerEvents = 'none'
  }
}
