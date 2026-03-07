import BaseGridController from "controllers/base_grid_controller"
import { setSelectOptions as setSelectOptionsUtil } from "controllers/grid/grid_select_utils"
import {
  bindDependentSelects,
  unbindDependentSelects,
  resolveMapOptions
} from "controllers/grid/grid_dependent_select_utils"
import {
  bindDetailFieldEvents,
  unbindDetailFieldEvents,
  detailFieldKey,
  fillDetailForm as fillDetailFormUtil,
  clearDetailForm as clearDetailFormUtil,
  syncDetailField as syncDetailFieldUtil,
  markCurrentMasterRowUpdated,
  refreshMasterRowCells,
  toDateInputValue
} from "controllers/grid/grid_form_utils"
import { switchTab, activateTab } from "controllers/ui_utils"
import {
  popupRootForField,
  setPopupValues,
  setPopupDisabled
} from "controllers/grid/grid_popup_utils"

// 코드성 필드: 상세 폼/그리드 입력 시 대문자 정규화 대상
const CODE_FIELDS = [
  "bzac_cd",
  "mngt_corp_cd",
  "bzac_sctn_grp_cd",
  "bzac_sctn_cd",
  "bzac_kind_cd",
  "upper_bzac_cd",
  "rpt_bzac_cd",
  "ctry_cd",
  "tpl_logis_yn_cd",
  "if_yn_cd",
  "branch_yn_cd",
  "sell_bzac_yn_cd",
  "pur_bzac_yn_cd",
  "bilg_bzac_cd",
  "elec_taxbill_yn_cd",
  "fnc_or_cd",
  "rpt_sales_emp_cd",
  "use_yn_cd"
]

// 날짜 필드: input[type=date] 포맷으로 정규화 대상
const DATE_FIELDS = ["aply_strt_day_cd", "aply_end_day_cd"]
const YES_NO_VALUES = ["Y", "N"]
const BIZMAN_NO_PATTERN = /^\d{10}$/
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const ADDITIONAL_TAB_FIELDS = new Set([
  "if_yn_cd",
  "branch_yn_cd",
  "sell_bzac_yn_cd",
  "pur_bzac_yn_cd",
  "tpl_logis_yn_cd",
  "elec_taxbill_yn_cd",
  "bilg_bzac_cd",
  "fnc_or_cd",
  "acnt_no_cd",
  "remk"
])

const POPUP_NAME_KEY_BY_CODE_KEY = {
  mngt_corp_cd: "mngt_corp_nm",
  fnc_or_cd: "fnc_or_nm",
  upper_bzac_cd: "upper_bzac_nm",
  zip_cd: "zip_nm"
}

