import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "userGrid", "roleGrid", "menuGrid"]

  static values = {
    ...BaseGridController.values,
    rolesListUrlTemplate: String,
    menusListUrlTemplate: String
  }

  masterConfig() {
    return {
      role: "user",
      key: {
        field: "user_id_code",
        stateProperty: "selectedUserIdCode",
        entityLabel: "사용자"
      },
      onRowChange: {
        trackCurrentRow: false,
        syncForm: false
      }
    }
  }

  detailGrids() {
    return [
      {
        role: "role",
        masterKeyField: "user_id_code",
        listUrlTemplate: "rolesListUrlTemplateValue",
        placeholder: ":user_id_code",
        fetchErrorMessage: "사용자 역할 조회에 실패했습니다."
      },
      {
        role: "menu",
        masterKeyField: ["user_id_code", "role_cd"],
        listUrlTemplate: "menusListUrlTemplateValue",
        fetchErrorMessage: "메뉴 조회에 실패했습니다."
      }
    ]
  }

  gridRoles() {
    return {
      user: {
        target: "userGrid",
        isMaster: true,
        masterKeyField: "user_id_code"
      },
      role: {
        target: "roleGrid",
        parentGrid: "user",
        isMaster: true,
        masterKeyField: "role_cd",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("role", rowData)
      },
      menu: {
        target: "menuGrid",
        parentGrid: "role",
        detailLoader: (rowData) => this.loadDetailRows("menu", rowData)
      }
    }
  }
}
