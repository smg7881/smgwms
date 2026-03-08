import { Controller } from "@hotwired/stimulus"
import { openLookupPopup } from "controllers/lookup_popup_modal"
import { getSearchFormValue } from "controllers/grid/core/search_form_bridge"

export default class extends Controller {
  static targets = ["code", "codeDisplay", "display"]

  static values = {
    type: String,
    url: String,
    title: String,
    contextFields: String
  }

  async open(event) {
    if (event) {
      event.preventDefault()
    }

    const directSelection = await this.fetchSingleMatch()
    if (directSelection) {
      this.select(directSelection)
      return
    }

    let selection = null
    let lookupOpened = false
    try {
      lookupOpened = true
      this.element.dispatchEvent(new CustomEvent("search-popup:opening", { bubbles: true }))
      selection = await openLookupPopup({
        type: this.typeValue,
        url: this.buildRequestUrl().toString(),
        keyword: this.seedKeyword,
        title: this.titleValue
      })
    } catch (error) {
      console.error("[search-popup] failed to open lookup modal", error)
      this.openFallbackWindow()
      return
    } finally {
      if (lookupOpened) {
        this.element.dispatchEvent(new CustomEvent("search-popup:closed", { bubbles: true }))
      }
    }

    if (selection) {
      this.select(selection)
    }
  }

  openFallbackWindow() {
    const popupType = String(this.typeValue || "").trim()
    if (!popupType) return

    const url = this.buildRequestUrl({ includeKeyword: true })

    window.open(url.toString(), "lookup_popup_window", "width=980,height=700,left=60,top=40,resizable=yes,scrollbars=yes")
  }

  async fetchSingleMatch() {
    const popupType = String(this.typeValue || "").trim()
    const keyword = this.seedKeyword
    if (!popupType || !keyword) return null

    const url = this.buildRequestUrl({ includeKeyword: true, includeJsonFormat: true })

    try {
      const response = await fetch(url.toString(), { headers: { Accept: "application/json" } })
      if (!response.ok) return null

      const rows = await response.json()
      if (!Array.isArray(rows) || rows.length !== 1) return null

      const row = rows[0] || {}
      const code = String(row.code ?? row.corp_cd ?? row.fnc_or_cd ?? "").trim()
      const name = String(row.name ?? row.corp_nm ?? row.fnc_or_nm ?? row.display ?? "").trim()
      if (!code && !name) return null

      return {
        ...row,
        code,
        name,
        display: name
      }
    } catch {
      return null
    }
  }

  buildRequestUrl({ includeKeyword = false, includeJsonFormat = false } = {}) {
    const popupType = String(this.typeValue || "").trim()
    const baseUrl = String(this.urlValue || "").trim() || `/search_popups/${encodeURIComponent(popupType)}`
    const url = new URL(baseUrl, window.location.origin)

    if (includeKeyword) {
      const keyword = this.seedKeyword
      if (keyword) {
        url.searchParams.set("q", keyword)
      } else {
        url.searchParams.delete("q")
      }
    }

    if (includeJsonFormat) {
      url.searchParams.set("format", "json")
    }

    this.contextFieldNames.forEach((fieldName) => {
      const value = this.readContextValue(fieldName)
      if (value) {
        url.searchParams.set(fieldName, value)
      } else {
        url.searchParams.delete(fieldName)
      }
    })

    return url
  }

  get contextFieldNames() {
    const rawValue = String(this.contextFieldsValue || "").trim()
    if (!rawValue) return []

    return rawValue
      .split(",")
      .map((fieldName) => fieldName.trim())
      .filter((fieldName) => fieldName.length > 0)
  }

  readContextValue(fieldName) {
    return getSearchFormValue(this.application, fieldName, {
      toUpperCase: true,
      fieldElement: this.element
    })
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
