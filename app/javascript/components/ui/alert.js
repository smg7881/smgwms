/**
 * UI Alert / Confirm 유틸리티
 *
 * showAlert  : 알림 메시지 표시 (브라우저 alert 래퍼)
 * confirmAction : 확인/취소 대화상자 (브라우저 confirm 래퍼)
 *
 * 추후 SweetAlert2 등 UI 라이브러리로 교체할 경우 이 파일만 수정하면 됩니다.
 */

/**
 * 알림 메시지를 표시합니다.
 * @param {string} title   - 제목 (예: "Warning", "Error", "Success", "Info")
 * @param {string} message - 표시할 메시지
 * @param {string} type    - 메시지 유형: "success" | "error" | "warning" | "info"
 */
export function showAlert(title, message, type = "info") {
    // 제목과 메시지를 합쳐서 표시
    const prefix = title ? `[${title}] ` : ""
    window.alert(`${prefix}${message}`)
}

/**
 * 확인/취소 대화상자를 표시하고 사용자의 선택을 Promise로 반환합니다.
 * @param {string} title   - 제목
 * @param {string} message - 표시할 메시지
 * @returns {Promise<boolean>} 확인 시 true, 취소 시 false
 */
export function confirmAction(title, message) {
    const prefix = title ? `[${title}] ` : ""
    const result = window.confirm(`${prefix}${message}`)
    return Promise.resolve(result)
}
