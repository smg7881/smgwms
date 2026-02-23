import { Controller } from "@hotwired/stimulus"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { fetchJson, hasChanges, isApiAlive, postJson, setManagerRowData, getSearchFieldValue, focusFirstRow } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = ["groupGrid", "star"]

  static values = {
    listUrl: String,
    batchUrl: String,
    groupListUrl: String,
    groupBatchUrl: String
  }

  connect() {
    this.groupManager = null
    this.userFavorites = []
    this.dirtyFavorites = {}

    this.searchForm = this.element.querySelector("form.search-form")
    this.searchHandler = (e) => {
      e.preventDefault()
      this.reloadGroups()
      this.reloadFavorites()
    }

    if (this.searchForm) {
      this.searchForm.addEventListener("submit", this.searchHandler)
    }
  }

  disconnect() {
    if (this.searchForm) {
      this.searchForm.removeEventListener("submit", this.searchHandler)
    }
    this.groupManager?.detach()
    this.groupManager = null
  }

  registerGrid(event) {
    const { api, controller } = event.detail
    const gridElement = event.target

    if (gridElement === this.groupGridTarget) {
      this.groupManager?.detach()
      this.groupManager = new GridCrudManager(this.groupConfig)
      this.groupManager.attach(api)
      this.reloadGroups()
      this.reloadFavorites()
    }
  }

  // --- Group Grid Methods ---

  addGroupRow() {
    if (!this.groupManager) return
    this.groupManager.addRow({ use_yn: "Y" })
  }

  deleteGroupRows() {
    if (!this.groupManager) return
    this.groupManager.deleteRows()
    this.renderStars()
  }

  async saveGroupRows() {
    if (!this.groupManager) return
    this.groupManager.stopEditing()

    const groupOperations = this.groupManager.buildOperations()
    const favOperations = this.buildFavoriteOperations()

    if (!hasChanges(groupOperations) && !hasChanges(favOperations)) {
      alert("변경된 데이터가 없습니다.")
      return
    }

    if (hasChanges(groupOperations)) {
      const ok = await postJson(this.groupBatchUrlValue, groupOperations)
      if (!ok) return
    }

    if (hasChanges(favOperations)) {
      const ok = await postJson(this.batchUrlValue, favOperations)
      if (!ok) return
    }

    alert("즐겨찾기 그룹 및 메뉴 정보가 저장되었습니다.")
    this.dirtyFavorites = {}
    await this.reloadGroups()
    await this.reloadFavorites()
  }

  get groupConfig() {
    return {
      pkFields: ["group_nm"],
      fields: {
        group_nm: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        group_nm: "",
        use_yn: "Y"
      },
      blankCheckFields: ["group_nm"],
      comparableFields: ["use_yn"],
      firstEditCol: "group_nm",
      pkLabels: { group_nm: "그룹명" }
    }
  }

  getSearchParams() {
    if (this.searchForm) {
      return new URLSearchParams(new FormData(this.searchForm)).toString()
    }
    return ""
  }

  async reloadGroups() {
    if (!isApiAlive(this.groupManager?.api)) return

    const query = this.getSearchParams()
    try {
      const rows = await fetchJson(`${this.groupListUrlValue}?${query}`)
      setManagerRowData(this.groupManager, rows)

      // 데이터가 존재하면 무조건 첫번째 행으로 포커스 및 선택
      const firstRow = focusFirstRow(this.groupManager.api, { select: true, ensureVisible: true })
      this._activeGroup = firstRow
      this.renderStars()
    } catch {
      alert("즐겨찾기 그룹을 불러오지 못했습니다.")
    }
  }

  async reloadFavorites() {
    const query = this.getSearchParams()
    try {
      this.userFavorites = await fetchJson(`${this.listUrlValue}?${query}`)
      this.dirtyFavorites = {}
      this.renderStars()
    } catch {
      alert("즐겨찾기 목록을 재조회하지 못했습니다.")
    }
  }

  // --- Sitemap Star Methods ---

  onGroupSelectionChanged() {
    const selectedRows = this.groupManager?.api?.getSelectedRows() || []
    if (selectedRows.length > 0 && !this._activeGroup) {
      this._activeGroup = selectedRows[0]
    }
    this.renderStars()
  }

  onGroupRowClicked(event) {
    if (event.detail && event.detail.data) {
      this._activeGroup = event.detail.data
    }
    this.renderStars()
  }

  onGroupRowFocused(event) {
    if (event.detail && event.detail.data) {
      this._activeGroup = event.detail.data
    }
    this.renderStars()
  }

  get selectedGroup() {
    if (this._activeGroup && !this._activeGroup.__is_deleted) {
      return this._activeGroup
    }

    const selectedRows = this.groupManager?.api?.getSelectedRows() || []
    return selectedRows.length > 0 ? selectedRows[0] : null
  }

  toggleStar(event) {
    let group = this.selectedGroup

    // Auto-select or auto-create a group if none is selected
    if (!group && this.groupManager?.api) {
      const allRows = []
      this.groupManager.api.forEachNode(node => allRows.push(node))

      const validNodes = allRows.filter(n => {
        const r = n.data
        return r && !r.__is_deleted && r._status !== 'deleted' && r.group_nm && r.group_nm.trim() !== ''
      })

      if (validNodes.length > 0) {
        validNodes[0].setSelected(true)
        group = validNodes[0].data
      } else {
        this.groupManager.addRow({ group_nm: "기본 그룹", use_yn: "Y" })

        let newNode = null
        this.groupManager.api.forEachNode(node => {
          if (node.data && node.data.group_nm === "기본 그룹" && node.data._status === "added") {
            newNode = node
          }
        })

        if (newNode) {
          newNode.setSelected(true)
          group = newNode.data
        }
      }
    }

    if (!group) {
      alert("즐겨찾기 그룹을 생성할 수 없습니다.")
      return
    }

    if (group.__is_deleted || group._status === 'deleted') {
      alert("삭제 중인 그룹에는 메뉴를 추가할 수 없습니다.")
      return
    }

    const groupNm = group.group_nm
    if (!groupNm || groupNm.trim() === '') {
      alert("그룹명을 입력한 뒤에 메뉴를 즐겨찾기 할 수 있습니다.")
      return
    }

    const menuNode = event.currentTarget
    const menuCd = menuNode.dataset.menuCd
    const menuNm = menuNode.dataset.menuNm

    const existingObj = this.getFavState(menuCd)

    if (existingObj && existingObj.use_yn === 'Y') {
      if (existingObj.user_favor_menu_grp === groupNm) {
        this.dirtyFavorites[menuCd] = {
          menu_cd: menuCd,
          menu_nm: menuNm,
          user_favor_menu_grp: groupNm,
          use_yn: 'N',
          sort_seq: parseInt(existingObj.sort_seq) || 0
        }
      } else {
        this.dirtyFavorites[menuCd] = {
          menu_cd: menuCd,
          menu_nm: menuNm,
          user_favor_menu_grp: groupNm,
          use_yn: 'Y',
          sort_seq: parseInt(existingObj.sort_seq) || 0
        }
      }
    } else {
      this.dirtyFavorites[menuCd] = {
        menu_cd: menuCd,
        menu_nm: menuNm,
        user_favor_menu_grp: groupNm,
        use_yn: 'Y',
        sort_seq: parseInt(existingObj?.sort_seq) || 0
      }
    }

    this.renderStars()
  }

  getFavState(menuCd) {
    if (this.dirtyFavorites[menuCd] !== undefined) {
      return this.dirtyFavorites[menuCd]
    }
    const orig = this.userFavorites.find((f) => f.menu_cd === menuCd)
    return orig || null
  }

  renderStars() {
    const group = this.selectedGroup
    const groupNm = group ? group.group_nm : null

    this.starTargets.forEach((starBtn) => {
      const menuNode = starBtn.closest("[data-menu-cd]")
      const menuCd = menuNode.dataset.menuCd
      const favState = this.getFavState(menuCd)
      const textSpan = starBtn.nextElementSibling

      starBtn.classList.remove('text-blue-500', 'fill-blue-500', 'text-gray-500', 'text-text-muted')
      starBtn.style.color = ''
      starBtn.style.fill = ''
      if (textSpan) {
        textSpan.classList.remove('text-blue-500', 'font-bold', 'text-text-secondary', 'font-medium')
        textSpan.style.color = ''
      }

      if (favState && favState.use_yn === 'Y') {
        if (!groupNm || favState.user_favor_menu_grp === groupNm) {
          starBtn.classList.add('text-blue-500', 'fill-blue-500')
          starBtn.style.color = '#3b82f6'
          starBtn.style.fill = '#3b82f6'

          if (textSpan) {
            textSpan.classList.add('font-bold')
            textSpan.style.color = '#3b82f6'
          }
        } else {
          starBtn.classList.add('text-text-muted')
          if (textSpan) {
            textSpan.classList.add('text-text-secondary', 'font-medium')
          }
        }
      } else {
        starBtn.classList.add('text-text-muted')
        if (textSpan) {
          textSpan.classList.add('text-text-secondary', 'font-medium')
        }
      }
    })
  }

  buildFavoriteOperations() {
    const operations = {
      rowsToInsert: [],
      rowsToUpdate: [],
      rowsToDelete: []
    }

    Object.keys(this.dirtyFavorites).forEach((menuCd) => {
      const dirty = this.dirtyFavorites[menuCd]
      const orig = this.userFavorites.find((f) => f.menu_cd === menuCd)

      if (!orig) {
        if (dirty.use_yn === 'Y') {
          operations.rowsToInsert.push({ ...dirty })
        }
      } else {
        if (dirty.use_yn === 'N') {
          operations.rowsToDelete.push({ menu_cd: menuCd })
        } else {
          if (orig.use_yn !== dirty.use_yn || orig.user_favor_menu_grp !== dirty.user_favor_menu_grp) {
            operations.rowsToUpdate.push({ ...dirty })
          }
        }
      }
    })

    return operations
  }
}
