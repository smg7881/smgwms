import { Controller } from "@hotwired/stimulus"

// ── 검색 폼 Stimulus 컨트롤러 ──
// 검색 폼의 접기/펼치기, 검색, 초기화 기능을 담당합니다.
// data-controller="search-form" 으로 사용합니다.
export default class extends Controller {
  static targets = [
    "form",          // <form> 요소
    "fieldGroup",    // 각 필드 래퍼 (.sf-field)
    "collapseBtn",   // 접기/펼치기 버튼
    "collapseBtnText",  // 버튼 텍스트
    "collapseBtnIcon",  // 버튼 아이콘
    "buttonGroup"    // 버튼 그룹 래퍼
  ]

  static values = {
    collapsed: { type: Boolean, default: true },
    loading: { type: Boolean, default: false },
    collapsedRows: { type: Number, default: 1 },
    cols: { type: Number, default: 3 },
    enableCollapse: { type: Boolean, default: true }
  }

  // ── 생명주기: 연결 ──
  connect() {
    // 접기/펼치기가 비활성화되면 모든 필드를 표시
    if (!this.enableCollapseValue) {
      this.collapsedValue = false
    }

    // ResizeObserver 등록 — 브레이크포인트 변경 시 collapse 재계산
    this._resizeObserver = new ResizeObserver(() => {
      if (this.collapsedValue && this.enableCollapseValue) {
        this.#applyCollapse()
      }
    })
    this._resizeObserver.observe(this.element)

    // 초기 collapse 적용
    this.collapsedValueChanged()
  }

  // ── 생명주기: 연결 해제 ──
  disconnect() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect()
      this._resizeObserver = null
    }
  }

  // ── 검색 액션 ──
  // form의 HTML5 유효성 검사 후 submit
  search(event) {
    event.preventDefault()

    if (!this.formTarget.checkValidity()) {
      this.formTarget.reportValidity()
      return
    }

    this.formTarget.requestSubmit()
  }

  // ── 초기화 액션 ──
  // 모든 입력값 제거 후 기본 URL로 Turbo 네비게이션
  reset(event) {
    event.preventDefault()

    this.formTarget.reset()

    // URL에서 쿼리 파라미터 제거 후 이동
    const baseUrl = this.formTarget.action.split("?")[0]
    const turboFrame = this.formTarget.dataset.turboFrame

    if (turboFrame && window.Turbo) {
      Turbo.visit(baseUrl, { frame: turboFrame })
    } else {
      window.location.href = baseUrl
    }
  }

  // ── 접기/펼치기 토글 ──
  toggleCollapse(event) {
    event.preventDefault()
    this.collapsedValue = !this.collapsedValue
  }

  // ── collapsedValue 변경 콜백 ──
  // Stimulus의 value changed callback으로 자동 호출됩니다.
  collapsedValueChanged() {
    if (this.collapsedValue && this.enableCollapseValue) {
      this.#applyCollapse()
      this.#updateCollapseButton(true)
    } else {
      this.#showAllFields()
      this.#updateCollapseButton(false)
    }
    this.#updateButtonSpan()
  }

  // ── Private: collapse 적용 ──
  // getComputedStyle 기반으로 실제 span을 읽어 누적하고,
  // collapsedRows * 24를 초과하면 hidden 처리합니다.
  #applyCollapse() {
    if (!this.hasFieldGroupTarget) return

    const maxSpan = this.collapsedRowsValue * 24
    let accumulated = 0

    this.fieldGroupTargets.forEach(el => {
      const span = this.#spanOf(el)
      accumulated += span

      if (accumulated > maxSpan) {
        el.hidden = true
      } else {
        el.hidden = false
      }
    })
  }

  // ── Private: 모든 필드 표시 ──
  #showAllFields() {
    if (!this.hasFieldGroupTarget) return

    this.fieldGroupTargets.forEach(el => {
      el.hidden = false
    })
  }

  // ── Private: 요소의 grid span 계산 ──
  // getComputedStyle로 grid-column-end 값에서 span 숫자를 추출합니다.
  #spanOf(el) {
    const style = getComputedStyle(el)
    const gridColumn = style.gridColumnEnd

    // "span 8" 형식에서 숫자 추출
    const match = gridColumn.match(/span\s+(\d+)/)
    if (match) return parseInt(match[1], 10)

    // fallback: 기본 24 (풀 폭)
    return 24
  }

  // ── Private: 버튼 그룹 span 동적 계산 ──
  // 접힌 상태: 보이는 필드 span 합 + 버튼 = 24
  // 펼친 상태: 마지막 행 남은 공간 계산
  #updateButtonSpan() {
    if (!this.hasButtonGroupTarget) return

    // 1. 전체 필드의 span 합산 (펼쳐졌을 때 기준)
    let totalSpan = 0
    let visibleSpan = 0 // 접혔을 때 보이는 span 합산

    if (this.hasFieldGroupTarget) {
      this.fieldGroupTargets.forEach(el => {
        const span = this.#spanOf(el)
        totalSpan += span
        if (!el.hidden) {
          visibleSpan += span
        }
      })
    }

    const rowSpan = 24
    let targetSpan = 0

    if (this.collapsedValue && this.enableCollapseValue) {
      // [접힘 상태]
      // 보이는 필드들의 span 합 + 버튼 = 24 (또는 그 배수 줄바꿈)
      // PRD: "보이는 필드 span 합 + 버튼 = 24"
      // 즉, 버튼은 (24 - visibleSpan % 24) 만큼 차지해야 함.
      const used = visibleSpan % rowSpan
      const remaining = rowSpan - used
      // 만약 remaining이 24라면(딱 떨어지면), 버튼은 24(새 줄) 혹은 0(같이 있기?)
      // 보통 버튼은 최소 span이 필요하므로, 공간 없으면 다음 줄로 감.
      // 여기서는 "남은 공간"을 채우도록 설정.
      targetSpan = (remaining === 0) ? 24 : remaining
    } else {
      // [펼침 상태]
      // 마지막 행 남은 공간 계산
      const used = totalSpan % rowSpan
      const remaining = rowSpan - used
      targetSpan = (remaining === 0) ? 24 : remaining
    }

    // 최소 4칸 이상 확보 (UX)
    if (targetSpan < 4) targetSpan = 24

    this.buttonGroupTarget.style.gridColumn = `span ${targetSpan}`
  }

  // ── Private: 접기/펼치기 버튼 텍스트 업데이트 ──
  #updateCollapseButton(isCollapsed) {
    if (this.hasCollapseBtnTarget) {
      this.collapseBtnTarget.setAttribute("aria-expanded", String(!isCollapsed))
    }
    if (this.hasCollapseBtnTextTarget) {
      this.collapseBtnTextTarget.textContent = isCollapsed ? "펼치기" : "접기"
    }
    if (this.hasCollapseBtnIconTarget) {
      this.collapseBtnIconTarget.textContent = isCollapsed ? "▼" : "▲"
    }
  }
}
