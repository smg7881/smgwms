import { Controller } from "@hotwired/stimulus"
import { showAlert, confirmAction } from "components/ui/alert"
import { isApiAlive, getCsrfToken, fetchJson, setGridRowData, buildCompositeKey, registerGridInstance } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = [
    "topSearchArea",
    "bottomSearchArea",
    "mappedGrid",
    "unmappedGrid"
  ]

  static values = {
    mappedUrl: String,
    unmappedUrl: String,
    saveUrl: String,
    defaultCorpCode: String,
    defaultCorpName: String,
    defaultCountryCode: String,
    defaultCountryName: String
  }

  connect() {
    this.mappedApi = null
    this.unmappedApi = null
    this.mappedRows = []
    this.unmappedRows = []

    this.bindSearchForms()
    this.applyDefaultSearchValues()
    this.syncRegionPopupUrl()
  }

  disconnect() {
    this.unbindSearchForms()
    this.mappedApi = null
    this.unmappedApi = null
  }

  registerGrid(event) {
    registerGridInstance(event, this, [
      { target: this.hasMappedGridTarget ? this.mappedGridTarget : null, managerKey: "mappedApi" },
      { target: this.hasUnmappedGridTarget ? this.unmappedGridTarget : null, managerKey: "unmappedApi" }
    ])

    // Fallback assignment to ensure the APIs are captured
    const registration = resolveAgGridRegistration(event)
    if (!registration) return
    if (registration.gridElement === this.mappedGridTarget) {
      this.mappedApi = registration.api
    } else if (registration.gridElement === this.unmappedGridTarget) {
      this.unmappedApi = registration.api
    }
  }

  handleConditionChange(event) {
    const name = event?.target?.name
    if (name === "q[corp_cd]") {
      this.onCorpChange()
      return
    }
    if (name === "q[regn_cd]") {
      this.onRegionChange()
      return
    }
    if (name === "q[ctry_cd]") {
      this.onCountryChange()
    }
  }

  async onRegionChange() {
    if (!this.currentRegionCode) {
      this.mappedRows = []
      this.unmappedRows = []
      this.render()
      return
    }

    await Promise.all([this.searchMapped(), this.searchUnmapped()])
  }

  onCorpChange() {
    this.clearRegionSelection()
    this.mappedRows = []
    this.unmappedRows = []
    this.render()
    this.syncRegionPopupUrl()
  }

  async onCountryChange() {
    if (!this.currentRegionCode) {
      return
    }

    await this.searchUnmapped()
  }

  async searchMapped() {
    if (!isApiAlive(this.mappedApi)) return

    if (!this.currentRegionCode) {
      this.mappedRows = []
      this.render()
      return
    }

    try {
      const query = new URLSearchParams({
        corp_cd: this.currentCorpCode,
        regn_cd: this.currentRegionCode
      })
      this.mappedRows = await fetchJson(`${this.mappedUrlValue}?${query.toString()}`)
      this.rebuildMappedSortOrder()
      this.render()
    } catch {
      showAlert("할당 우편번호 조회에 실패했습니다.")
    }
  }

  async searchUnmapped() {
    if (!isApiAlive(this.unmappedApi)) return

    if (!this.currentRegionCode) {
      showAlert("권역을 먼저 선택해 주세요.")
      return
    }

    try {
      const query = new URLSearchParams({
        corp_cd: this.currentCorpCode,
        regn_cd: this.currentRegionCode,
        ctry_cd: this.currentCountryCode,
        zipcd: this.currentZipCode,
        zipaddr: this.currentZipAddress
      })

      const fetchedRows = await fetchJson(`${this.unmappedUrlValue}?${query.toString()}`)
      const mappedKeySet = new Set(this.mappedRows.map((row) => this.rowKey(row)))
      this.unmappedRows = fetchedRows.filter((row) => !mappedKeySet.has(this.rowKey(row)))
      this.render()
    } catch {
      showAlert("미할당 우편번호 조회에 실패했습니다.")
    }
  }

  moveUp() {
    if (!isApiAlive(this.unmappedApi)) return

    const selectedRows = this.unmappedApi.getSelectedRows()
    if (!selectedRows.length) return

    const selectedKeySet = new Set(selectedRows.map((row) => this.rowKey(row)))
    const existingMappedKeySet = new Set(this.mappedRows.map((row) => this.rowKey(row)))

    selectedRows.forEach((row) => {
      const key = this.rowKey(row)
      if (!existingMappedKeySet.has(key)) {
        this.mappedRows.push(row)
        existingMappedKeySet.add(key)
      }
    })

    this.unmappedRows = this.unmappedRows.filter((row) => !selectedKeySet.has(this.rowKey(row)))
    this.rebuildMappedSortOrder()
    this.render()
  }

  moveDown() {
    if (!isApiAlive(this.mappedApi)) return

    const selectedRows = this.mappedApi.getSelectedRows()
    if (!selectedRows.length) return

    const selectedKeySet = new Set(selectedRows.map((row) => this.rowKey(row)))
    const existingUnmappedKeySet = new Set(this.unmappedRows.map((row) => this.rowKey(row)))

    selectedRows.forEach((row) => {
      const key = this.rowKey(row)
      if (!existingUnmappedKeySet.has(key)) {
        this.unmappedRows.push(row)
        existingUnmappedKeySet.add(key)
      }
    })

    this.mappedRows = this.mappedRows.filter((row) => !selectedKeySet.has(this.rowKey(row)))
    this.rebuildMappedSortOrder()
    this.render()
  }

  async save() {
    if (!this.currentRegionCode) {
      showAlert("권역을 먼저 선택해 주세요.")
      return
    }

    const rows = this.mappedRows.map((row, index) => ({
      ctry_cd: row.ctry_cd,
      zipcd: row.zipcd,
      seq_no: row.seq_no,
      sort_seq: index + 1
    }))

    try {
      const response = await fetch(this.saveUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": getCsrfToken()
        },
        body: JSON.stringify({
          corp_cd: this.currentCorpCode,
          regn_cd: this.currentRegionCode,
          rows: rows
        })
      })

      const result = await response.json()
      if (!response.ok || !result.success) {
        showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      showAlert(result.message || "저장이 완료되었습니다.")
      await Promise.all([this.searchMapped(), this.searchUnmapped()])
    } catch {
      showAlert("저장 실패: 네트워크 오류")
    }
  }

  render() {
    if (isApiAlive(this.mappedApi)) {
      setGridRowData(this.mappedApi, this.mappedRows)
    }
    if (isApiAlive(this.unmappedApi)) {
      setGridRowData(this.unmappedApi, this.unmappedRows)
    }
  }

  rebuildMappedSortOrder() {
    this.mappedRows = this.mappedRows.map((row, index) => ({
      ...row,
      sort_seq: index + 1
    }))
  }

  rowKey(row) {
    return buildCompositeKey([row.ctry_cd, row.zipcd, row.seq_no])
  }

  bindSearchForms() {
    this.topSearchForm = this.topSearchAreaTarget?.querySelector("form")
    this.bottomSearchForm = this.bottomSearchAreaTarget?.querySelector("form")

    this._onTopSubmit = (event) => {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
      this.searchMapped()
    }

    this._onBottomSubmit = (event) => {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
      this.searchUnmapped()
    }

    if (this.topSearchForm) {
      this.topSearchForm.addEventListener("submit", this._onTopSubmit, true)
    }
    if (this.bottomSearchForm) {
      this.bottomSearchForm.addEventListener("submit", this._onBottomSubmit, true)
    }
  }

  unbindSearchForms() {
    if (this.topSearchForm && this._onTopSubmit) {
      this.topSearchForm.removeEventListener("submit", this._onTopSubmit, true)
    }
    if (this.bottomSearchForm && this._onBottomSubmit) {
      this.bottomSearchForm.removeEventListener("submit", this._onBottomSubmit, true)
    }
    this.topSearchForm = null
    this.bottomSearchForm = null
    this._onTopSubmit = null
    this._onBottomSubmit = null
  }

  applyDefaultSearchValues() {
    if (!this.currentCorpCode && this.defaultCorpCodeValue) {
      this.setPopupValues("corp", this.defaultCorpCodeValue, this.defaultCorpNameValue)
    }
    if (!this.currentCountryCode && this.defaultCountryCodeValue) {
      this.setPopupValues("country", this.defaultCountryCodeValue, this.defaultCountryNameValue)
    }
  }

  clearRegionSelection() {
    this.setPopupValues("region", "", "")
  }

  syncRegionPopupUrl() {
    const wrapper = this.popupWrapper("region")
    if (!wrapper) return

    const baseUrl = wrapper.dataset.searchPopupUrlValue?.split("?")[0] || "/search_popups/region"
    const query = new URLSearchParams()
    if (this.currentCorpCode) {
      query.set("corp_cd", this.currentCorpCode)
    }

    const suffix = query.toString()
    wrapper.dataset.searchPopupUrlValue = suffix ? `${baseUrl}?${suffix}` : baseUrl
  }

  popupWrapper(type) {
    return this.element.querySelector(`[data-controller~='search-popup'][data-search-popup-type-value='${type}']`)
  }

  popupCode(type) {
    const wrapper = this.popupWrapper(type)
    if (!wrapper) return ""

    const input = wrapper.querySelector("[data-search-popup-target='code']")
    return input?.value?.toString().trim().toUpperCase() || ""
  }

  setPopupValues(type, code, display) {
    const wrapper = this.popupWrapper(type)
    if (!wrapper) return

    const normalizedCode = String(code || "").trim().toUpperCase()
    const normalizedDisplay = String(display || "").trim()

    const codeInput = wrapper.querySelector("[data-search-popup-target='code']")
    const displayInput = wrapper.querySelector("[data-search-popup-target='display']")
    const codeDisplayInput = wrapper.querySelector("[data-search-popup-target='codeDisplay']")

    if (codeInput) {
      codeInput.value = normalizedCode
    }
    if (displayInput) {
      displayInput.value = normalizedDisplay
    }
    if (codeDisplayInput) {
      codeDisplayInput.value = normalizedCode
    }
  }

  inputValue(name) {
    const input = this.element.querySelector(`[name='${name}']`)
    return input?.value?.toString().trim() || ""
  }

  get currentCorpCode() {
    return this.popupCode("corp")
  }

  get currentRegionCode() {
    return this.popupCode("region")
  }

  get currentCountryCode() {
    return this.popupCode("country")
  }

  get currentZipCode() {
    return this.inputValue("q[zipcd]").toUpperCase()
  }

  get currentZipAddress() {
    return this.inputValue("q[zipaddr]")
  }
}
