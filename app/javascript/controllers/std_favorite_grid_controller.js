import { Controller } from "@hotwired/stimulus"
import GridCrudManager from "controllers/grid/grid_crud_manager"
import { fetchJson, hasChanges, isApiAlive, postJson, setManagerRowData } from "controllers/grid/grid_utils"

export default class extends Controller {
  static targets = ["grid", "groupGrid"]

  static values = {
    batchUrl: String,
    groupListUrl: String,
    groupBatchUrl: String
  }

  connect() {
    this.favoriteManager = null
    this.groupManager = null
    this.favoriteGridController = null
    this.userField = this.element.querySelector("[name='q[user_id_code]']")
    this.userChangeHandler = () => this.reloadGroups()

    if (this.userField) {
      this.userField.addEventListener("change", this.userChangeHandler)
    }
  }

  disconnect() {
    if (this.userField) {
      this.userField.removeEventListener("change", this.userChangeHandler)
    }
    this.favoriteManager?.detach()
    this.groupManager?.detach()
    this.favoriteManager = null
    this.groupManager = null
    this.favoriteGridController = null
  }

  registerGrid(event) {
    const { api, controller } = event.detail
    const gridElement = event.target

    if (gridElement === this.gridTarget) {
      this.favoriteGridController = controller
      this.favoriteManager?.detach()
      this.favoriteManager = new GridCrudManager(this.favoriteConfig)
      this.favoriteManager.attach(api)
    }

    if (gridElement === this.groupGridTarget) {
      this.groupManager?.detach()
      this.groupManager = new GridCrudManager(this.groupConfig)
      this.groupManager.attach(api)
      this.reloadGroups()
    }
  }

  addRow() {
    if (!this.favoriteManager) return
    this.favoriteManager.addRow({ user_id_code: this.currentUserIdCode, use_yn: "Y" })
  }

  deleteRows() {
    if (!this.favoriteManager) return
    this.favoriteManager.deleteRows()
  }

  async saveRows() {
    if (!this.favoriteManager) return

    this.favoriteManager.stopEditing()
    const operations = this.favoriteManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("No changed data.")
      return
    }

    const ok = await postJson(this.batchUrlValue, operations)
    if (!ok) return

    alert("Favorite data saved.")
    this.reloadFavoriteRows()
  }

  addGroupRow() {
    if (!this.groupManager) return
    this.groupManager.addRow({ user_id_code: this.currentUserIdCode, use_yn: "Y" })
  }

  deleteGroupRows() {
    if (!this.groupManager) return
    this.groupManager.deleteRows()
  }

  async saveGroupRows() {
    if (!this.groupManager) return

    this.groupManager.stopEditing()
    const operations = this.groupManager.buildOperations()
    if (!hasChanges(operations)) {
      alert("No changed data.")
      return
    }

    const ok = await postJson(this.groupBatchUrlValue, operations)
    if (!ok) return

    alert("Favorite group data saved.")
    this.reloadGroups()
  }

  get favoriteConfig() {
    return {
      pkFields: ["user_id_code", "menu_cd"],
      fields: {
        user_id_code: "trimUpper",
        menu_cd: "trimUpper",
        menu_nm: "trim",
        user_favor_menu_grp: "trim",
        sort_seq: "number",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        user_id_code: "",
        menu_cd: "",
        menu_nm: "",
        user_favor_menu_grp: "",
        sort_seq: 0,
        use_yn: "Y"
      },
      blankCheckFields: ["menu_cd"],
      comparableFields: ["menu_nm", "user_favor_menu_grp", "sort_seq", "use_yn"],
      firstEditCol: "menu_cd",
      pkLabels: { user_id_code: "User ID", menu_cd: "Menu Code" }
    }
  }

  get groupConfig() {
    return {
      pkFields: ["user_id_code", "group_nm"],
      fields: {
        user_id_code: "trimUpper",
        group_nm: "trim",
        use_yn: "trimUpperDefault:Y"
      },
      defaultRow: {
        user_id_code: "",
        group_nm: "",
        use_yn: "Y"
      },
      blankCheckFields: ["group_nm"],
      comparableFields: ["use_yn"],
      firstEditCol: "group_nm",
      pkLabels: { user_id_code: "User ID", group_nm: "Group Name" }
    }
  }

  async reloadFavoriteRows() {
    if (!isApiAlive(this.favoriteManager?.api)) return
    if (!this.favoriteGridController?.urlValue) return

    try {
      const rows = await fetchJson(this.favoriteGridController.urlValue)
      setManagerRowData(this.favoriteManager, rows)
    } catch {
      alert("Failed to reload favorite list.")
    }
  }

  async reloadGroups() {
    if (!isApiAlive(this.groupManager?.api)) return

    const userIdCode = this.currentUserIdCode
    if (!userIdCode) {
      setManagerRowData(this.groupManager, [])
      return
    }

    const query = new URLSearchParams({ "q[user_id_code]": userIdCode })
    try {
      const rows = await fetchJson(`${this.groupListUrlValue}?${query.toString()}`)
      setManagerRowData(this.groupManager, rows)
    } catch {
      alert("Failed to load favorite groups.")
    }
  }

  get currentUserIdCode() {
    return this.userField?.value?.toString().trim().toUpperCase() || ""
  }
}
