# Grid 컨트롤러 공통화 설계서 — BaseGridController 통합

작성일: 2026-03-07
대상 소스: `controllers/ag_grid/`, `controllers/grid/`, `system/code_grid_controller.js`, `std/client_grid_controller.js` 외

---

## 1. 문제 분석

### 1.1 현재 구조의 문제점

현재 각 화면 컨트롤러(code_grid_controller, client_grid_controller 등)는
`BaseGridController`를 상속하지만, **동일한 보일러플레이트 코드를 반복**하고 있다.

| 컨트롤러 | 라인 수 | 실제 비즈니스 로직 | 보일러플레이트 |
|---|---|---|---|
| `code_grid_controller.js` | 413줄 | ~40줄 | ~373줄 (90%) |
| `client_grid_controller.js` | 937줄 | ~100줄 | ~837줄 (89%) |

### 1.2 반복되는 패턴 카탈로그

**[패턴 A] 디테일 그리드 CRUD 6종 세트**

디테일 그리드가 하나 추가될 때마다 아래 6개 메서드가 동일한 구조로 생성된다.

```js
// contacts 예시 — workplaces, details 등 모두 동일 구조
addContactRow() {
  if (!this.contactManager) return              // 1. 매니저 존재 여부
  if (this.blockDetailActionIfMasterChanged()) return  // 2. 마스터 미저장 체크
  if (!this.selectedClientValue) {              // 3. 마스터 선택 여부
    showAlert("거래처를 먼저 선택해주세요.")
    return
  }
  this.addRow({ manager: this.contactManager })
}

deleteContactRows() {
  if (!this.contactManager) return
  if (this.blockDetailActionIfMasterChanged()) return
  this.deleteRows({ manager: this.contactManager })
}

async saveContactRows() {
  if (!this.contactManager) return
  if (this.blockDetailActionIfMasterChanged()) return
  if (!this.selectedClientValue) { showAlert("..."); return }
  const batchUrl = buildTemplateUrl(this.contactBatchUrlTemplateValue, ":id", this.selectedClientValue)
  await this.saveRowsWith({ manager: this.contactManager, batchUrl, saveMessage: "...", onSuccess: ... })
}

async fetchContactRows(rowData) { /* 유효성 검사 후 fetchContactRowsByClient 위임 */ }
async fetchContactRowsByClient(clientCode) {
  try {
    const url = buildTemplateUrl(this.contactListUrlTemplateValue, ":id", clientCode)
    const rows = await fetchJson(url)
    return Array.isArray(rows) ? rows : []
  } catch { showAlert("..."); return [] }
}

async reloadContactRows(clientCode) {
  const rows = await this.fetchContactRowsByClient(clientCode)
  setManagerRowData(this.contactManager, rows)
}

clearContactRows() { setManagerRowData(this.contactManager, []) }
```

**디테일 하나 = 6개 메서드 × 약 8줄 = 48줄** — contacts, workplaces, detail 등 개수만큼 곱셈.

---

**[패턴 B] 마스터 키 상태 관리**

```js
// 패턴: 선택된 마스터 키를 보관하고 라벨에 표시
this.selectedClientValue = rowData?.bzac_cd || ""
refreshSelectionLabel(this.selectedClientLabelTarget, this.selectedClientValue, "거래처", "거래처를 먼저 선택하세요.")

// blockDetailActionIfMasterChanged — 매 컨트롤러마다 동일 패턴
blockDetailActionIfMasterChanged() {
  return blockIfPendingChanges(this.masterManager, "마스터 거래처")
}
```

---

**[패턴 C] handleMasterRowChange**

```js
handleMasterRowChange(rowData) {
  this.currentMasterRow = rowData || null
  if (!rowData) { this.clearDetailForm() } else { this.fillDetailForm(rowData) }
  this.selectedClientValue = rowData?.bzac_cd || ""
  this.refreshSelectedClientLabel()
  this.clearContactRows()      // 자식 그리드 초기화 (하드코딩)
  this.clearWorkplaceRows()    // 자식 그리드 초기화 (하드코딩)
}
```

---

**[패턴 D] beforeSearchReset**

```js
beforeSearchReset() {
  this.selectedClientValue = ""
  this.currentMasterRow = null
  this.refreshSelectedClientLabel()
  this.clearValidationErrors()
  this.clearDetailForm()
}
```

---

**[패턴 E] detailLoader 보일러플레이트**

```js
detailLoader: async (rowData) => {
  const code = rowData?.code
  const hasLoadableCode = Boolean(code) && !rowData?.__is_deleted && !rowData?.__is_new
  if (!hasLoadableCode) return []
  try {
    const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":code", code)
    const rows = await fetchJson(url)
    return Array.isArray(rows) ? rows : []
  } catch {
    showAlert("상세코드 목록 조회에 실패했습니다.")
    return []
  }
}
```

---

**[패턴 F] getter 프록시**

```js
get masterManager() { return this.gridManager("master") }
get contactManager() { return this.gridManager("contacts") }
get workplaceManager() { return this.gridManager("workplaces") }
```

---

**[패턴 G] showValidationErrors / clearValidationErrors**

두 컨트롤러에 동일한 구현이 존재. 공통화 가능.

---

## 2. 설계 목표

| 목표 | 내용 |
|---|---|
| 서브클래스 최소화 | 비즈니스 설정값만 선언. 로직은 공통 레이어에서 처리 |
| 기존 API 호환 | `gridRoles()`, `saveRowsWith()` 등 기존 API 유지 |
| 확장 가능 | 특수 동작은 훅(hook)으로 오버라이드 가능 |
| 점진적 도입 | 기존 컨트롤러를 한 번에 바꾸지 않아도 됨 |

---

## 3. 아키텍처 결정: Mixin 분리 → BaseGridController 직접 통합

### 3.1 현재 Mixin 구조의 문제

