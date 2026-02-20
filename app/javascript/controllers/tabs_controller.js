import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["contextMenu", "menuToggle"]
  static values = {
    tabsEndpoint: { type: String, default: "/tabs" },
    maxOpenTabs: { type: Number, default: 10 }
  }

  connect() {
    this.contextTabId = null
    this.boundDocumentClick = this.handleDocumentClick.bind(this)
    this.boundDocumentKeydown = this.handleDocumentKeydown.bind(this)
    document.addEventListener("click", this.boundDocumentClick, true)
    document.addEventListener("keydown", this.boundDocumentKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.boundDocumentClick, true)
    document.removeEventListener("keydown", this.boundDocumentKeydown)
  }

  openTab(event) {
    event.preventDefault()
    const { tabId, label, url } = event.currentTarget.dataset
    const isAlreadyOpen = this.tabIds.includes(tabId)

    if (!isAlreadyOpen && this.tabIds.length >= this.maxOpenTabsValue) {
      console.warn(`[tabs] maximum open tabs (${this.maxOpenTabsValue}) reached`)
      return
    }

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

  openContextMenu(event) {
    event.preventDefault()
    const tabId = event.currentTarget.dataset.tabId
    this.showContextMenu(tabId, { x: event.clientX, y: event.clientY })
  }

  openActionsMenu(event) {
    event.preventDefault()
    const activeTabId = this.activeTabId || "overview"

    if (this.isContextMenuVisible() && this.contextMenuTarget.classList.contains("is-anchor")) {
      this.hideContextMenu()
      return
    }

    this.showContextMenu(activeTabId, { anchor: event.currentTarget })
  }

  closeAllTabs(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    this.hideContextMenu()
    this.requestTurboStream("DELETE", `${this.tabsEndpointValue}/close_all`)
      .then(() => this.syncUI("overview"))
  }

  closeOtherTabs(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    const tabId = this.currentContextTabId
    this.hideContextMenu()
    this.requestTurboStream("DELETE", `${this.tabsEndpointValue}/close_others?id=${encodeURIComponent(tabId)}`)
      .then(() => this.syncUI(tabId))
  }

  moveTabLeft(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    const tabId = this.currentContextTabId
    this.hideContextMenu()
    this.requestTurboStream("PATCH", `${this.tabsEndpointValue}/${encodeURIComponent(tabId)}/move_left`)
      .then(() => this.syncUIFromActiveTab())
  }

  moveTabRight(event) {
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    const tabId = this.currentContextTabId
    this.hideContextMenu()
    this.requestTurboStream("PATCH", `${this.tabsEndpointValue}/${encodeURIComponent(tabId)}/move_right`)
      .then(() => this.syncUIFromActiveTab())
  }

  handleMenuItemKeydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    if (this.isMenuItemDisabled(event.currentTarget)) return

    event.preventDefault()
    event.currentTarget.click()
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
      if (tabId) {
        this.updateSidebarActive(tabId)
        this.updateBreadcrumb(activeTab?.dataset?.tabLabel)
      }
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

  get activeTabId() {
    return document.querySelector(".tab-item.active")?.dataset?.tabId
  }

  get currentContextTabId() {
    if (this.contextTabId) {
      return this.contextTabId
    }
    return this.activeTabId || "overview"
  }

  showContextMenu(tabId, options = {}) {
    if (!this.hasContextMenuTarget) return

    this.contextTabId = tabId
    this.syncContextMenuState(tabId)
    this.contextMenuTarget.classList.add("is-open")

    if (options.anchor) {
      this.positionContextMenuAsAnchor()
      return
    }

    this.contextMenuTarget.classList.remove("is-anchor")
    this.positionContextMenuByPoint(options.x, options.y)
  }

  hideContextMenu() {
    if (!this.hasContextMenuTarget) return

    this.contextMenuTarget.classList.remove("is-open")
    this.contextMenuTarget.classList.remove("is-anchor")
    this.contextMenuTarget.style.left = ""
    this.contextMenuTarget.style.top = ""
    this.contextTabId = null
  }

  positionContextMenuByPoint(x = 0, y = 0) {
    const menu = this.contextMenuTarget
    const viewportPadding = 8
    const width = menu.offsetWidth
    const height = menu.offsetHeight
    const left = Math.max(viewportPadding, Math.min(x, window.innerWidth - width - viewportPadding))
    const top = Math.max(viewportPadding, Math.min(y, window.innerHeight - height - viewportPadding))
    menu.style.left = `${left}px`
    menu.style.top = `${top}px`
  }

  positionContextMenuAsAnchor() {
    this.contextMenuTarget.classList.add("is-anchor")
    this.contextMenuTarget.style.left = ""
    this.contextMenuTarget.style.top = ""
  }

  syncContextMenuState(tabId) {
    const tabIds = this.tabIds
    const index = tabIds.indexOf(tabId)
    const hasOtherClosableTabs = tabIds.some((id) => id !== "overview" && id !== tabId)
    const canMoveLeft = index > 1
    const canMoveRight = index >= 1 && index < tabIds.length - 1

    this.toggleMenuAction("close-all", false)
    this.toggleMenuAction("close-others", !hasOtherClosableTabs)
    this.toggleMenuAction("move-left", !canMoveLeft)
    this.toggleMenuAction("move-right", !canMoveRight)
  }

  toggleMenuAction(actionName, disabled) {
    if (!this.hasContextMenuTarget) return

    const action = this.contextMenuTarget.querySelector(`[data-menu-action='${actionName}']`)
    if (!action) return

    action.classList.toggle("is-disabled", disabled)
    action.setAttribute("aria-disabled", disabled ? "true" : "false")
    action.setAttribute("tabindex", disabled ? "-1" : "0")
  }

  get tabIds() {
    return Array.from(document.querySelectorAll(".tab-item")).map((tab) => tab.dataset.tabId)
  }

  handleDocumentClick(event) {
    if (!this.hasContextMenuTarget || !this.contextMenuTarget.classList.contains("is-open")) return

    const clickedOnMenu = this.contextMenuTarget.contains(event.target)
    const clickedOnToggle = this.hasMenuToggleTarget && this.menuToggleTarget.contains(event.target)
    if (!clickedOnMenu && !clickedOnToggle) {
      this.hideContextMenu()
    }
  }

  handleDocumentKeydown(event) {
    if (event.key === "Escape") {
      this.hideContextMenu()
    }
  }

  isContextMenuVisible() {
    return this.hasContextMenuTarget && this.contextMenuTarget.classList.contains("is-open")
  }

  isMenuItemDisabled(element) {
    if (!element) return false
    return element.classList.contains("is-disabled") || element.getAttribute("aria-disabled") === "true"
  }
}
