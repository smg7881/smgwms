/**
 * ExcelDownloadable
 *
 * Stimulus 컨트롤러에 엑셀 다운로드/업로드 기능을 추가하는 믹스인입니다.
 * BaseCrudController 와 BaseGridController 양쪽에 동일하게 적용되어
 * Excel 공통 메서드를 단일 표준으로 관리합니다.
 *
 * 적용 방법:
 *   import { ExcelDownloadable } from "controllers/concerns/excel_downloadable"
 *   Object.assign(MyController.prototype, ExcelDownloadable)
 *
 * 컨트롤러 static values에 반드시 포함해야 할 항목 (사용 기능에 따라 선택):
 *   - importHistoryUrl : 업로드 이력 페이지 URL
 *
 * HTML 마크업 예시:
 *   data-[identifier]-import-history-url-value="/system/excel_import_tasks"
 *   data-excel-import-input (파일 input 요소에 지정)
 */
export const ExcelDownloadable = {
  // 업로드(Import) 처리 내역/이력을 보는 페이지로 이동합니다.
  openImportHistory() {
    if (this.hasImportHistoryUrlValue) {
      window.location.href = this.importHistoryUrlValue
    }
  },

  // 엑셀 업로드 팝업: 숨겨진 <input type="file" data-excel-import-input> 요소를 클릭합니다.
  openExcelImport() {
    const fileInput = this.element.querySelector("[data-excel-import-input]")
    if (fileInput) {
      fileInput.click()
    }
  },

  // 파일 선택 완료 즉시 업로드 form을 submit합니다.
  submitExcelImport(event) {
    const input = event.target
    if (input.files.length === 0) return

    const form = input.closest("form")
    form?.requestSubmit()
    input.value = ""
  }
}