현재 세 개의 mixin이 `BaseGridController.prototype`에 `Object.assign`으로 합성된다.

```js
// base_grid_controller.js 하단 (현재)
Object.assign(BaseGridController.prototype, ModalMixin)
Object.assign(BaseGridController.prototype, ExcelDownloadable)
```

이 방식은 **여러 다른 클래스에 동일 기능을 붙여야 할 때** 유용하다. 하지만 현재 이 프로젝트에서는 두 mixin 모두 `BaseGridController` **하나에만** 적용되고 있다.

### 3.2 Mixin이 의미 있는 경우 vs 현재 상황

```js
// Mixin이 진짜 필요한 경우 — 여러 독립된 클래스에 재사용
Object.assign(GridController.prototype, ExcelDownloadable)
Object.assign(ReportController.prototype, ExcelDownloadable)  // 다른 클래스에도 적용
Object.assign(AdminController.prototype, ExcelDownloadable)   // 다른 클래스에도 적용

// 현재 상황 — 하나의 클래스에만 적용 (Mixin의 장점 없음)
Object.assign(BaseGridController.prototype, ModalMixin)
Object.assign(BaseGridController.prototype, ExcelDownloadable)
```

런타임에서 Mixin 파일의 메서드와 `BaseGridController` 클래스 본문의 메서드는
**프로토타입 체인상 완전히 동일**하다. 파일만 분리되어 있을 뿐이다.

### 3.3 통합 결정

**ModalMixin**, **ExcelDownloadable**, **MasterDetailMixin(신규)**, **ValidationMixin(신규)** 네 개를
모두 `BaseGridController` 클래스 본문으로 직접 통합한다.

| 구분 | 변경 전 | 변경 후 |
|---|---|---|
| `concerns/modal_mixin.js` | 별도 파일 (344줄) | `BaseGridController` 내부 섹션으로 흡수 → **파일 삭제** |
| `concerns/excel_downloadable.js` | 별도 파일 (44줄) | `BaseGridController` 내부 섹션으로 흡수 → **파일 삭제** |
| `concerns/master_detail_mixin.js` | 신규 생성 예정 | `BaseGridController` 내부 섹션으로 직접 구현 |
| `concerns/validation_mixin.js` | 신규 생성 예정 | `BaseGridController` 내부 섹션으로 직접 구현 |

### 3.4 통합 후 BaseGridController 파일 구조

```js
// base_grid_controller.js — 단일 파일에 섹션 주석으로 구분

export default class BaseGridController extends Controller {

  // ================================================================
  // [섹션 1] Stimulus 선언 — targets / values
  // ================================================================
  static targets = ["grid", "validationBox", "validationSummary", "validationList"]
  static values  = { batchUrl: String }

  // ================================================================
  // [섹션 2] 그리드 공통 — Lifecycle / 등록 / 조회 / 저장 / 삭제
  // ================================================================
  connect()          { ... }
  disconnect()       { ... }
  registerGrid()     { ... }
  gridRoles()        { return null }
  configureManager() { return null }
  addRow()           { ... }
  deleteRows()       { ... }
  saveRowsWith()     { ... }
  refreshGrid()      { ... }

  // ================================================================
  // [섹션 3] 마스터-디테일 자동화 (구 MasterDetailMixin)
  // ================================================================
  // 서브클래스가 masterConfig() / detailGrids() 를 선언하면
  // connect() 시점에 아래 메서드들을 자동 생성한다.
  #initMasterDetail()        { ... }
  #generateMasterMethods()   { ... }
  #generateDetailMethods()   { ... }
  loadDetailRows()           { ... }   // detailLoader 1줄 팩토리
  onMasterRowChanged()       { ... }   // handleMasterRowChange 공통 처리
  refreshSelectedLabel()     { ... }   // 선택 라벨 갱신

  // ================================================================
  // [섹션 4] 유효성 검증 UI (구 ValidationMixin)
  // ================================================================
  // validationBox / validationSummary / validationList target 필요.
  // target이 없으면 자동으로 no-op 처리됨.
  showValidationErrors()  { ... }
  clearValidationErrors() { ... }

  // ================================================================
  // [섹션 5] 모달 CRUD (구 ModalMixin)
  // ================================================================
  connectBase()         { ... }   // 모달 이벤트 등록
  disconnectBase()      { ... }   // 모달 이벤트 해제
  openModal()           { ... }
  closeModal()          { ... }
  save()                { ... }   // 모달 폼 저장
  handleDelete()        { ... }   // 모달 행 삭제
  buildJsonPayload()    { ... }   // FormData → JSON
  setFieldValue()       { ... }   // 폼 필드 값 세팅
  setFieldValues()      { ... }
  startDrag()           { ... }   // 모달 드래그
  handleDragMove()      { ... }
  endDrag()             { ... }
  requestJson()         { ... }   // HTTP 유틸

  // ================================================================
  // [섹션 6] 엑셀 (구 ExcelDownloadable)
  // ================================================================
  openExcelImport()     { ... }
  submitExcelImport()   { ... }
  openImportHistory()   { ... }

  // ================================================================
  // [섹션 7] Private — 내부 그리드 레지스트리
  // ================================================================
  #gridRegistry
  #expectedRoles
  #registerSingleGrid()  { ... }
  #registerMultiGrid()   { ... }
  #handleMasterRowFocused() { ... }
  // ...
}

// Object.assign 제거 — 더 이상 필요 없음
```

---

## 4. 신규 설계: masterConfig() / detailGrids() API

### 4.1 서브클래스가 선언하는 config 메서드 2개

#### (1) `masterConfig()` — 마스터 상태 설정

