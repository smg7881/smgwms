import { Controller } from "@hotwired/stimulus"
import { resolveAgGridRegistration } from "controllers/grid/grid_event_manager"
import { isApiAlive, getCsrfToken, fetchJson, setGridRowData } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = [
    "regionCodeInput",
    "regionDisplayInput",
    "countryCodeInput",
    "countryDisplayInput",
    "zipcdInput",
    "zipaddrInput",
    "mappedGrid",
    "unmappedGrid"
  ]

  static values = {
    mappedUrl: String,
    unmappedUrl: String,
    saveUrl: String
  }

  connect() {
    this.mappedApi = null
    this.unmappedApi = null
    this.mappedRows = []
    this.unmappedRows = []
  }

  disconnect() {
    this.mappedApi = null
    this.unmappedApi = null
  }

  registerGrid(event) {
    const registration = resolveAgGridRegistration(event)
    if (!registration) return

    const { gridElement, api } = registration
    if (gridElement === this.mappedGridTarget) {
      this.mappedApi = api
    } else if (gridElement === this.unmappedGridTarget) {
      this.unmappedApi = api
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
      const query = new URLSearchParams({ regn_cd: this.currentRegionCode })
      this.mappedRows = await fetchJson(`${this.mappedUrlValue}?${query.toString()}`)
      this.rebuildMappedSortOrder()
      this.render()
    } catch {
      alert("할당 우편번호 조회에 실패했습니다.")
    }
  }

  async searchUnmapped() {
    if (!isApiAlive(this.unmappedApi)) return

    if (!this.currentRegionCode) {
      alert("권역을 먼저 선택해 주세요.")
      return
    }

    try {
      const query = new URLSearchParams({
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
      alert("미할당 우편번호 조회에 실패했습니다.")
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
      alert("권역을 먼저 선택해 주세요.")
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
          regn_cd: this.currentRegionCode,
          rows: rows
        })
      })

      const result = await response.json()
      if (!response.ok || !result.success) {
        alert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
        return
      }

      alert(result.message || "저장이 완료되었습니다.")
      await Promise.all([this.searchMapped(), this.searchUnmapped()])
    } catch {
      alert("저장 실패: 네트워크 오류")
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
    return `${row.ctry_cd}::${row.zipcd}::${row.seq_no}`
  }

  get currentRegionCode() {
    return this.regionCodeInputTarget?.value?.toString().trim().toUpperCase() || ""
  }

  get currentCountryCode() {
    return this.countryCodeInputTarget?.value?.toString().trim().toUpperCase() || ""
  }

  get currentZipCode() {
    return this.zipcdInputTarget?.value?.toString().trim().toUpperCase() || ""
  }

  get currentZipAddress() {
    return this.zipaddrInputTarget?.value?.toString().trim() || ""
  }
}
