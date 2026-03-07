/**
 * ExcelDownloadable
 *
 * Stimulus 컨트롤러에 엑셀 업로드/이력 조회 기능을 추가하는 믹스인입니다.
 *
 * 적용 방법:
 *   import { ExcelDownloadable } from "controllers/concerns/excel_downloadable"
 *   Object.assign(MyController.prototype, ExcelDownloadable)
 *
 * 컨트롤러 static values에 반드시 포함해야 할 항목:
 *   - importHistoryUrl: String
 *
 * HTML 연결 예시:
 *   data-action="click->my-grid#openExcelImport"
 *   data-action="change->my-grid#submitExcelImport" data-excel-import-input
 */
export const ExcelDownloadable = {
  openImportHistory() {
    if (this.hasImportHistoryUrlValue) {
      window.location.href = this.importHistoryUrlValue
    }
  },

  openExcelImport() {
    const fileInput = this.element.querySelector("[data-excel-import-input]")
    if (fileInput) {
      fileInput.click()
    }
  },

  submitExcelImport(event) {
    const input = event.target
    if (input.files.length === 0) return

    const form = input.closest("form")
    form?.requestSubmit()
    input.value = ""
  }
}