```js
masterConfig() {
  return {
    // gridRoles()에서 마스터로 선언된 역할명 (default: "master")
    role: "master",

    // 마스터 일괄저장 Stimulus value 이름 (this.xxxValue)
    batchUrl: "masterBatchUrlValue",

    // 저장 성공 메시지
    saveMessage: "데이터가 저장되었습니다.",

    // 마스터 PK 상태 관리 설정
    key: {
      field: "bzac_cd",                     // 마스터 행에서 읽을 PK 필드
      stateProperty: "selectedClientValue", // 이 컨트롤러에 저장할 프로퍼티명
      labelTarget: "selectedClientLabel",   // 라벨 target 이름
      entityLabel: "거래처",                // "선택 거래처: xxx" 라벨용
      emptyMessage: "거래처를 먼저 선택하세요." // 미선택 시 라벨 문구
    },

    // 마스터 행 변경 시 동작
    onRowChange: {
      trackCurrentRow: true,  // this.currentMasterRow 자동 갱신 (default: true)
      syncForm: false,         // true면 clearDetailForm/fillDetailForm 자동 호출
    },

    // 검색 전 초기화 시 추가로 처리할 항목
    beforeSearch: {
      clearValidation: true,  // clearValidationErrors() 호출
      clearForm: false         // clearDetailForm() 호출 (syncForm: true 시 자동)
    },

    // 마스터 행 추가 후 처리 — addMasterRow() 성공 시 호출
    // 기본: onMasterRowChanged(rowData) 호출
    // 예: (rowData) => { this.activateTab("basic"); this.onMasterRowChanged(rowData) }
    onAdded: null,

    // 마스터 신규행 포커스 컬럼 — addRow()의 firstEditCol 전달
    firstEditCol: null
  }
}
```

#### (2) `detailGrids()` — 디테일 그리드 배열 설정

```js
detailGrids() {
  return [
    {
      role: "contacts",           // gridRoles()에서 선언한 역할명 (필수)
      masterKeyField: "bzac_cd", // 마스터 행에서 읽을 FK 필드 (필수)
      placeholder: ":id",         // URL 템플릿 치환자 (default: ":id")

      // Stimulus value 이름 — this.xxxValue 로 접근
      listUrlTemplate: "contactListUrlTemplateValue",
      batchUrlTemplate: "contactBatchUrlTemplateValue",

      entityLabel: "거래처",     // "거래처을(를) 먼저 선택해주세요." 자동 생성
      saveMessage: "거래처 담당자 데이터가 저장되었습니다.",
      fetchErrorMessage: "담당자 목록 조회에 실패했습니다.",

      // FK 자동 주입 — addDetailRow() 시 마스터 PK를 신규행에 자동 삽입
      // true → { [masterKeyField]: currentMasterKeyValue } 자동 계산
      // object → 직접 지정 (예: { code: this.selectedCodeValue })
      fkInjection: true,    // (default: true) 마스터 PK를 신규행에 자동 주입

      onAdded: null,        // (optional) 행 추가 후 훅 (rowData) => {}
      onSaveSuccess: null   // (optional) 저장 성공 후 훅. 기본: reloadXxxRows()
    },
    {
      role: "workplaces",
      masterKeyField: "bzac_cd",
      placeholder: ":id",
      listUrlTemplate: "workplaceListUrlTemplateValue",
      batchUrlTemplate: "workplaceBatchUrlTemplateValue",
      entityLabel: "거래처",
      saveMessage: "거래처 작업장 데이터가 저장되었습니다.",
      fetchErrorMessage: "작업장 목록 조회에 실패했습니다."
    }
  ]
}
```

---

### 4.2 자동 생성 메서드 목록

`detailGrids()` 배열에서 role: "contacts" 선언 시 아래가 **자동 생성**됨:

| 자동 생성 메서드 | 동작 |
|---|---|
| `get contactManager()` | `this.gridManager("contacts")` |
| `addContactRow()` | 매니저 체크 → 마스터 변경 체크 → 선택 체크 → FK 자동 주입 → addRow |
| `deleteContactRows()` | 매니저 체크 → 마스터 변경 체크 → deleteRows |
| `saveContactRows()` | 매니저 체크 → 마스터 변경 체크 → 선택 체크 → URL 생성 → saveRowsWith |
| `fetchContactRows(rowData)` | rowData 유효성 검사 → URL 생성 → fetchJson → 에러 핸들링 |
| `reloadContactRows(key?)` | fetchContactRows → setManagerRowData |
| `clearContactRows()` | setManagerRowData(manager, []) |

`masterConfig()` 선언 시 아래가 **자동 생성/처리**됨:

| 자동 생성 메서드/처리 | 동작 |
|---|---|
| `get masterManager()` | `this.gridManager("master")` |
| `refreshSelectedLabel()` | refreshSelectionLabel(labelTarget, value, entity, emptyMsg) |
| `blockDetailActionIfMasterChanged()` | blockIfPendingChanges(masterManager, entityLabel) |
| `onMasterRowChanged(rowData)` | currentMasterRow 갱신 → key 갱신 → 라벨 갱신 → (폼 동기화) |
| `beforeSearchReset()` | key 초기화 → 라벨 초기화 → (validation 초기화) → (폼 초기화) |
| `addMasterRow()` | addRow(masterManager) + firstEditCol + onAdded 훅 (기본: onMasterRowChanged) |
| `deleteMasterRows()` | deleteRows(masterManager) |
| `saveMasterRows()` | saveRowsWith(masterManager, batchUrl, saveMessage) |

---

### 4.3 `gridRoles()`에서 detailLoader 단순화

`BaseGridController`가 제공하는 `loadDetailRows(role, rowData)` 헬퍼를 사용하면
detailLoader를 1줄로 줄일 수 있다.

