import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    tabsEndpoint: { type: String, default: "/tabs" }
  }

  openTab(event) {
    event.preventDefault()
    const { tabId, label, url } = event.currentTarget.dataset

    this.requestTurboStream("POST", this.tabsEndpointValue, {
      tab: { id: tabId, label, url }
    }).then(() => this.syncUI(tabId))
  }

  activateTab(event) {
    const tabId = event.currentTarget.dataset.tabId
    if (event.currentTarget.classList.contains("active")) return

    this.requestTurboStream("POST", `${this.tabsEndpointValue}/${tabId}/activation`)
      .then(() => this.syncUI(tabId))
  }

  closeTab(event) {
    const tabId = event.currentTarget.dataset.tabId
    this.requestTurboStream("DELETE", `${this.tabsEndpointValue}/${tabId}`)
      .then(() => this.syncUIFromActiveTab())
  }

  toggleSidebar() {
    this.element.classList.toggle("sidebar-collapsed")
  }

  requestTurboStream(method, url, body = null) {
    const headers = {
      "X-CSRF-Token": this.csrfToken,
      Accept: "text/vnd.turbo-stream.html"
    }
    const options = { method, headers }

    if (body) {
      headers["Content-Type"] = "application/json"
      options.body = JSON.stringify(body)
    }

    return fetch(url, options)
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.text()
      })
      .then((html) => {
        Turbo.renderStreamMessage(html)
      })
      .catch((error) => {
        console.error("[tabs]", error)
        throw error
      })
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  syncUI(tabId) {
    this.updateSidebarActive(tabId)
    const button = document.querySelector(`[data-role='sidebar-menu-item'][data-tab-id='${tabId}']`)
    this.updateBreadcrumb(button?.dataset?.label)
  }

  syncUIFromActiveTab() {
    queueMicrotask(() => {
      const activeTab = document.querySelector(".tab-item.active")
      const tabId = activeTab?.dataset?.tabId
      if (tabId) this.updateSidebarActive(tabId)
    })
  }

  updateSidebarActive(tabId) {
    document.querySelectorAll("[data-role='sidebar-menu-item']").forEach((button) => {
      button.classList.toggle("active", button.dataset.tabId === tabId)
    })
  }

  updateBreadcrumb(label) {
    const element = document.getElementById("breadcrumb-current")
    if (element && label) element.textContent = label
  }
}
