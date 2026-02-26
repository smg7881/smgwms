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
 *
 * 호출 방식:
 *   showAlert("메시지")                          → window.alert("메시지")
 *   showAlert("제목", "메시지")                  → window.alert("[제목] 메시지")
 *   showAlert("제목", "메시지", "warning")       → window.alert("[제목] 메시지")
 *
 * @param {string} titleOrMessage - 제목 또는 메시지 (두 번째 인자가 없으면 메시지로 처리)
 * @param {string} [message]      - 메시지 (두 번째 인자가 있는 경우)
 * @param {string} [type]         - 메시지 유형: "success" | "error" | "warning" | "info"
 */
export function showAlert(titleOrMessage, message, type = "info") {
    if (message === undefined || message === null) {
        // 단일 인자: showAlert("메시지")
        window.alert(titleOrMessage)
    } else {
        // 두 인자 이상: showAlert("제목", "메시지")
        window.alert(`[${titleOrMessage}] ${message}`)
    }
}

/**
 * 확인/취소 대화상자를 표시하고 사용자의 선택을 Promise로 반환합니다.
 *
 * 호출 방식:
 *   confirmAction("메시지")              → window.confirm("메시지")
 *   confirmAction("제목", "메시지")      → window.confirm("[제목] 메시지")
 *
 * @param {string} titleOrMessage - 제목 또는 메시지
 * @param {string} [message]      - 메시지 (두 번째 인자가 있는 경우)
 * @returns {Promise<boolean>} 확인 시 true, 취소 시 false
 */
export function confirmAction(titleOrMessage, message) {
    let text
    if (message === undefined || message === null) {
        text = titleOrMessage
    } else {
        text = `[${titleOrMessage}] ${message}`
    }
    return Promise.resolve(window.confirm(text))
}