```js
// 기존 (16줄)
detailLoader: async (rowData) => {
  const code = rowData?.code
  const hasLoadableCode = Boolean(code) && !rowData?.__is_deleted && !rowData?.__is_new
  if (!hasLoadableCode) return []
  try {
    const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":code", code)
    const rows = await fetchJson(url)
    return Array.isArray(rows) ? rows : []
  } catch {
    showAlert("상세코드 목록 조회에 실패했습니다.")
    return []
  }
}

// 신규 (1줄) — detailGrids()에 role: "detail" 설정 후
detailLoader: (rowData) => this.loadDetailRows("detail", rowData)
```

`onMasterRowChange`도 단순화:

```js
// 기존 (6줄)
onMasterRowChange: (rowData) => {
  this.selectedCodeValue = rowData?.code || ""
  this.refreshSelectedCodeLabel()
  this.clearDetailRows()
}

// 신규 (1줄) — masterConfig().key 설정 후
onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData)
```

---

## 5. 구현 설계 (BaseGridController 섹션별)

### 5.1 마스터-디테일 자동화 — 섹션 3 구현

```js
// BaseGridController 내부 — 섹션 3

// connect()에서 호출
#initMasterDetail() {
  this._masterCfg = this.masterConfig?.() || null
  this._detailCfgs = this.detailGrids?.() || []
  this.#generateMasterMethods()
  this.#generateDetailMethods()
}

// 마스터 행 변경 시 공통 처리 (gridRoles의 onMasterRowChange에서 호출)
onMasterRowChanged(rowData) {
  const cfg = this._masterCfg
  if (!cfg) return

  if (cfg.onRowChange?.trackCurrentRow !== false) {
    this.currentMasterRow = rowData || null
  }

  const keyField = cfg.key?.field
  const stateProp = cfg.key?.stateProperty
  if (keyField && stateProp) {
    this[stateProp] = rowData?.[keyField] || ""
  }

  this.refreshSelectedLabel()

  if (cfg.onRowChange?.syncForm) {
    if (rowData) {
      this.fillDetailForm?.(rowData)
    } else {
      this.clearDetailForm?.()
    }
  }
}

// 선택 라벨 갱신
refreshSelectedLabel() {
  const cfg = this._masterCfg?.key
  if (!cfg) return
  const targetGetter = cfg.labelTarget + "Target"
  const hasGetter = "has" + cfg.labelTarget.charAt(0).toUpperCase() + cfg.labelTarget.slice(1) + "Target"
  if (!this[hasGetter]) return
  refreshSelectionLabel(this[targetGetter], this[cfg.stateProperty], cfg.entityLabel, cfg.emptyMessage)
}

// detailLoader 팩토리 — detailGrids() 설정 기반으로 fetch 처리
async loadDetailRows(role, rowData) {
  const cfg = this._detailCfgs?.find(d => d.role === role)
  if (!cfg) return []

  const keyField = cfg.masterKeyField
  const key = rowData?.[keyField]
  if (!key || rowData?.__is_deleted || rowData?.__is_new) return []

  try {
    const template = this[cfg.listUrlTemplate]
    const url = buildTemplateUrl(template, cfg.placeholder || ":id", key)
    const rows = await fetchJson(url)
    return Array.isArray(rows) ? rows : []
  } catch {
    showAlert(cfg.fetchErrorMessage || "데이터 조회에 실패했습니다.")
    return []
  }
}

#generateDetailMethods() {
  const details = this._detailCfgs || []
  const ownProto = Object.getPrototypeOf(this)
  // prototype 메서드 + 인스턴스 필드 메서드(예: foo = () => {}) 모두 충돌 보호
  const hasSubclassMethod = (name) =>
    typeof ownProto?.[name] === "function" || typeof this[name] === "function"

  details.forEach((cfg) => {
    const role = cfg.role
    // "contacts" → "Contact", "workplaces" → "Workplace", "detail" → "Detail"
    const Name = role.charAt(0).toUpperCase() + role.slice(1).replace(/s$/, "")
    if (!Name) return

    // getter: this.contactManager
    const alias = cfg.managerAlias || (role.replace(/s$/, "") + "Manager")
    if (!Object.getOwnPropertyDescriptor(ownProto, alias)) {
      Object.defineProperty(ownProto, alias, {
        get() { return this.gridManager(role) },
        configurable: true
      })
    }

    // add{Name}Row()
    const addMethod = "add" + Name + "Row"
    if (!hasSubclassMethod(addMethod)) {
      this[addMethod] = () => {
        const mgr = this.gridManager(role)
        if (!mgr) return
        if (this.blockDetailActionIfMasterChanged?.()) return
        const keyProp = this._masterCfg?.key?.stateProperty
        const keyValue = keyProp ? this[keyProp] : null
        if (keyProp && !keyValue) {
          showAlert((cfg.entityLabel || "") + "을(를) 먼저 선택해주세요.")
          return
        }

        // FK 자동 주입 — fkInjection 설정에 따라 신규행에 마스터 PK 삽입
        let overrides = {}
        if (cfg.fkInjection !== false) {
          if (cfg.fkInjection && typeof cfg.fkInjection === "object") {
            overrides = cfg.fkInjection  // 직접 지정된 overrides 사용
          } else {
            overrides = { [cfg.masterKeyField]: keyValue }
          }
        }

        this.addRow({ manager: mgr, overrides, onAdded: cfg.onAdded })
      }
    }

    // delete{Name}Rows()
    const deleteMethod = "delete" + Name + "Rows"
    if (!hasSubclassMethod(deleteMethod)) {
      this[deleteMethod] = () => {
        const mgr = this.gridManager(role)
        if (!mgr) return
        if (this.blockDetailActionIfMasterChanged?.()) return
        this.deleteRows({ manager: mgr })
      }
    }

    // save{Name}Rows()
    const saveMethod = "save" + Name + "Rows"
    if (!hasSubclassMethod(saveMethod)) {
      this[saveMethod] = async () => {
        const mgr = this.gridManager(role)
        if (!mgr) return
        if (this.blockDetailActionIfMasterChanged?.()) return
        const keyProp = this._masterCfg?.key?.stateProperty
        const keyValue = keyProp ? this[keyProp] : null
        if (!keyValue) {
          showAlert((cfg.entityLabel || "") + "을(를) 먼저 선택해주세요.")
          return
        }
        const template = this[cfg.batchUrlTemplate]
        const batchUrl = buildTemplateUrl(template, cfg.placeholder || ":id", keyValue)
        await this.saveRowsWith({
          manager: mgr,
          batchUrl,
          saveMessage: cfg.saveMessage,
          onSuccess: cfg.onSaveSuccess || (() => this["reload" + Name + "Rows"](keyValue))
        })
      }
    }

    // fetch{Name}Rows(rowData)
    if (!hasSubclassMethod("fetch" + Name + "Rows")) {
      this["fetch" + Name + "Rows"] = (rowData) => this.loadDetailRows(role, rowData)
    }

    // reload{Name}Rows(key?)
    if (!hasSubclassMethod("reload" + Name + "Rows")) {
      this["reload" + Name + "Rows"] = async (key) => {
        const actualKey = key ?? this[this._masterCfg?.key?.stateProperty]
        if (!actualKey) return
        const fakeRowData = { [cfg.masterKeyField]: actualKey }
        const rows = await this.loadDetailRows(role, fakeRowData)
        setManagerRowData(this.gridManager(role), rows)
      }
    }

    // clear{Name}Rows()
    if (!hasSubclassMethod("clear" + Name + "Rows")) {
      this["clear" + Name + "Rows"] = () => {
        setManagerRowData(this.gridManager(role), [])
      }
    }
  })
}

#generateMasterMethods() {
  const cfg = this._masterCfg
  if (!cfg) return
  const ownProto = Object.getPrototypeOf(this)
  const hasSubclassMethod = (name) =>
    typeof ownProto?.[name] === "function" || typeof this[name] === "function"

  const role = cfg.role || "master"
  const entityLabel = cfg.key?.entityLabel || "마스터"

  // this.masterManager getter
  if (!Object.getOwnPropertyDescriptor(ownProto, "masterManager")) {
    Object.defineProperty(ownProto, "masterManager", {
      get() { return this.gridManager(role) },
      configurable: true
    })
  }

  // blockDetailActionIfMasterChanged()
  if (!hasSubclassMethod("blockDetailActionIfMasterChanged")) {
    this.blockDetailActionIfMasterChanged = () =>
      blockIfPendingChanges(this.gridManager(role), entityLabel)
  }

  // beforeSearchReset() — BaseGridController 훅 오버라이드
  if (!hasSubclassMethod("beforeSearchReset")) {
    this.beforeSearchReset = () => {
      const keyProp = cfg.key?.stateProperty
      if (keyProp) this[keyProp] = ""
      this.currentMasterRow = null
      this.refreshSelectedLabel()
      if (cfg.beforeSearch?.clearValidation) this.clearValidationErrors?.()
      if (cfg.beforeSearch?.clearForm || cfg.onRowChange?.syncForm) this.clearDetailForm?.()
    }
  }

  if (!hasSubclassMethod("addMasterRow")) {
    this.addMasterRow = (opts = {}) => {
      const addOpts = { manager: this.gridManager(role), ...opts }
      if (cfg.firstEditCol && !addOpts.firstEditCol) {
        addOpts.firstEditCol = cfg.firstEditCol
      }
      // onAdded: 서브클래스 지정 > masterConfig().onAdded > 기본(onMasterRowChanged)
      if (!addOpts.onAdded) {
        addOpts.onAdded = cfg.onAdded || ((rowData) => this.onMasterRowChanged(rowData))
      }
      this.addRow(addOpts)
    }
  }
  if (!hasSubclassMethod("deleteMasterRows")) {
    this.deleteMasterRows = () => this.deleteRows({ manager: this.gridManager(role) })
  }
  if (!hasSubclassMethod("saveMasterRows")) {
    this.saveMasterRows = async () => {
      await this.saveRowsWith({
        manager: this.gridManager(role),
        batchUrl: this[cfg.batchUrl],
        saveMessage: cfg.saveMessage,
        onSuccess: () => this.refreshGrid(role)
      })
    }
  }
}
```

