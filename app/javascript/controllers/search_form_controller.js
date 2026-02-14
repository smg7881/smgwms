import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "fieldGroup",
    "collapseBtn",
    "collapseBtnText",
    "collapseBtnIcon",
    "buttonGroup"
  ]

  static values = {
    collapsed: { type: Boolean, default: true },
    loading: { type: Boolean, default: false },
    collapsedRows: { type: Number, default: 1 },
    cols: { type: Number, default: 3 },
    enableCollapse: { type: Boolean, default: true }
  }

  connect() {
    if (!this.enableCollapseValue) {
      this.collapsedValue = false
    }

    this._resizeObserver = new ResizeObserver(() => {
      if (this.collapsedValue && this.enableCollapseValue) {
        this.#applyCollapse()
      }
    })
    this._resizeObserver.observe(this.element)

    this.collapsedValueChanged()
  }

  disconnect() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect()
      this._resizeObserver = null
    }
  }

  search(event) {
    event.preventDefault()

    if (!this.formTarget.checkValidity()) {
      this.formTarget.reportValidity()
      return
    }

    this.formTarget.requestSubmit()
  }

  reset(event) {
    event.preventDefault()

    this.formTarget.reset()

    const baseUrl = this.formTarget.action.split("?")[0]
    const turboFrame = this.formTarget.dataset.turboFrame

    if (turboFrame && window.Turbo) {
      Turbo.visit(baseUrl, { frame: turboFrame })
    } else {
      window.location.href = baseUrl
    }
  }

  toggleCollapse(event) {
    event.preventDefault()
    this.collapsedValue = !this.collapsedValue
  }

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

  #showAllFields() {
    if (!this.hasFieldGroupTarget) return

    this.fieldGroupTargets.forEach(el => {
      el.hidden = false
    })
  }

  #spanOf(el) {
    const style = getComputedStyle(el)
    const gridColumn = style.gridColumnEnd

    const match = gridColumn.match(/span\s+(\d+)/)
    if (match) return parseInt(match[1], 10)

    return 24
  }

  #updateButtonSpan() {
    if (!this.hasButtonGroupTarget) return

    let totalSpan = 0
    let visibleSpan = 0

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
      const used = visibleSpan % rowSpan
      const remaining = rowSpan - used
      targetSpan = (remaining === 0) ? 24 : remaining
    } else {
      const used = totalSpan % rowSpan
      const remaining = rowSpan - used
      targetSpan = (remaining === 0) ? 24 : remaining
    }

    if (targetSpan < 4) targetSpan = 24

    this.buttonGroupTarget.style.gridColumn = `span ${targetSpan}`
  }

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
