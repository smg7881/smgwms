import BaseGridController from "controllers/base_grid_controller"
import { showAlert, confirmAction } from "components/ui/alert"

export default class extends BaseGridController {
    static targets = [...BaseGridController.targets]

    connect() {
        super.connect()
    }

    configureManager() {
        return {
            pkFields: ["cust_cd", "inout_sctn", "stock_attr_sctn"],
            fields: {
                cust_cd: "trimUpper",
                inout_sctn: "trim",
                stock_attr_sctn: "trim",
                attr_desc: "trim",
                rel_tbl: "trim",
                rel_col: "trim",
                use_yn: "trimUpperDefault:Y"
            },
            defaultRow: { cust_cd: "", inout_sctn: "", stock_attr_sctn: "", attr_desc: "", rel_tbl: "", rel_col: "", use_yn: "Y" },
            blankCheckFields: ["inout_sctn", "stock_attr_sctn"],
            comparableFields: ["attr_desc", "rel_tbl", "rel_col", "use_yn"],
            firstEditCol: "inout_sctn",
            pkLabels: { cust_cd: "고객코드", inout_sctn: "입출고구분", stock_attr_sctn: "재고속성구분" }
        }
    }

    get saveMessage() {
        return "고객재고속성 데이터가 저장되었습니다."
    }

    // 고객 검색팝업에서 선택 결과 수신
    handlePopupSelected(event) {
        if (event.detail.target !== "cust_cd") return

        // 기본 검색 필드 채우기 외에, 
        // 여기서 그리드에 고객코드(cust_cd)를 기본적으로 세팅하기 위한 처리를 추가할 수 있습니다.
        // 하지만 "행추가" 시, 현재 검색 조건의 고객코드를 가져오도록 addRow()를 재정의하는 것이 일반적입니다.
    }

    addRow(event) {
        if (event) event.preventDefault()
        if (!this.getSearchFormValue("cust_cd")) {
            showAlert("검색조건에서 먼저 고객을 선택해주세요.")
            return
        }
        super.addRow()
    }

    buildNewRowOverrides() {
        return {
            cust_cd: this.getSearchFormValue("cust_cd"),
            cust_nm: this.getSearchFormValue("cust_nm")
        }
    }
}