---

### 5.2 Validation UI — 섹션 4 구현

```js
// BaseGridController 내부 — 섹션 4
// validationBox / validationList target이 없는 화면에서는 자동으로 no-op 처리

showValidationErrors({ errors = [], firstError = null, summary = "", manager = null } = {}) {
  if (!this.hasValidationBoxTarget || !this.hasValidationListTarget) return false

  // 선택 훅 — 탭 활성화 등 화면별 커스텀 UX
  this.beforeShowValidationErrors?.({ errors, firstError, summary, manager })

  const list = Array.isArray(errors) ? errors : []
  const maxItems = 10
  const visible = list.slice(0, maxItems)

  if (this.hasValidationSummaryTarget) {
    this.validationSummaryTarget.textContent = summary || "입력값을 확인해주세요."
  }

  this.validationListTarget.innerHTML = ""
  visible.forEach((error) => {
    const item = document.createElement("li")
    item.textContent = this.#formatValidationLine(error)
    this.validationListTarget.appendChild(item)
  })

  if (list.length > maxItems) {
    const more = document.createElement("li")
    more.textContent = `외 ${list.length - maxItems}건`
    this.validationListTarget.appendChild(more)
  }

  this.validationBoxTarget.hidden = false
  this.validationBoxTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
  return true
}

clearValidationErrors() {
  if (!this.hasValidationBoxTarget) return
  this.validationBoxTarget.hidden = true
  if (this.hasValidationSummaryTarget) this.validationSummaryTarget.textContent = ""
  if (this.hasValidationListTarget) this.validationListTarget.innerHTML = ""
}

#formatValidationLine(error) {
  const scopeLabel = error?.scope === "insert" ? "추가" : "수정"
  const rowLabel = Number.isInteger(error?.rowIndex) ? `${error.rowIndex + 1}행` : "행"
  const message = (error?.message || "입력값을 확인해주세요.").toString()
  return `[${scopeLabel} ${rowLabel}] ${message}`
}
```

