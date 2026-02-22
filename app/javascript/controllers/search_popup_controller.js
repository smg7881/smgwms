import { Controller } from "@hotwired/stimulus"
import { openLookupPopup } from "controllers/lookup_popup_modal"

export default class extends Controller {
  static targets = ["code", "codeDisplay", "display"]

  static values = {
    type: String,
    url: String,
    title: String
  }

  async open(event) {
    if (event) {
      event.preventDefault()
    }

    let selection = null
    try {
      selection = await openLookupPopup({
        type: this.typeValue,
        url: this.urlValue,
        keyword: this.seedKeyword,
        title: this.titleValue
      })
    } catch (error) {
      console.error("[search-popup] failed to open lookup modal", error)
      this.openFallbackWindow()
      return
    }

    if (selection) {
      this.select(selection)
    }
  }

  openFallbackWindow() {
    const popupType = String(this.typeValue || "").trim()
    if (!popupType) return

    const baseUrl = String(this.urlValue || "").trim() || `/search_popups/${encodeURIComponent(popupType)}`
    const url = new URL(baseUrl, window.location.origin)
    const keyword = this.seedKeyword
    if (keyword) {
      url.searchParams.set("q", keyword)
    }

    window.open(url.toString(), "lookup_popup_window", "width=980,height=700,left=60,top=40,resizable=yes,scrollbars=yes")
  }

  onDisplayInput() {
    this.clearCode()
  }

  clearCode() {
    if (this.hasCodeTarget) {
      this.codeTarget.value = ""
      this.codeTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    if (this.hasCodeDisplayTarget) {
      this.codeDisplayTarget.value = ""
    }
  }

  get seedKeyword() {
    const displayValue = this.hasDisplayTarget ? this.displayTarget.value.toString().trim() : ""
    if (displayValue.length > 0) {
      return displayValue
    }

    const codeValue = this.hasCodeTarget ? this.codeTarget.value.toString().trim() : ""
    return codeValue
  }

  select(selection) {
    const { code, name, display } = selection || {}
    const resolvedCode = String(code ?? "").trim()
    const resolvedDisplay = String(name ?? display ?? "").trim()

    if (this.hasCodeTarget) {
      this.codeTarget.value = resolvedCode
      this.codeTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    if (this.hasCodeDisplayTarget) {
      this.codeDisplayTarget.value = resolvedCode
    }

    if (this.hasDisplayTarget) {
      this.displayTarget.value = resolvedDisplay
      this.displayTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    this.element.dispatchEvent(new CustomEvent("search-popup:selected", {
      bubbles: true,
      detail: selection || {}
    }))
  }
}
