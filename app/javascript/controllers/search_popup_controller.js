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

    const selection = await openLookupPopup({
      type: this.typeValue,
      url: this.urlValue,
      keyword: this.seedKeyword,
      title: this.titleValue
    })

    if (selection) {
      this.select(selection)
    }
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

  select({ code, name, display }) {
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
  }
}
