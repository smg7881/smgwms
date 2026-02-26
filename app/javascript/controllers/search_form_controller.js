/**
 * search_form_controller.js
 *
 * 대시보드 및 리스트 페이지의 상단에 위치하는 '조회 조건 필터 폼(Search Form)' UI를 제어합니다.
 * 주요 기능:
 * 1. 폼의 접기/펼치기(Collapse) 기능 (화면 크기나 초기설정에 따라 조건 박스 공간을 절약)
 * 2. 그리드 레이아웃의 Span 계산을 통해, 우측 끄트머리에 정렬되어야 할 조회/초기화 버튼 그룹 동적 정렬
 * 3. 새로고침 및 Turbo를 통한 폼 제출 로직 제어
 */
import { Controller } from "@hotwired/stimulus"
import { createIcons, icons } from "lucide"

export default class extends Controller {
  static targets = [
    "form",             // <form> 루트 태그
    "fieldGroup",       // 개별 검색조건 위젯 컨테이너 (한 줄 혹은 여러 줄 차지 단위)
    "collapseBtn",      // 우측 하단 접기/펼치기 토글 버튼 대상
    "collapseBtnIcon",  // 화살표 아이콘
    "buttonGroup"       // "조회", "초기화" 버튼이 묶인 div 컨테이너
  ]

  // data-* 값으로 제어받는 프로퍼티
  static values = {
    collapsed: { type: Boolean, default: true },      // 현재 폼이 다 닫혀있는지(접힘) 여부
    loading: { type: Boolean, default: false },       // 조회중 스피너/제출 락 용도
    collapsedRows: { type: Number, default: 1 },      // 닫혀있을 때 기본으로 몇 줄의 필드까지만 보여줄 건지 결정
    cols: { type: Number, default: 3 },               // 한 줄에 표시할 필드 수 (버튼 span 계산에 사용)
    enableCollapse: { type: Boolean, default: true }  // 접기 기능 자체가 사용 가능한지
  }

  // DOM 렌더링 시점에 초기 세팅 및 브라우저 리사이징 감시 등록
  connect() {
    if (!this.enableCollapseValue) {
      this.collapsedValue = false // 기능 오프라면 무조건 펼처둠
    }

    // 브라우저 윈도우 사이즈가 조절될 때, CSS Grid의 Span값이 동적으로 바뀔 가능성이 있어
    // 변화를 캐치하고 버튼 그룹의 위치를 재계산하기 위함
    this._resizeObserver = new ResizeObserver(() => {
      if (this.collapsedValue && this.enableCollapseValue) {
        this.#applyCollapse()
      }
      this.#updateButtonSpan()
    })
    this._resizeObserver.observe(this.element)

    this.collapsedValueChanged() // 상태 초깃값에 맞게 DOM 변경 트리거
  }

