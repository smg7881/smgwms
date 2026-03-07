import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { postJson } from "controllers/grid/grid_utils"

export default class extends BaseGridController {
  static values = {
    ...BaseGridController.values,
    moveUrl: String
  }

  configureManager() {
    return {
      pkFields: ["corp_cd", "workpl_cd", "stock_attr_no", "loc_cd"],
      fields: {
        to_loc_cd: "trimUpper",
        move_qty: "number"
      },
      defaultRow: {},
      blankCheckFields: [],
      comparableFields: ["to_loc_cd", "move_qty"],
      firstEditCol: "to_loc_cd"
    }
  }

  async moveSelectedRows(event) {
    if (event) {
      event.preventDefault()
    }

    if (!this.moveUrlValue) {
      showAlert("재고이동 URL이 설정되지 않았습니다.")
      return
    }

    const api = this.manager?.api
    if (!api) {
      showAlert("그리드가 아직 준비되지 않았습니다.")
      return
    }

    api.stopEditing()

    const selectedRows = api.getSelectedRows()
    if (selectedRows.length === 0) {
      showAlert("재고이동할 행을 선택해주세요.")
      return
    }

    const payloadRows = []
    const errors = []

    selectedRows.forEach((row, index) => {
      const rowNo = index + 1
      const fromLocCd = this.#codeValue(row.loc_cd)
      const toLocCd = this.#codeValue(row.to_loc_cd)
      const moveQty = this.#numberValue(row.move_qty)
      const movePossQty = this.#numberValue(row.move_poss_qty)

      if (!toLocCd) {
        errors.push(`${rowNo}행 TO 로케이션을 입력해주세요.`)
      } else if (toLocCd === fromLocCd) {
        errors.push(`${rowNo}행 TO 로케이션은 FROM 로케이션과 달라야 합니다.`)
      }

      if (moveQty <= 0) {
        errors.push(`${rowNo}행 이동수량은 0보다 커야 합니다.`)
      } else if (moveQty > movePossQty) {
        errors.push(`${rowNo}행 이동수량이 이동가능수량을 초과했습니다.`)
      }

      payloadRows.push({
        corp_cd: this.#codeValue(row.corp_cd),
        workpl_cd: this.#codeValue(row.workpl_cd),
        cust_cd: this.#codeValue(row.cust_cd),
        item_cd: this.#codeValue(row.item_cd),
        stock_attr_no: this.#codeValue(row.stock_attr_no),
        loc_cd: fromLocCd,
        to_loc_cd: toLocCd,
        move_qty: moveQty,
        basis_unit_cls: this.#codeValue(row.basis_unit_cls),
        basis_unit_cd: this.#codeValue(row.basis_unit_cd)
      })
    })

    if (errors.length > 0) {
      showAlert("Validation", errors[0], "warning")
      return
    }

    const confirmed = await confirmAction("재고이동", `${payloadRows.length}건을 이동 처리하시겠습니까?`)
    if (!confirmed) {
      return
    }

    const result = await postJson(this.moveUrlValue, { rows: payloadRows })
    if (result?.success) {
      showAlert("Success", result.message || "재고이동이 완료되었습니다.", "success")
      this.reloadRows()
    }
  }

  #codeValue(value) {
    return value == null ? "" : value.toString().trim().toUpperCase()
  }

  #numberValue(value) {
    const numberValue = Number(value)
    if (Number.isFinite(numberValue)) {
      return numberValue
    }

    return 0
  }
}
