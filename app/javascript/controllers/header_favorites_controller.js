import { Controller } from "@hotwired/stimulus"
import { fetchJson } from "controllers/grid/grid_utils"

export default class extends Controller {
    static targets = ["popup", "groupSelect", "menuList"]
    static values = {
        url: String,
        groupsUrl: String
    }

    connect() {
        this.groups = []
        this.favorites = []

        // Close popup on outside click
        this.boundHandleClickOutside = this.handleClickOutside.bind(this)
        document.addEventListener("click", this.boundHandleClickOutside)
    }

    disconnect() {
        document.removeEventListener("click", this.boundHandleClickOutside)
    }

    async toggle() {
        const isHidden = this.popupTarget.classList.contains("hidden")

        if (isHidden) {
            await this.loadData()
            this.popupTarget.classList.remove("hidden")
        } else {
            this.popupTarget.classList.add("hidden")
        }
    }

    handleClickOutside(event) {
        // Don't close if clicking the toggle button or inside the popup itself
        if (this.element.contains(event.target)) {
            return
        }
        this.popupTarget.classList.add("hidden")
    }

    async loadData() {
        try {
            // Fetch user groups
            this.groups = await fetchJson(this.groupsUrlValue)

            // Update select options
            this.groupSelectTarget.innerHTML = '<option value="">즐겨찾기 그룹 선택</option>'
            this.groups.forEach(group => {
                if (group.use_yn === 'Y' && !group.__is_deleted) {
                    const option = document.createElement('option')
                    option.value = group.group_nm
                    option.textContent = group.group_nm
                    this.groupSelectTarget.appendChild(option)
                }
            })

            // Select the first group if available
            if (this.groupSelectTarget.options.length > 1) {
                this.groupSelectTarget.options[1].selected = true
            }

            // Fetch user favorites
            this.favorites = await fetchJson(this.urlValue)

            this.renderMenus()
        } catch (e) {
            console.error("Failed to load favorites data", e)
        }
    }

    renderMenus() {
        const selectedGroup = this.groupSelectTarget.value
        this.menuListTarget.innerHTML = ''

        if (!selectedGroup) {
            this.menuListTarget.innerHTML = '<div class="text-xs text-text-muted p-2 text-center">그룹을 선택해주세요.</div>'
            return
        }

        // Filter active favorites for the selected group
        const groupFavs = this.favorites.filter(f =>
            f.user_favor_menu_grp === selectedGroup && f.use_yn === 'Y'
        )

        if (groupFavs.length === 0) {
            this.menuListTarget.innerHTML = '<div class="text-xs text-text-muted p-2 text-center">즐겨찾기 메뉴가 없습니다.</div>'
            return
        }

        // Render as a grid mega-menu (Sitemap style) - Force 3 columns natively
        const listWrapper = document.createElement("div")
        listWrapper.className = "grid grid-cols-3 gap-x-8 gap-y-6"

        // Group the favorites by parent menu name
        const groupedFavs = groupFavs.reduce((acc, fav) => {
            const category = fav.up_menu_nm || "기타"
            if (!acc[category]) acc[category] = []
            acc[category].push(fav)
            return acc
        }, {})

        // Sort categories if necessary, and then render them
        Object.entries(groupedFavs).forEach(([category, favs]) => {
            const groupDiv = document.createElement("div")
            groupDiv.className = "flex flex-col gap-1.5"

            // Category Header
            groupDiv.innerHTML = `<div class="text-[13px] font-bold text-text-secondary border-b border-border pb-1.5 mb-2">${category}</div>`

            // Category Items
            favs.forEach(fav => {
                const btn = document.createElement("button")
                btn.type = "button"
                btn.className = "flex items-center gap-2 px-2 py-1.5 hover:bg-bg-hover rounded transition-colors text-left w-full text-text-primary group"
                btn.dataset.action = "click->header-favorites#openMenu"
                btn.dataset.menuCd = fav.menu_cd
                btn.dataset.menuNm = fav.menu_nm
                btn.dataset.tabId = fav.tab_id || fav.menu_cd
                btn.dataset.url = fav.menu_url || ""

                btn.innerHTML = `
                    <div class="flex items-center justify-center shrink-0" style="width: 14px; height: 14px;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-text-muted transition-colors group-hover:text-blue-500"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                    </div>
                    <span class="flex-1 text-[13px] font-medium transition-colors group-hover:text-blue-500" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${fav.menu_nm}</span>
                `
                groupDiv.appendChild(btn)
            })
            listWrapper.appendChild(groupDiv)
        })

        this.menuListTarget.appendChild(listWrapper)
    }

    openMenu(event) {
        const btn = event.currentTarget
        const tabId = btn.dataset.tabId
        const menuUrl = btn.dataset.url
        const menuNm = btn.dataset.menuNm

        // Try to trigger the sidebar click if element exists
        const sidebarBtn = document.querySelector(`[data-tab-id="${tabId}"]`)

        // Hide popup first for better UX
        this.popupTarget.classList.add("hidden")

        if (sidebarBtn) {
            sidebarBtn.click()
        } else if (menuUrl) {
            const tabGroup = document.querySelector('[data-controller~="tabs"]')
            if (tabGroup) {
                // If using a tabs controller for navigation 
                const tabsCtrl = this.application.getControllerForElementAndIdentifier(tabGroup, 'tabs')
                if (tabsCtrl && typeof tabsCtrl.openTab === 'function') {
                    const fakeEvent = {
                        preventDefault: () => { },
                        currentTarget: {
                            dataset: {
                                tabId: tabId,
                                label: menuNm,
                                url: menuUrl
                            }
                        }
                    }
                    tabsCtrl.openTab(fakeEvent)
                } else {
                    window.location.href = menuUrl
                }
            } else {
                window.location.href = menuUrl
            }
        }

    }
}