  disconnect() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect()
      this._resizeObserver = null
    }
  }

  // 조회 버튼 Submit 요청
  search(event) {
    // HTML5 네이티브 validation 통과하지 못하면 브라우저 말풍선 팝업 호출 후 폼 서밋 취소
    if (!this.formTarget.checkValidity()) {
      event.preventDefault()
      this.formTarget.reportValidity()
      return
    }

    // 문제 없으면 event.preventDefault()를 굳이 호출하지 않습니다.
    // 브라우저 또는 Turbo가 이벤트를 catch하여 정상 서밋하도록 둡니다.
  }

  // 초기화 버튼 클릭
  reset(event) {
    event.preventDefault()

    this.formTarget.reset() // DOM 입력폼 백지화

    const baseUrl = this.formTarget.action.split("?")[0]
    const turboFrame = this.formTarget.dataset.turboFrame

    // 필터 값 걷어내고 쌩 주소로 방문 요청하여 그리드를 완전히 초기 상태로 복구
    if (turboFrame && window.Turbo) {
      // 폼이 특정한 TurboFrame을 겨냥하고 있다면 그 영역만 교체 요청할 수 있도록 강제 visit 명령
      Turbo.visit(baseUrl, { frame: turboFrame })
    } else {
      window.location.href = baseUrl
    }
  }

  // 펼치기 / 접기 버튼 핸들러
  toggleCollapse(event) {
    event.preventDefault()
    this.collapsedValue = !this.collapsedValue // 값 변경 시 자동 collapsedValueChanged() 실행
  }

  // collapsedValue 변수 값 변경을 감지하는 Stimulus 콜백 메서드
  collapsedValueChanged() {
    if (this.collapsedValue && this.enableCollapseValue) {
      this.#applyCollapse() // 접음 로직 수행
      this.#updateCollapseButton(true)
    } else {
      this.#showAllFields() // 전부 다 보이도록 펼침
      this.#updateCollapseButton(false)
    }
    // 접히나 펴지나, 버튼 위치는 재계산되어야 하므로 공통 호출
    this.#updateButtonSpan()
  }

  // 접힌 상태: 버튼 자리를 빼고 남은 칸만큼 필드 표시
  #applyCollapse() {
    if (!this.hasFieldGroupTarget) return

    const colSpan = Math.floor(24 / this.colsValue)
    const maxSpan = (this.collapsedRowsValue * 24) - colSpan // 버튼 자리 빼기
    let accumulated = 0

    this.fieldGroupTargets.forEach(el => {
      const span = this.#spanOf(el)
      accumulated += span

      // 할당된 span 총합이 허용치 이상을 넘기면 이후 요소들은 전부 hidden 처리
      if (accumulated > maxSpan) {
        el.hidden = true
      } else {
        el.hidden = false
      }
    })
  }

  // 모조리 hidden 속성 제거
  #showAllFields() {
    if (!this.hasFieldGroupTarget) return

    this.fieldGroupTargets.forEach(el => {
      el.hidden = false
    })
  }

  // 해당 DOM 태그의 현재 화면상 grid-column 계산. Tailwind "col-span-8" 같은 CSS 적용본 추출.
  #spanOf(el) {
    const style = getComputedStyle(el)
    const gridColumn = style.gridColumnEnd

    const match = gridColumn.match(/span\s+(\d+)/)
    if (match) return parseInt(match[1], 10) // "span 8" 이면 8 리턴

    return 24 // 매칭 못하면 블록 단위 통짜 차지로 간주
  }

  // 버튼 그룹을 항상 첫 번째 줄 오른쪽 끝에 배치
  #updateButtonSpan() {
    if (!this.hasButtonGroupTarget) return

    // 버튼은 항상 첫 번째 줄, 오른쪽 끝
    const colSpan = Math.floor(24 / this.colsValue) // cols=4 → 6, cols=3 → 8
    const startCol = 24 - colSpan + 1               // cols=4 → 19, cols=3 → 17
    this.buttonGroupTarget.style.gridRow = "1"
    this.buttonGroupTarget.style.gridColumn = `${startCol} / -1`
  }

  // 필드가 한 줄에 모두 들어가는지 판단
  #needsCollapse() {
    if (!this.hasFieldGroupTarget) return false

    const colSpan = Math.floor(24 / this.colsValue)
    const maxSpan = this.collapsedRowsValue * 24 - colSpan // 버튼 자리 빼기
    let totalSpan = 0

    this.fieldGroupTargets.forEach(el => {
      totalSpan += this.#spanOf(el)
    })

    return totalSpan > maxSpan
  }

  // 펼치기 버튼 표시/숨김 처리
  #updateCollapseButtonVisibility() {
    if (!this.hasCollapseBtnTarget) return

    if (this.#needsCollapse()) {
      this.collapseBtnTarget.hidden = false
    } else {
      this.collapseBtnTarget.hidden = true
    }
  }

  // 접기/펼치기 아이콘 토글링
  #updateCollapseButton(isCollapsed) {
    this.#updateCollapseButtonVisibility()

    if (this.hasCollapseBtnTarget) {
      this.collapseBtnTarget.setAttribute("aria-expanded", String(!isCollapsed))
    }
    if (this.hasCollapseBtnIconTarget) {
      const iconName = isCollapsed ? "chevron-down" : "chevron-up"
      this.collapseBtnIconTarget.innerHTML =
        `<i data-lucide="${iconName}" class="w-4 h-4"></i>`
      createIcons({ icons, nodes: [this.collapseBtnIconTarget] })
    }
  }

  /**
   * 폼 내 HTML DOM을 검색하여 특정 필드(fieldName)의 값을 반환하는 공통 함수
   * (input, select, radio, 달력, 팝업 등 지원)
   * @param {string} fieldName 찾고자 하는 필드의 name 속성 (예: 'q[workpl_cd]')
   * @returns {any} 필드의 값
   */
  getSearchFieldValue(fieldName) {
    if (!this.hasFormTarget) return null

    const elements = this.formTarget.querySelectorAll(`[name="${fieldName}"]`)
    if (elements.length === 0) return null

    // 라디오 버튼 처리
    if (elements[0].type === "radio") {
      const checkedRadio = Array.from(elements).find(el => el.checked)
      return checkedRadio ? checkedRadio.value : null
    }

    // 체크박스 처리 (Rails의 hidden 우선 생성 패턴 대비, 실제 checkbox 요소만 추출)
    const checkboxes = Array.from(elements).filter(el => el.type === "checkbox")
    if (checkboxes.length > 0) {
      const checked = checkboxes.filter(el => el.checked)
      if (checkboxes.length === 1) {
        return checked.length > 0 ? checked[0].value : null
      }
      return checked.map(el => el.value)
    }

    // 다중 선택 Select 처리
    if (elements[0].tagName === "SELECT" && elements[0].multiple) {
      return Array.from(elements[0].selectedOptions).map(opt => opt.value)
    }

    // 일반 input (text, hidden, number 등), select(single), textarea 등
    // (동일 이름이 중복된 경우, 화면 구조상 주로 맨 뒤의 요소가 유효값을 담고 있으므로 마지막 요소를 선택)
    return elements[elements.length - 1].value
  }

  /**
   * 특정 필드(fieldName)에 값을 세팅하는 공통 함수
   * @param {string} fieldName 세팅하고자 하는 필드의 name 속성
   * @param {any} value 세팅할 값
   */
  setSearchFieldValue(fieldName, value) {
    if (!this.hasFormTarget) return

    const elements = this.formTarget.querySelectorAll(`[name="${fieldName}"]`)
    if (elements.length === 0) return

    // 라디오 버튼 값 지정
    if (elements[0].type === "radio") {
      let isSet = false
      elements.forEach(el => {
        if (el.value === String(value)) {
          el.checked = true
          isSet = true
        } else {
          el.checked = false
        }
      })
      if (isSet) elements[0].dispatchEvent(new Event("change", { bubbles: true }))
      return
    }

    // 체크박스 값 지정
    const checkboxes = Array.from(elements).filter(el => el.type === "checkbox")
    if (checkboxes.length > 0) {
      if (Array.isArray(value)) {
        checkboxes.forEach(el => {
          el.checked = value.includes(el.value)
        })
      } else {
        checkboxes.forEach(el => {
          el.checked = (value === true || el.value === String(value))
        })
      }
      checkboxes[0].dispatchEvent(new Event("change", { bubbles: true }))
      return
    }

    // 입력 필드(text, hidden), 달력 등 실제 값 세팅 요소
    const targetEl = elements[elements.length - 1]

    // 다중 선택 Select 처리
    if (targetEl.tagName === "SELECT" && targetEl.multiple) {
      const valArray = Array.isArray(value) ? value : [String(value)]
      Array.from(targetEl.options).forEach(opt => {
        opt.selected = valArray.includes(opt.value)
      })
    } else {
      // 일반 단일 입력/선택 값 지정
      targetEl.value = value
    }

    // 변경된 값을 UI나 그리드 등 외부에서 알 수 있도록 이벤트 트리거 발생
    targetEl.dispatchEvent(new Event("input", { bubbles: true }))
    targetEl.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