`static targets`에 추가:
```js
static targets = ["grid", "validationBox", "validationSummary", "validationList"]
```

---

## 6. 리팩토링 Before / After

### 6.1 code_grid_controller.js (413줄 → 약 80줄)

#### After (설정만 선언)

```js
import BaseGridController from "controllers/base_grid_controller"

export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedCodeLabel"]
  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    detailBatchUrlTemplate: String,
    detailListUrlTemplate: String,
    selectedCode: String
  }

  connect() {
    super.connect()
    this.refreshSelectedLabel()
  }

  // === 설정 선언부 (전부) ===

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "코드 데이터가 저장되었습니다.",
      key: {
        field: "code",
        stateProperty: "selectedCodeValue",
        labelTarget: "selectedCodeLabel",
        entityLabel: "코드",
        emptyMessage: "코드를 먼저 선택해주세요."
      },
      onRowChange: { trackCurrentRow: false, syncForm: false },
      beforeSearch: { clearValidation: false, clearForm: false }
    }
  }

  detailGrids() {
    return [{
      role: "detail",
      masterKeyField: "code",
      placeholder: ":code",
      fkInjection: true,     // addDetailRow() 시 { code: selectedCodeValue } 자동 주입
      listUrlTemplate: "detailListUrlTemplateValue",
      batchUrlTemplate: "detailBatchUrlTemplateValue",
      entityLabel: "코드",
      saveMessage: "상세코드 데이터가 저장되었습니다.",
      fetchErrorMessage: "상세코드 목록 조회에 실패했습니다.",
      onSaveSuccess: () => this.refreshGrid("master")
    }]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "code"
      },
      detail: {
        target: "detailGrid",
        manager: this.detailManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),  // 1줄
        detailLoader: (rowData) => this.loadDetailRows("detail", rowData)   // 1줄
      }
    }
  }

  // GridCrudManager 설정 — 비즈니스 필드 정의 (유지)
  masterManagerConfig() { /* 기존 유지 */ }
  detailManagerConfig() { /* 기존 유지 */ }
}

// connect() 완료 후 BaseGridController가 자동 생성하는 메서드:
// this.masterManager, this.detailManager (getter)
// this.addMasterRow(), this.deleteMasterRows(), this.saveMasterRows()
// this.addDetailRow(), this.deleteDetailRows(), this.saveDetailRows()
// this.fetchDetailRows(), this.reloadDetailRows(), this.clearDetailRows()
// this.blockDetailActionIfMasterChanged(), this.beforeSearchReset()
// this.refreshSelectedLabel(), this.onMasterRowChanged()
```

---

### 6.2 client_grid_controller.js (937줄 → 약 180줄)

#### After (설정만 선언)

```js
export default class extends BaseGridController {
  static targets = [
    ...BaseGridController.targets,
    "masterGrid", "contactsGrid", "workplacesGrid",
    "selectedClientLabel",
    "detailField", "detailGroupField", "detailSectionField",
    "tabButton", "tabPanel"
    // "validationBox", "validationSummary", "validationList" — BaseGridController.targets에 포함됨
  ]

  static values = {
    ...BaseGridController.values,
    masterBatchUrl: String,
    contactBatchUrlTemplate: String, contactListUrlTemplate: String,
    workplaceBatchUrlTemplate: String, workplaceListUrlTemplate: String,
    sectionMap: Object,
    selectedClient: String
  }

  connect() {
    super.connect()
    bindDependentSelects(this, this.#searchDependentConfig())
    bindDetailFieldEvents(this, null, (event) => {
      syncDetailFieldUtil(event, this)
      const key = detailFieldKey(event.currentTarget)
      if (this.isPopupCodeKey(key)) this.syncPopupFieldPresentation(event.currentTarget, key, event.currentTarget.value)
      if (key === "bzac_sctn_grp_cd") this.handleDetailGroupChange(event)
    })
    this._onPopupSelected = (event) => this.handlePopupSelected(event)
    this.element.addEventListener("search-popup:selected", this._onPopupSelected)
    this.activateTab("basic")
  }

  disconnect() {
    unbindDependentSelects(this)
    unbindDetailFieldEvents(this)
    if (this._onPopupSelected) {
      this.element.removeEventListener("search-popup:selected", this._onPopupSelected)
    }
    super.disconnect()
  }

  // === 설정 선언부 ===

  masterConfig() {
    return {
      role: "master",
      batchUrl: "masterBatchUrlValue",
      saveMessage: "거래처 데이터가 저장되었습니다.",
      key: {
        field: "bzac_cd",
        stateProperty: "selectedClientValue",
        labelTarget: "selectedClientLabel",
        entityLabel: "거래처",
        emptyMessage: "거래처를 먼저 선택하세요."
      },
      onRowChange: { trackCurrentRow: true, syncForm: true },
      beforeSearch: { clearValidation: true, clearForm: true }
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
        fetchErrorMessage: "담당자 목록 조회에 실패했습니다."
      },
      {
        role: "workplaces",
        masterKeyField: "bzac_cd",
        placeholder: ":id",
        listUrlTemplate: "workplaceListUrlTemplateValue",
        batchUrlTemplate: "workplaceBatchUrlTemplateValue",
        entityLabel: "거래처",
        saveMessage: "거래처 작업장 데이터가 저장되었습니다.",
        fetchErrorMessage: "작업장 목록 조회에 실패했습니다."
      }
    ]
  }

  gridRoles() {
    return {
      master: {
        target: "masterGrid",
        manager: this.masterManagerConfig(),
        masterKeyField: "bzac_cd"
      },
      contacts: {
        target: "contactsGrid",
        manager: this.contactManagerConfig(),
        parentGrid: "master",
        onMasterRowChange: (rowData) => this.onMasterRowChanged(rowData),
        detailLoader: (rowData) => this.loadDetailRows("contacts", rowData)
      },
      workplaces: {
        target: "workplacesGrid",
        manager: this.workplaceManagerConfig(),
        parentGrid: "master",
        detailLoader: (rowData) => this.loadDetailRows("workplaces", rowData)
      }
    }
  }

  // 탭 활성화 훅 — showValidationErrors 전에 호출됨
  beforeShowValidationErrors({ manager }) {
    if (manager === this.contactManager) { this.activateTab("contacts"); return }
    if (manager === this.workplaceManager) { this.activateTab("workplaces"); return }
    // ...기타 탭 처리
  }

  // GridCrudManager 설정 / 폼 동기화 / 팝업 — 화면별 특수 로직 (유지)
  masterManagerConfig() { /* ... */ }
  contactManagerConfig() { /* ... */ }
  workplaceManagerConfig() { /* ... */ }
  fillDetailForm(rowData) { /* popup 특수처리 포함 */ }
  clearDetailForm() { /* popup 특수처리 포함 */ }
  handlePopupSelected(event) { /* ... */ }
  switchTab(event) { switchTab(event, this) }
  activateTab(tab) { activateTab(tab, this) }
}
```

