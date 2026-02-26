/**
 * ui_utils.js
 * 
 * UI 관련 공통 유틸리티 함수 모음
 */

/**
 * 탭 전환 처리 (클릭 이벤트 핸들러)
 * @param {Event} event - 클릭 이벤트 객체
 * @param {Controller} controller - Stimulus 컨트롤러 인스턴스 (this)
 */
export function switchTab(event, controller) {
    event.preventDefault()
    const tab = event.currentTarget?.dataset?.tab
    if (!tab) return

    activateTab(tab, controller)
}

/**
 * 탭 활성화 처리
 * @param {string} tab - 활성화할 탭 이름
 * @param {Controller} controller - Stimulus 컨트롤러 인스턴스 (this)
 */
export function activateTab(tab, controller) {
    controller.activeTab = tab

    if (controller.hasTabButtonTarget || controller.tabButtonTargets) {
        controller.tabButtonTargets.forEach((button) => {
            const isActive = button.dataset.tab === tab
            button.classList.toggle("is-active", isActive)
            button.setAttribute("aria-selected", isActive ? "true" : "false")
        })
    }

    if (controller.hasTabPanelTarget || controller.tabPanelTargets) {
        controller.tabPanelTargets.forEach((panel) => {
            const isActive = panel.dataset.tabPanel === tab
            panel.classList.toggle("is-active", isActive)
            panel.classList.toggle("hidden", !isActive)
            panel.hidden = !isActive
        })
    }
}
