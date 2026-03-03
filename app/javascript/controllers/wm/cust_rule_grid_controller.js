import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
    configureManager() {
        return {
            pkFields: ["id"],
            fields: {
                workpl_cd: "trimUpper",
                cust_cd: "trimUpper",
                inout_sctn: "trim",
                inout_type: "trim",
                rule_sctn: "trim",
                aply_yn: "trimUpperDefault:Y",
                remark: "trim"
            },
            defaultRow: { workpl_cd: "", cust_cd: "", inout_sctn: "", inout_type: "", rule_sctn: "", aply_yn: "Y", remark: "" },
            blankCheckFields: ["workpl_cd", "cust_cd", "inout_sctn", "inout_type", "rule_sctn", "aply_yn"],
            comparableFields: ["workpl_cd", "cust_cd", "inout_sctn", "inout_type", "rule_sctn", "aply_yn", "remark"],
            firstEditCol: "workpl_cd",
            pkLabels: { id: "ID" }
        }
    }

    get saveMessage() {
        return "고객 RULE 데이터가 저장되었습니다."
    }
}