---

## 7. 구현 우선순위 및 작업 목록

### Phase 1: BaseGridController에 Validation UI 통합 (0.5일)

| # | 작업 | 상세 |
|---|---|---|
| 1 | `static targets`에 `validationBox`, `validationSummary`, `validationList` 추가 | `base_grid_controller.js` |
| 2 | `showValidationErrors()` / `clearValidationErrors()` 메서드 직접 추가 | `base_grid_controller.js` 섹션 4 |
| 3 | `concerns/validation_mixin.js` 파일 삭제 계획 수립 (현재 사용처 확인 후) | — |

### Phase 2: BaseGridController에 마스터-디테일 자동화 통합 (2~3일)

| # | 작업 | 상세 |
|---|---|---|
| 4 | `#initMasterDetail()` 구현 및 `connect()` 훅 연결 | `base_grid_controller.js` 섹션 3 |
| 5 | `loadDetailRows()`, `onMasterRowChanged()`, `refreshSelectedLabel()` 구현 | `base_grid_controller.js` 섹션 3 |
| 6 | `#generateMasterMethods()` 구현 | `base_grid_controller.js` 섹션 3 |
| 7 | `#generateDetailMethods()` 구현 | `base_grid_controller.js` 섹션 3 |

### Phase 3: ModalMixin / ExcelDownloadable 통합 (1일)

| # | 작업 | 상세 |
|---|---|---|
| 8 | `ModalMixin` 메서드를 `BaseGridController` 섹션 5로 이동 | `base_grid_controller.js` |
| 9 | `ExcelDownloadable` 메서드를 `BaseGridController` 섹션 6으로 이동 | `base_grid_controller.js` |
| 10 | `Object.assign` 3줄 제거, 빈 파일들 삭제 | `concerns/modal_mixin.js`, `concerns/excel_downloadable.js` |

### Phase 4: 기존 컨트롤러 마이그레이션 (1~2일/개)

| # | 대상 | 예상 결과 |
|---|---|---|
| 11 | `system/code_grid_controller.js` | 413줄 → ~80줄 (-80%) |
| 12 | `std/client_grid_controller.js` | 937줄 → ~180줄 (-81%) |
| 13 | 신규 컨트롤러 개발 시 새 패턴 적용 | — |

### Phase 5: 테스트/검증 (1일)

| # | 작업 | 기준 |
|---|---|---|
| 14 | 자동 생성/충돌 테스트 | 서브클래스 메서드가 자동 생성으로 덮어써지지 않는지 |
| 15 | 마스터-디테일 연동 테스트 | `onMasterRowChanged` + `loadDetailRows` 동작 순서 |
| 16 | 검색 초기화/검증 UI 테스트 | `beforeSearchReset`, `beforeShowValidationErrors` 훅 보존 |

---

## 8. 네이밍 컨벤션 (자동 생성 메서드명)

role `"contacts"` (복수 s 제거 → "Contact") 기준:

| 패턴 | 생성 이름 |
|---|---|
| getter | `contactManager` |
| add | `addContactRow()` |
| delete | `deleteContactRows()` |
| save | `saveContactRows()` |
| fetch | `fetchContactRows(rowData)` |
| reload | `reloadContactRows(key?)` |
| clear | `clearContactRows()` |

role `"detail"` (s 없음 → "Detail") 기준:

| 패턴 | 생성 이름 |
|---|---|
| getter | `detailManager` |
| add | `addDetailRow()` |
| delete | `deleteDetailRows()` |
| save | `saveDetailRows()` |
| fetch | `fetchDetailRows(rowData)` |
| reload | `reloadDetailRows(key?)` |
| clear | `clearDetailRows()` |

**role 네이밍 제약**:
- 자동 단수화 규칙은 `replace(/s$/, "")` 기준이다.
- 따라서 `contacts`, `workplaces`, `detail`처럼 규칙적인 role 이름 사용을 권장한다.
- `status`처럼 단수/복수 판단이 모호한 이름은 `managerAlias` 또는 별도 메서드명 override를 사용한다.

**HTML `data-action` 속성은 변경 없음** — 자동 생성된 메서드명이 기존과 동일하므로.

---

## 9. 주의사항 및 제약

