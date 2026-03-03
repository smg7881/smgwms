import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"
import { switchTab, activateTab } from "controllers/ui_utils"
// 작업진행현황 화면 (폼 + 2개 그리드)
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    // Form Inputs
    "custOrdNo", "ordNo", "custOrdTypeNm", "ordReqCustNm",
    "ctrtNo", "ctrtCustNm", "bilgCustNm", "ordTypeNm",
    "custOrdOfcr", "custTel", "custExprYn", "clsExprYn",
    "retrngdYn", "ordStatNm", "ordCmptNm",
    // Grid Containers
    "itemGridContainer", "progressGridContainer",
    // Tabs
    "tabButton", "tabPanel"
  ]

  gridRoles() {
    return {
      items: { target: "itemGridContainer" },
      progresses: { target: "progressGridContainer" }
    }
  }

  // 검색폼의 JSON 응답을 받아와 바인딩
  loadData(event) {
    if (!event.detail) return

    const response = event.detail

    if (response && response.master) {
      this.bindMaster(response.master)
      this.setRows("items", response.items || [])
      this.setRows("progresses", response.progresses || [])
    } else {
      this.bindMaster({})
      this.setRows("items", [])
      this.setRows("progresses", [])

      if (response && response.length === 0) {
        showAlert("오더 번호를 정확히 넣고 검색하십시오.")
      }
    }
  }

  switchTab(event) {
    switchTab(event, this)

    const tabId = this.activeTab
    // 숨겨져 있던 그리드가 표시될 때 크기 재조정 필요
    setTimeout(() => {
      if (tabId === "items" && this.grids.items) {
        this.resizeGridIfNecessary(this.grids.items)
      } else if (tabId === "progress" && this.grids.progresses) {
        this.resizeGridIfNecessary(this.grids.progresses)
      }
    }, 10)
  }

  activateTab(tabId) {
    activateTab(tabId, this)

    // 숨겨져 있던 그리드가 표시될 때 크기 재조정 필요
    setTimeout(() => {
      if (tabId === "items" && this.grids.items) {
        this.resizeGridIfNecessary(this.grids.items)
      } else if (tabId === "progress" && this.grids.progresses) {
        this.resizeGridIfNecessary(this.grids.progresses)
      }
    }, 10)
  }

  resizeGridIfNecessary(grid) {
    if (grid && grid.api) {
      grid.api.sizeColumnsToFit()
    }
  }

  // ─── Private ───

  bindMaster(master) {
    this.custOrdNoTarget.value = master.cust_ord_no || ""
    this.ordNoTarget.value = master.ord_no || ""
    this.custOrdTypeNmTarget.value = master.cust_ord_type_nm || ""
    this.ordReqCustNmTarget.value = master.ord_req_cust_nm || ""

    this.ctrtNoTarget.value = master.ctrt_no || ""
    this.ctrtCustNmTarget.value = master.ctrt_cust_nm || ""
    this.bilgCustNmTarget.value = master.bilg_cust_nm || ""
    this.ordTypeNmTarget.value = master.ord_type_nm || ""

    this.custOrdOfcrTarget.value = master.cust_ord_ofcr || ""
    this.custTelTarget.value = master.cust_tel || ""
    this.custExprYnTarget.value = master.cust_expr_yn || ""
    this.clsExprYnTarget.value = master.cls_expr_yn || ""

    this.retrngdYnTarget.value = master.retrngd_yn || ""
    this.ordStatNmTarget.value = master.ord_stat_nm || ""
    this.ordCmptNmTarget.value = master.ord_cmpt_nm || ""
  }
}