// 거래처 마스터 + 담당자/작업장 디테일 + 상세 폼 동기화 컨트롤러
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid",
    "contactsGrid",
    "workplacesGrid",
    "selectedClientLabel",
    "detailField",
    "detailGroupField",
    "detailSectionField",
    "tabButton",
    "tabPanel"
  ]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    contactBatchUrlTemplate: String,
    contactListUrlTemplate: String,
    workplaceBatchUrlTemplate: String,
    workplaceListUrlTemplate: String,
    sectionMap: Object,
    selectedClient: String
  }

  // 초기 화면 상태/이벤트 바인딩
  connect() {
    super.connect()

    this.currentMasterRow = null
    this.activeTab = "basic"

    bindDependentSelects(this, this.#searchDependentConfig())
    bindDetailFieldEvents(this, null, (event) => {
      syncDetailFieldUtil(event, this)
      const key = detailFieldKey(event.currentTarget)
      if (this.isPopupCodeKey(key)) {
        this.syncPopupFieldPresentation(event.currentTarget, key, event.currentTarget.value)
      }
      if (key === "bzac_sctn_grp_cd") {
        this.handleDetailGroupChange(event)
      }
    })
    this._onPopupSelected = (event) => this.handlePopupSelected(event)
    this.element.addEventListener("search-popup:selected", this._onPopupSelected)
    this.activateTab("basic")
    this.clearDetailForm()
    this.clearValidationErrors()
    this.refreshSelectedLabel()
  }

  // 이벤트 해제 및 상태 정리
  disconnect() {
    unbindDependentSelects(this)
    unbindDetailFieldEvents(this)
    if (this._onPopupSelected) {
      this.element.removeEventListener("search-popup:selected", this._onPopupSelected)
      this._onPopupSelected = null
    }

    this.currentMasterRow = null

    super.disconnect()
  }

  // 다중 그리드 역할 정의 (master -> contacts/workplaces)
  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "거래처 데이터가 저장되었습니다.",
      pendingEntityLabel: "마스터 거래처",
      key: {
        field: "bzac_cd",
        stateProperty: "selectedClientValue",
        labelTarget: "selectedClientLabel",
        entityLabel: "거래처",
        emptyMessage: "거래처를 먼저 선택하세요."
      },
      onRowChange: {
        trackCurrentRow: true,
        syncForm: true
      },
      beforeSearch: {
        clearValidation: true,
        clearForm: true
      },
      onAdded: (rowData) => {
        this.activateTab("basic")
        this.onMasterRowChanged(rowData)
      }
    }
  }

  detailGrids() {
    return [
      {
        role: "contacts",
        masterKeyField: "bzac_cd",
        placeholder: ":id",
        listUrlTemplate: "contactListUrlTemplateValue",
        batchUrlTemplate: "contactBatchUrlTemplateValue",
        entityLabel: "거래처",
        saveMessage: "거래처 담당자 데이터가 저장되었습니다.",
        fetchErrorMessage: "담당자 목록 조회에 실패했습니다.",
        onSaveSuccess: () => this.reloadContactRows(this.selectedClientValue)
      },
      {
        role: "workplaces",
        masterKeyField: "bzac_cd",
        placeholder: ":id",
        listUrlTemplate: "workplaceListUrlTemplateValue",
        batchUrlTemplate: "workplaceBatchUrlTemplateValue",
        entityLabel: "거래처",
        saveMessage: "거래처 작업장 데이터가 저장되었습니다.",
        fetchErrorMessage: "작업장 목록 조회에 실패했습니다.",
        onSaveSuccess: () => this.reloadWorkplaceRows(this.selectedClientValue)
      }
    ]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: "masterManagerConfig",
        masterKeyField: "bzac_cd"
      },
      contacts: {
        target: "contactsGrid",
        manager: "contactManagerConfig",
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("contacts", rowData)
      },
      workplaces: {
        target: "workplacesGrid",
        manager: "workplaceManagerConfig",
        parentGrid: "master",
        detailLoader: (rowData) => this.loadDetailRows("workplaces", rowData)
      }
    }
  }

  // 마스터 거래처 CRUD/정규화 규칙
  masterManagerConfig() {
    return {
      pkFields: ["bzac_cd"],
      fields: {
        bzac_cd: "trimUpper",
        bzac_nm: "trim",
        mngt_corp_cd: "trimUpper",
        bizman_no: "trim",
        bzac_sctn_grp_cd: "trimUpper",
        bzac_sctn_cd: "trimUpper",
        bzac_kind_cd: "trimUpper",
        upper_bzac_cd: "trimUpper",
        rpt_bzac_cd: "trimUpper",
        ctry_cd: "trimUpperDefault:KR",
        tpl_logis_yn_cd: "trimUpperDefault:N",
        if_yn_cd: "trimUpperDefault:N",
        branch_yn_cd: "trimUpperDefault:N",
        sell_bzac_yn_cd: "trimUpperDefault:Y",
        pur_bzac_yn_cd: "trimUpperDefault:Y",
        bilg_bzac_cd: "trimUpper",
        elec_taxbill_yn_cd: "trimUpperDefault:N",
        fnc_or_cd: "trimUpper",
        acnt_no_cd: "trim",
        zip_cd: "trim",
        addr_cd: "trim",
        addr_dtl_cd: "trim",
        rpt_sales_emp_cd: "trimUpper",
        rpt_sales_emp_nm: "trim",
        aply_strt_day_cd: "trim",
        aply_end_day_cd: "trim",
        use_yn_cd: "trimUpperDefault:Y",
        remk: "trim"
      },
      defaultRow: {
        bzac_cd: "",
        bzac_nm: "",
        mngt_corp_cd: "",
        mngt_corp_nm: "",
        bizman_no: "",
        bzac_sctn_grp_cd: "",
        bzac_sctn_cd: "",
        bzac_kind_cd: "CORP",
        upper_bzac_cd: "",
        upper_bzac_nm: "",
        rpt_bzac_cd: "",
        ctry_cd: "KR",
        tpl_logis_yn_cd: "N",
        if_yn_cd: "N",
        branch_yn_cd: "N",
        sell_bzac_yn_cd: "Y",
        pur_bzac_yn_cd: "Y",
        bilg_bzac_cd: "",
        elec_taxbill_yn_cd: "N",
        fnc_or_cd: "",
        fnc_or_nm: "",
        acnt_no_cd: "",
        zip_cd: "",
        zip_nm: "",
        addr_cd: "",
        addr_dtl_cd: "",
        rpt_sales_emp_cd: "",
        rpt_sales_emp_nm: "",
        aply_strt_day_cd: "",
        aply_end_day_cd: "",
        use_yn_cd: "Y",
        remk: ""
      },
      blankCheckFields: ["bzac_nm", "bizman_no"],
      comparableFields: [
        "bzac_nm",
        "mngt_corp_cd",
        "bizman_no",
        "bzac_sctn_grp_cd",
        "bzac_sctn_cd",
        "bzac_kind_cd",
        "upper_bzac_cd",
        "rpt_bzac_cd",
        "ctry_cd",
        "tpl_logis_yn_cd",
        "if_yn_cd",
        "branch_yn_cd",
        "sell_bzac_yn_cd",
        "pur_bzac_yn_cd",
        "bilg_bzac_cd",
        "elec_taxbill_yn_cd",
        "fnc_or_cd",
        "acnt_no_cd",
        "zip_cd",
        "addr_cd",
        "addr_dtl_cd",
        "rpt_sales_emp_cd",
        "rpt_sales_emp_nm",
        "aply_strt_day_cd",
        "aply_end_day_cd",
        "use_yn_cd",
        "remk"
      ],
      validationRules: {
        requiredFields: [
          "bzac_nm",
          "mngt_corp_cd",
          "bizman_no",
          "bzac_sctn_grp_cd",
          "bzac_sctn_cd",
          "bzac_kind_cd",
          "ctry_cd",
          "rpt_sales_emp_cd",
          "aply_strt_day_cd",
          "use_yn_cd"
        ],
        fieldLabels: {
          bzac_nm: "거래처명",
          mngt_corp_cd: "관리법인",
          bizman_no: "사업자번호",
          bzac_sctn_grp_cd: "거래처구분그룹",
          bzac_sctn_cd: "거래처구분",
          bzac_kind_cd: "거래처종류",
          ctry_cd: "국가",
          rpt_sales_emp_cd: "대표영업사원",
          aply_strt_day_cd: "적용시작일",
          aply_end_day_cd: "적용종료일",
          tpl_logis_yn_cd: "3자물류여부",
          if_yn_cd: "IF 여부",
          branch_yn_cd: "지점여부",
          sell_bzac_yn_cd: "매출여부",
          pur_bzac_yn_cd: "매입여부",
          elec_taxbill_yn_cd: "전자세금계산서",
          use_yn_cd: "사용여부"
        },
        fieldRules: {
          bizman_no: [
            {
              type: "pattern",
              value: BIZMAN_NO_PATTERN,
              message: "사업자번호는 숫자 10자리여야 합니다."
            }
          ],
          tpl_logis_yn_cd: [{ type: "enum", values: YES_NO_VALUES }],
          if_yn_cd: [{ type: "enum", values: YES_NO_VALUES }],
          branch_yn_cd: [{ type: "enum", values: YES_NO_VALUES }],
          sell_bzac_yn_cd: [{ type: "enum", values: YES_NO_VALUES }],
          pur_bzac_yn_cd: [{ type: "enum", values: YES_NO_VALUES }],
          elec_taxbill_yn_cd: [{ type: "enum", values: YES_NO_VALUES }],
          use_yn_cd: [{ type: "enum", values: YES_NO_VALUES }]
        },
        rowRules: [
          {
            code: "date_order",
            field: "aply_end_day_cd",
            message: "적용종료일은 적용시작일보다 빠를 수 없습니다.",
            validate: ({ normalizedRow }) => {
              const start = (normalizedRow.aply_strt_day_cd || "").toString().trim()
              const end = (normalizedRow.aply_end_day_cd || "").toString().trim()
              if (!start || !end) return true
              return start <= end
            }
          }
        ]
      },
      firstEditCol: "bzac_nm",
      pkLabels: { bzac_cd: "거래처코드" },
      onCellValueChanged: (event) => this.normalizeMasterField(event)
    }
  }

  // 담당자 그리드 CRUD 규칙
  contactManagerConfig() {
    return {
      pkFields: ["seq_cd"],
      fields: {
        seq_cd: "number",
        nm_cd: "trim",
        ofic_telno_cd: "trim",
        mbp_no_cd: "trim",
        email_cd: "trim",
        rpt_yn_cd: "trimUpperDefault:N",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        seq_cd: null,
        nm_cd: "",
        ofic_telno_cd: "",
        mbp_no_cd: "",
        email_cd: "",
        rpt_yn_cd: "N",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["nm_cd"],
      comparableFields: ["nm_cd", "ofic_telno_cd", "mbp_no_cd", "email_cd", "rpt_yn_cd", "use_yn_cd"],
      validationRules: {
        requiredFields: ["nm_cd"],
        fieldLabels: {
          nm_cd: "담당자명",
          email_cd: "이메일",
          rpt_yn_cd: "대표여부",
          use_yn_cd: "사용여부"
        },
        fieldRules: {
          email_cd: [
            {
              type: "pattern",
              value: EMAIL_PATTERN,
              allowBlank: true,
              message: "이메일 형식이 올바르지 않습니다."
            }
          ],
          rpt_yn_cd: [{ type: "enum", values: YES_NO_VALUES }],
          use_yn_cd: [{ type: "enum", values: YES_NO_VALUES }]
        }
      },
      firstEditCol: "nm_cd",
      pkLabels: { seq_cd: "순번" }
    }
  }

  // 작업장 그리드 CRUD 규칙
  workplaceManagerConfig() {
    return {
      pkFields: ["seq_cd"],
      fields: {
        seq_cd: "number",
        workpl_nm_cd: "trim",
        workpl_sctn_cd: "trimUpper",
        ofcr_cd: "trimUpper",
        use_yn_cd: "trimUpperDefault:Y"
      },
      defaultRow: {
        seq_cd: null,
        workpl_nm_cd: "",
        workpl_sctn_cd: "",
        ofcr_cd: "",
        use_yn_cd: "Y"
      },
      blankCheckFields: ["workpl_nm_cd"],
      comparableFields: ["workpl_nm_cd", "workpl_sctn_cd", "ofcr_cd", "use_yn_cd"],
      validationRules: {
        requiredFields: ["workpl_nm_cd"],
        fieldLabels: {
          workpl_nm_cd: "작업장명",
          use_yn_cd: "사용여부"
        },
        fieldRules: {
          use_yn_cd: [{ type: "enum", values: YES_NO_VALUES }]
        }
      },
      firstEditCol: "workpl_nm_cd",
      pkLabels: { seq_cd: "순번" }
    }
  }

  // grid_form_utils 유틸이 controller.manager 경로를 기대하므로 브릿지 제공
  // base_grid_controller가 this.manager = null 을 쓰므로 setter도 함께 정의(흡수)
  get manager() {
    return this.masterManager
  }

  set manager(_v) {
    // base_grid_controller의 단일그리드 경로 할당 흡수 — 멀티그리드 전용이므로 무시
  }

  // 상세 폼 submit 기본 동작 차단 (그리드 저장 흐름 사용)
  preventDetailSubmit(event) {
    event.preventDefault()
  }

  beforeShowValidationErrors({ manager, firstError }) {
    if (!manager) return

    if (manager === this.contactManager) {
      this.activateTab("contacts")
      return
    }

    if (manager === this.workplaceManager) {
      this.activateTab("workplaces")
      return
    }

    if (manager !== this.masterManager) return

    const field = (firstError?.field || "").toString().trim()
    if (ADDITIONAL_TAB_FIELDS.has(field)) {
      this.activateTab("additional")
      return
    }

    this.activateTab("basic")
  }

  // 탭 전환
  switchTab(event) {
    switchTab(event, this)
  }

  activateTab(tab) {
    activateTab(tab, this)
  }

  // ----- 상세 폼 <-> 마스터 행 동기화 -----
  fillDetailForm(rowData) {
    fillDetailFormUtil(this, rowData, {
      beforeFill: () => {
        this.updateDetailSectionOptions(rowData?.bzac_sctn_grp_cd, rowData?.bzac_sctn_cd)
      },
      onFieldFill: (field, key, value, data) => {
        this.syncPopupFieldPresentation(field, key, value, data)
      },
      onFieldToggle: (field, disabled) => {
        this.togglePopupFieldDisabled(field, disabled)
      }
    })
  }

  clearDetailForm() {
    clearDetailFormUtil(this, {
      onFieldClear: (field, key) => {
        this.syncPopupFieldPresentation(field, key, "")
      },
      onFieldToggle: (field, disabled) => {
        this.togglePopupFieldDisabled(field, disabled)
      },
      afterClear: () => {
        this.updateDetailSectionOptions("", "")
      }
    })
  }

  // 거래처구분그룹 변경 시 거래처구분 옵션/값 동기화
  handleDetailGroupChange(event) {
    if (this._suppressDetailFieldSync) return
    if (!this.currentMasterRow) return
    if (!this.hasDetailSectionFieldTarget) return

    const groupCode = this.normalizeDetailFieldValue("bzac_sctn_grp_cd", event.currentTarget.value)
    const previousSection = this.detailSectionFieldTarget.value

    this.updateDetailSectionOptions(groupCode, previousSection)

    const currentSection = this.detailSectionFieldTarget.value
    this.currentMasterRow.bzac_sctn_cd = currentSection

    markCurrentMasterRowUpdated(this)
    refreshMasterRowCells(this, ["bzac_sctn_grp_cd", "bzac_sctn_cd", "__row_status"])
  }

  // 상세 폼 select 옵션 구성
  updateDetailSectionOptions(groupCode, selectedCode = "") {
    if (!this.hasDetailSectionFieldTarget) return

    const options = resolveMapOptions(this.sectionMapValue, groupCode)
    setSelectOptionsUtil(this.detailSectionFieldTarget, options, selectedCode, "")
  }

  // 입력값 표시용 정규화
  normalizeValueForInput(fieldName, rawValue) {
    if (rawValue == null) return ""

    if (DATE_FIELDS.includes(fieldName)) {
      return toDateInputValue(rawValue)
    }

    return rawValue.toString()
  }

  // 저장 전 상세 필드 정규화
  normalizeDetailFieldValue(fieldName, rawValue) {
    const value = (rawValue || "").toString()

    if (fieldName === "bizman_no") {
      return value.replace(/[^0-9]/g, "")
    }

    if (CODE_FIELDS.includes(fieldName)) {
      return value.trim().toUpperCase()
    }

    if (DATE_FIELDS.includes(fieldName)) {
      return toDateInputValue(value)
    }

    if (fieldName === "remk") {
      return value
    }

    return value.trim()
  }

  // popup 필드의 code/display 표시 동기화
  syncPopupFieldPresentation(fieldElement, key, value, rowData = null) {
    const popupRoot = popupRootForField(fieldElement)
    if (!popupRoot || !key) return

    const codeValue = (value || "").toString().trim()
    if (codeValue === "") {
      setPopupValues(popupRoot, "", "")
      return
    }

    const nameKey = this.nameKeyForCodeKey(key)
    const seededName = nameKey ? (rowData?.[nameKey] || "").toString().trim() : ""
    if (seededName.length > 0) {
      setPopupValues(popupRoot, codeValue, seededName)
      return
    }

    setPopupValues(popupRoot, codeValue, "")
  }

  // popup 필드 비활성화 상태 동기화
  togglePopupFieldDisabled(fieldElement, disabled) {
    const popupRoot = popupRootForField(fieldElement)
    if (popupRoot) setPopupDisabled(popupRoot, disabled)
  }

  isPopupCodeKey(key) {
    return Boolean(this.nameKeyForCodeKey(key))
  }

  nameKeyForCodeKey(codeKey) {
    return POPUP_NAME_KEY_BY_CODE_KEY[codeKey] || null
  }

  handlePopupSelected(event) {
    if (!this.currentMasterRow) return

    const popupRoot = event.target?.closest?.("[data-controller~='search-popup']")
    const codeKey = popupRoot?.dataset?.fieldName?.toString().trim()
    if (!this.isPopupCodeKey(codeKey)) return

    const nameKey = this.nameKeyForCodeKey(codeKey)
    const detail = event.detail || {}
    const code = this.normalizeDetailFieldValue(codeKey, detail.code ?? this.currentMasterRow[codeKey] ?? "")
    const name = this.resolvePopupSelectionName(codeKey, detail)

    this.currentMasterRow[codeKey] = code
    this.currentMasterRow[nameKey] = name

    refreshMasterRowCells(this, [codeKey, nameKey])
  }

  resolvePopupSelectionName(codeKey, detail) {
    if (codeKey === "mngt_corp_cd") {
      return String(detail.corp_nm ?? detail.name ?? detail.display ?? "").trim()
    }

    if (codeKey === "fnc_or_cd") {
      return String(detail.fnc_or_nm ?? detail.name ?? detail.display ?? "").trim()
    }

    if (codeKey === "upper_bzac_cd" || codeKey === "zip_cd") {
      return String(detail.name ?? detail.display ?? "").trim()
    }

    return String(detail.name ?? detail.display ?? "").trim()
  }

  // 마스터 셀 입력 정규화 (코드/사업자번호)
  normalizeMasterField(event) {
    const field = event?.colDef?.field
    if (!field || !event?.node?.data) return

    const row = event.node.data
    if (field === "bizman_no") {
      row[field] = (row[field] || "").toString().replace(/[^0-9]/g, "")
    } else if (CODE_FIELDS.includes(field)) {
      row[field] = (row[field] || "").toString().trim().toUpperCase()
    }

    const api = this.masterManager?.api
    if (!api) return

    api.refreshCells({
      rowNodes: [event.node],
      columns: [field],
      force: true
    })
  }

  // 검색폼 의존 SELECT 설정 (거래처구분그룹 → 거래처구분)
  #searchDependentConfig() {
    return {
      fields: ["bzac_sctn_grp_cd", "bzac_sctn_cd"],
      onChange: [
        (controller, fields) => {
          const options = resolveMapOptions(controller.sectionMapValue, fields[0]?.value)
          setSelectOptionsUtil(fields[1], options, "")
        }
      ],
      hydrate: (controller, fields) => {
        const options = resolveMapOptions(controller.sectionMapValue, fields[0]?.value)
        setSelectOptionsUtil(fields[1], options, fields[1]?.value || "")
      }
    }
  }

}