1. **`#initMasterDetail()` 호출 타이밍**: `BaseGridController.connect()` 마지막에 호출.
   서브클래스의 `connect()`에서 `super.connect()` 호출 후 자동으로 완료됨.

2. **메서드 충돌 보호**: 자동 생성 전 `hasSubclassMethod()` 체크로 서브클래스에 같은 이름의
   메서드가 있으면 생성을 건너뜀. (`prototype` + 인스턴스 필드 메서드 모두 검사)
   서브클래스 커스텀 로직이 안전하게 보존됨.

3. **`syncForm: true` 시**: `fillDetailForm()` / `clearDetailForm()` 메서드가 서브클래스에
   구현되어 있어야 함. 없으면 no-op 처리.

4. **Validation UI 훅**: `beforeShowValidationErrors({ errors, firstError, summary, manager })`를
   서브클래스에 선언하면 탭 활성화 등 화면별 UX를 주입할 수 있음.

5. **ModalMixin / ExcelDownloadable 이전 호환**: Phase 3 작업 전까지는 `Object.assign` 방식을
   유지하다가 메서드 이전이 완료된 후 `Object.assign` 줄을 제거함.

6. **role 이름 제약**: 자동 생성 이름은 단순 `s` 제거 규칙을 사용한다.
   불규칙 네이밍(role: `status` 등)이 필요하면 `managerAlias`/수동 메서드 override를 사용한다.

7. **`disconnect()` 정리**: `#initMasterDetail()`에서 동적으로 생성한 메서드/상태는
   `disconnect()` 시점에 정리해야 한다. `BaseGridController.disconnect()`에 아래 추가:
   ```js
   disconnect() {
     // ... 기존 정리 로직 ...
     // 마스터-디테일 동적 메서드 정리
     if (this._detailCfgs) {
       this._detailCfgs.forEach((cfg) => {
         const Name = cfg.role.charAt(0).toUpperCase() + cfg.role.slice(1).replace(/s$/, "")
         delete this["add" + Name + "Row"]
         delete this["delete" + Name + "Rows"]
         delete this["save" + Name + "Rows"]
         delete this["fetch" + Name + "Rows"]
         delete this["reload" + Name + "Rows"]
         delete this["clear" + Name + "Rows"]
       })
     }
     delete this.blockDetailActionIfMasterChanged
     delete this.beforeSearchReset
     delete this.addMasterRow
     delete this.deleteMasterRows
     delete this.saveMasterRows
     this._masterCfg = null
     this._detailCfgs = null
     this.currentMasterRow = null
   }
   ```

8. **`gridRoles()` 자동 연결 가능성**: 향후 `detailGrids()` 선언만으로 `gridRoles()` 내의
   `detailLoader`와 `onMasterRowChange`를 자동 연결하는 것도 가능하다. 현재는 서브클래스가
   `gridRoles()`에서 1줄 위임 코드를 명시적으로 작성하는 방식을 채택했으며, 이는 흐름이
   명확하여 디버깅이 쉽기 때문이다. Phase 5 이후 안정화되면 자동 연결을 검토할 수 있다.

9. **`manager` getter 브릿지**: `grid_form_utils.js`의 `fillDetailForm()` 등에서
   `controller.manager`로 접근하는 코드가 있을 수 있다. `masterConfig()`가 선언된 경우
   `get manager()` → `this.masterManager`로 자동 브릿지를 생성하거나, `grid_form_utils`가
   `gridManager(role)` API를 직접 사용하도록 수정한다. 추후 구현 시 확인 필요.

10. **통합 범위 제외 파일**: `concerns/attachment_mixin.js`와 `concerns/trix_mixin.js`는
    이번 통합 대상에 포함되지 않는다. 이 mixin들은 `BaseGridController`가 아닌 특정 에디터
    컨트롤러에서만 사용되므로, 별도 파일로 유지하는 것이 올바른 설계이다.

---

## 10. 최종 파일 변화 요약

### 삭제될 파일

```
controllers/concerns/modal_mixin.js        → BaseGridController 섹션 5로 흡수
controllers/concerns/excel_downloadable.js → BaseGridController 섹션 6으로 흡수
```

### 신규 생성 없음

별도 파일 생성 없이 `base_grid_controller.js` 하나에 모두 통합.

### 변화 규모

```
변경 전                              변경 후
─────────────────────────────────   ──────────────────────────────────────────
base_grid_controller.js  (654줄)  → base_grid_controller.js  (~900줄, 섹션 구분)
concerns/modal_mixin.js  (344줄)  → (삭제)
concerns/excel_downloadable.js (44줄) → (삭제)
─────────────────────────────────   ──────────────────────────────────────────
서브클래스 컨트롤러 평균  (~500줄) → 서브클래스 컨트롤러 평균 (~100줄, -80%)
```

### 서브클래스 개발 패턴 (통합 후)

```js
// 새 마스터-디테일 화면 — 선언만 하면 됨
export default class extends BaseGridController {
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedLabel"]
  static values  = { ...BaseGridController.values, masterBatchUrl: String, ... }

  masterConfig() { return { role: "master", key: { field: "pk_cd", ... }, ... } }
  detailGrids()  { return [{ role: "detail", masterKeyField: "pk_cd", ... }] }
  gridRoles()    { return {
    master: { target: "masterGrid", manager: this.masterManagerConfig(), masterKeyField: "pk_cd" },
    detail: { target: "detailGrid", manager: this.detailManagerConfig(), parentGrid: "master",
      onMasterRowChange: (r) => this.onMasterRowChanged(r),
      detailLoader:      (r) => this.loadDetailRows("detail", r) }
  }}

  masterManagerConfig() { return { pkFields: ["pk_cd"], fields: { ... }, ... } }
  detailManagerConfig() { return { pkFields: ["seq"], fields: { ... }, ... } }
}
// → BaseGridController가 나머지 모두 자동 처리
```
