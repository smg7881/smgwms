import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = []
  static values = {}

  // 라이프사이클
  connect() {}

  // 액션
  // 사이드바 메뉴 클릭 → 탭 열기
  // POST /tabs → Turbo Stream(탭바 update + main-content replace)
  openTab(event) {
    event.preventDefault()

    const { tabId, label, url } = event.currentTarget.dataset

    this.#turboStreamRequest("POST", "/tabs", {
      tab: { id: tabId, label, url }
    }).then(() => {
      this.#syncUI(tabId)
    })
  }

  // 탭 클릭 → 활성 탭 전환
  // POST /tabs/:tab_id/activation
  activateTab(event) {
    const tabId = event.currentTarget.dataset.tabId

    if (event.currentTarget.classList.contains("active")) return

    this.#turboStreamRequest("POST", `/tabs/${tabId}/activation`)
      .then(() => {
        this.#syncUI(tabId)
      })
  }

  // 탭 닫기 (✕ 버튼)
  // DELETE /tabs/:tab_id
  // data-action="click->tabs#closeTab:stop" 에서 :stop이 stopPropagation 역할
  closeTab(event) {
    const tabId = event.currentTarget.dataset.tabId
    this.#turboStreamRequest("DELETE", `/tabs/${tabId}`)
      .then(() => {
        this.#syncUIFromActiveTab()
      })
  }

  // 사이드바 토글
  toggleSidebar() {
    this.element.classList.toggle("sidebar-collapsed")
  }

  // 프라이빗
  #turboStreamRequest(method, url, body = null) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const headers = {
      "X-CSRF-Token": csrfToken,
      "Accept": "text/vnd.turbo-stream.html"
    }

    const options = { method, headers }

    if (body) {
      headers["Content-Type"] = "application/json"
      options.body = JSON.stringify(body)
    }

    return fetch(url, options)
      .then(response => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.text()
      })
      .then(html => {
        Turbo.renderStreamMessage(html)
      })
      .catch(error => {
        console.error("[tabs]", error)
        throw error
      })
  }

  #updateSidebarActive(tabId) {
    document.querySelectorAll("[data-role='sidebar-menu-item']").forEach(btn => {
      btn.classList.toggle("active", btn.dataset.tabId === tabId)
    })
  }

  #updateBreadcrumb(label) {
    const el = document.getElementById("breadcrumb-current")
    if (el && label) el.textContent = label
  }

  #syncUI(tabId) {
    this.#updateSidebarActive(tabId)
    const btn = document.querySelector(`[data-role='sidebar-menu-item'][data-tab-id='${tabId}']`)
    this.#updateBreadcrumb(btn?.dataset?.label)
  }

  #syncUIFromActiveTab() {
    queueMicrotask(() => {
      const activeTab = document.querySelector(".tab-item.active")
      const tabId = activeTab?.dataset?.tabId
      if (tabId) this.#updateSidebarActive(tabId)
    })
  }
}
