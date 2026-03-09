# ModalMixin 공통화 리팩토링 설계서

> **대상 파일**: `app/javascript/controllers/concerns/modal_mixin.js`
> **연관 컨트롤러**: `menu_crud_controller.js`, `notice_crud_controller.js`, `user_crud_controller.js`
> **작성일**: 2026-03-09
> **목적**: CRUD 모달 컨트롤러의 반복 코드를 `ModalMixin`으로 공통화하여 유지보수성 향상

---

## 1. 현황 분석 — 반복 패턴 목록

### 1.1 `connect()` / `disconnect()`

세 컨트롤러 모두 동일한 구조를 가진다.

```js
// menu_crud, user_crud, notice_crud 공통
connect() {
  super.connect()
  this.handleDelete = this.handleDelete.bind(this)      // ← 항상 동일
  this.connectBase({ events: [ ...이벤트 목록... ] })   // ← 이벤트 목록만 다름
}

disconnect() {
  this.disconnectBase()
  super.disconnect()
}
```

**문제점**: `handleDelete.bind` + `connectBase` 호출 패턴이 모든 컨트롤러에서 반복됨.
**공통화 방안**: `connectModal({ events })` 헬퍼를 ModalMixin에 추가하여 bind+connectBase를 한 번에 처리.

---

### 1.2 `openCreate()` / `openAdd()`

```js
// 공통 흐름: reset → 제목 설정 → 기본값 주입 → readOnly 조정 → mode='create' → 모달 열기
openCreate() {
  this.resetForm()
  this.modalTitleTarget.textContent = "XXX 추가"
  this.setFieldValues({ ... })              // 기본값 (선택)
  this.fieldXxxTarget.readOnly = false      // readOnly 조정 (선택)
  this.mode = "create"
  this.openModal()
}
```

**공통화 방안**: `openCreateModal(options)` 헬퍼 추가.

---

### 1.3 `handleEdit`

```js
// 공통 흐름: detail에서 데이터 추출 → reset → 제목 설정 → id 세팅 → setFieldValues → mode='update' → 모달 열기
handleEdit = (event) => {
  const data = event.detail.XxxData        // 이름만 다름
  this.resetForm()
  this.modalTitleTarget.textContent = "XXX 수정"
  this.fieldIdTarget.value = data.id ?? ""
  this.setFieldValues({ ...data 필드... })
  this.mode = "update"
  this.openModal()
}
```

**공통화 방안**: `openEditModal(data, options)` 헬퍼 추가. 컨트롤러는 이벤트 핸들러에서 data를 꺼내 호출.

---

### 1.4 `resetForm()`

```js
// 공통 흐름: form.reset → fieldId 초기화 → 기본값 주입 → 추가 훅(사진 초기화 등)
resetForm() {
  this.formTarget.reset()
  this.fieldIdTarget.value = ""
  this.setFieldValues({ ... })             // 기본값 (선택)
  // 컨트롤러별 추가 로직 (removePhoto, resetAttachment 등)
}
```

**공통화 방안**: `resetFormBase(options)` 헬퍼 추가. 컨트롤러별 추가 로직은 `hooks` 배열로 처리.

---

### 1.5 `save()` — 멀티파트 지원

현재 `modal_mixin.js`의 `save()`는 JSON 페이로드만 지원한다.
`notice_crud`, `user_crud`는 FormData(multipart) 방식의 `save()`를 오버라이드하고 있어 코드 중복이 발생한다.

```js
// notice_crud, user_crud 공통 save() 패턴
async save() {
  const formData = new FormData(this.formTarget)
  // 컨트롤러별 추가 데이터 첨부 (첨부파일 ID, 사진 등)
  const id = this.fieldIdTarget.value || null
  const isCreate = this.mode === "create"
  const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
  const method = isCreate ? "POST" : "PATCH"

  const { response, result } = await this.requestJson(url, {
    method, body: formData, isMultipart: true
  })
  // 응답 처리 (showAlert, closeModal, _refreshModalGrid)
}
```

**공통화 방안**: `save()`를 `buildMultipartFormData()` 훅 패턴으로 확장.

---

## 2. 공통화 함수 설계

### 2.1 `connectModal(options)` — connect 헬퍼

```js
/**
 * connect()에서 호출하는 모달 초기화 헬퍼.
 * handleDelete를 자동 bind하고 이벤트를 등록한다.
 *
 * @param {Object} options
 * @param {Array<{name: string, handler: Function}>} options.events    - 이벤트 목록
 * @param {Array<Function>} [options.initHooks]  - 추가 초기화 훅 (예: initAttachment)
 *
 * @example
 * connect() {
 *   super.connect()
 *   this.connectModal({
 *     events: [
 *       { name: "menu-crud:add-child", handler: this.handleAddChild },
 *       { name: "menu-crud:edit",      handler: this.handleEdit },
 *       { name: "menu-crud:delete",    handler: this.handleDelete }
 *     ],
 *     initHooks: [this.initAttachment]   // optional
 *   })
 * }
 */
connectModal({ events = [], initHooks = [] } = {}) {
  this.handleDelete = this.handleDelete.bind(this)
  initHooks.forEach(hook => hook.call(this))
  this.connectBase({ events })
}
```

---

### 2.2 `disconnectModal()` — disconnect 헬퍼

```js
/**
 * disconnect()에서 호출하는 모달 정리 헬퍼.
 *
 * @example
 * disconnect() {
 *   this.disconnectModal()
 *   super.disconnect()
 * }
 */
disconnectModal() {
  this.disconnectBase()
}
```

---

### 2.3 `openCreateModal(options)` — 신규 모달 열기

```js
/**
 * 신규 등록 모달을 여는 공통 헬퍼.
 *
 * @param {Object} options
 * @param {string} options.title                - 모달 제목
 * @param {Object} [options.defaults]           - create 모드에서만 추가로 덮어쓸 기본값
 * @param {HTMLElement[]} [options.readOnly]    - readOnly = true 설정할 필드 요소 배열
 * @param {HTMLElement[]} [options.readWrite]   - readOnly = false 설정할 필드 요소 배열
 * @param {Function} [options.afterReset]       - resetForm 후 추가 처리 훅
 *
 * @example
 * openCreate() {
 *   this.openCreateModal({
 *     title: "사용자 추가",
 *     readWrite: [this.fieldUserIdCodeTarget]
 *   })
 * }
 */
openCreateModal({ title, defaults = {}, readOnly = [], readWrite = [], afterReset = null } = {}) {
  this.resetForm()
  if (afterReset) afterReset.call(this)
  if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = title
  if (Object.keys(defaults).length) this.setFieldValues(defaults)
  readOnly.forEach(el => { el.readOnly = true })
  readWrite.forEach(el => { el.readOnly = false })
  this.mode = "create"
  this.openModal()
}
```

> **기본값 책임 분리**
> - `resetFormBase({ defaults })`: create/update 공통으로 항상 복원할 값
> - `openCreateModal({ defaults })`: 신규 생성 흐름에서만 추가로 덮어쓸 값
>
> 예를 들어 `work_status: "ACTIVE"`는 `resetFormBase`에만 두고,
> 메뉴의 `parent_cd`, `menu_level`처럼 생성 경로마다 달라지는 값만 `openCreateModal`에 둔다.

---

### 2.4 `openEditModal(data, options)` — 수정 모달 열기

```js
/**
 * 수정 모달을 여는 공통 헬퍼.
 *
 * @param {Object} data                         - 폼에 채울 레코드 데이터
 * @param {Object} options
 * @param {string} options.title                - 모달 제목
 * @param {Object} [options.fieldMap]           - { formField: dataKey } 매핑 (생략 시 동일 key 사용)
 * @param {Object} [options.defaults]           - data에 없는 필드의 기본값
 * @param {HTMLElement[]} [options.readOnly]    - readOnly = true 설정할 필드 요소 배열
 * @param {HTMLElement[]} [options.readWrite]   - readOnly = false 설정할 필드 요소 배열
 * @param {Function} [options.afterFill]        - setFieldValues 후 추가 처리 훅 (data를 인자로 받음)
 *
 * @example
 * handleEdit = (event) => {
 *   const data = event.detail.userData
 *   this.openEditModal(data, {
 *     title: "사용자 수정",
 *     readOnly: [this.fieldUserIdCodeTarget],
 *     afterFill: (d) => {
 *       if (d.photo_url) {
 *         this.photoPreviewTarget.src = d.photo_url
 *         this.photoRemoveBtnTarget.hidden = false
 *       }
 *     }
 *   })
 * }
 */
openEditModal(data, { title, fieldMap = null, defaults = {}, readOnly = [], readWrite = [], afterFill = null } = {}) {
  this.resetForm()
  if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = title
  if (this.hasFieldIdTarget) this.fieldIdTarget.value = data.id ?? ""

  const values = fieldMap
    ? Object.fromEntries(Object.entries(fieldMap).map(([formField, dataKey]) => [formField, data[dataKey] ?? defaults[formField] ?? ""]))
    : { ...defaults, ...Object.fromEntries(Object.entries(data).filter(([k]) => k !== "id").map(([k, v]) => [k, v ?? ""])) }

  this.setFieldValues(values)
  readOnly.forEach(el => { el.readOnly = true })
  readWrite.forEach(el => { el.readOnly = false })
  if (afterFill) afterFill.call(this, data)
  this.mode = "update"
  this.openModal()
}
```

---

### 2.5 `resetFormBase(options)` — 폼 초기화 헬퍼

```js
/**
 * resetForm()에서 호출하는 공통 폼 초기화 헬퍼.
 *
 * @param {Object} options
 * @param {Object} [options.defaults]      - create/update 공통으로 항상 복원할 기본값
 * @param {Function[]} [options.hooks]     - 추가 정리 로직 훅 배열 (예: removePhoto, resetAttachment)
 *
 * @example
 * resetForm() {
 *   this.resetFormBase({
 *     defaults: { work_status: "ACTIVE" },
 *     hooks: [this.removePhoto]
 *   })
 * }
 */
resetFormBase({ defaults = {}, hooks = [] } = {}) {
  if (this.hasFormTarget) this.formTarget.reset()
  if (this.hasFieldIdTarget) this.fieldIdTarget.value = ""
  if (Object.keys(defaults).length) this.setFieldValues(defaults)
  hooks.forEach(hook => hook.call(this))
}
```

---

### 2.6 `save()` — 멀티파트 지원 확장

기존 `save()`를 훅 패턴으로 확장한다.
컨트롤러에 `buildMultipartFormData()` 메서드가 정의되어 있으면 자동으로 multipart 방식으로 전송한다.

```js
/**
 * 저장 요청 공통 핸들러.
 *
 * 컨트롤러에 buildMultipartFormData() 가 정의된 경우 → multipart(FormData) 전송
 * 미정의 시 → 기존 JSON 페이로드 전송 (기존 동작 유지)
 *
 * buildMultipartFormData() 훅 시그니처:
 *   buildMultipartFormData(): FormData
 *
 * @example — notice_crud: AttachmentMixin의 appendRemovedAttachmentIds 활용
 * buildMultipartFormData() {
 *   const formData = new FormData(this.formTarget)
 *   this.appendRemovedAttachmentIds(formData, this.constructor.resourceName)
 *   return formData
 * }
 *
 * @example — user_crud: 사진 파일 추가
 * buildMultipartFormData() {
 *   const formData = new FormData(this.formTarget)
 *   const photoFile = this.photoInputTarget.files[0]
 *   if (photoFile) formData.append("user[photo]", photoFile)
 *   return formData
 * }
 */
async save() {
  const isMultipart = typeof this.buildMultipartFormData === "function"
  let body, id

  if (isMultipart) {
    body = this.buildMultipartFormData()
    id = this.hasFieldIdTarget && this.fieldIdTarget.value ? this.fieldIdTarget.value : null
  } else {
    const payload = this.buildJsonPayload()
    id = this.hasFieldIdTarget && this.fieldIdTarget.value ? this.fieldIdTarget.value : null
    if (id) payload.id = id
    const extractedId = payload.id
    delete payload.id
    id = extractedId
    body = { [this.constructor.resourceName]: payload }
  }

  const isCreate = this.mode === "create"
  const url = isCreate ? this.createUrlValue : this.updateUrlValue.replace(":id", id)
  const method = isCreate ? "POST" : "PATCH"

  try {
    const { response, result } = await this.requestJson(url, {
      method, body, isMultipart
    })

    if (!response.ok || !result.success) {
      showAlert("저장 실패: " + (result.errors || ["요청 처리 실패"]).join(", "))
      return
    }

    showAlert(result.message || "저장되었습니다")
    this.closeModal()
    this._refreshModalGrid()
  } catch {
    showAlert("저장 실패: 네트워크 오류")
  }
}
```

---

### 2.7 `AttachmentMixin` 계약 변경

`notice_crud_controller`는 `AttachmentMixin`의 사용 계약을 따르므로,
이번 공통화 설계는 첨부파일 믹스인의 가이드 문구까지 같이 갱신되어야 한다.

기존 계약:

```js
connect()   -> this.initAttachment()
resetForm() -> this.resetAttachment()
save()      -> this.appendRemovedAttachmentIds(formData, scope)
```

변경 계약:

```js
connect()                -> this.connectModal({ initHooks: [this.initAttachment] })
resetForm()              -> this.resetFormBase({ hooks: [this.resetAttachment] })
buildMultipartFormData() -> this.appendRemovedAttachmentIds(formData, scope)
```

즉, 영향 범위는 `notice_crud_controller.js`에 한정되지 않고
`attachment_mixin.js` 상단 주석의 사용 가이드까지 포함한다.

---

## 3. 컨트롤러별 변경 전/후 비교

### 3.1 `menu_crud_controller.js`

**변경 전 (현재)**
```js
connect() {
  super.connect()
  this.handleDelete = this.handleDelete.bind(this)
  this.connectBase({
    events: [
      { name: "menu-crud:add-child", handler: this.handleAddChild },
      { name: "menu-crud:edit",      handler: this.handleEdit },
      { name: "menu-crud:delete",    handler: this.handleDelete }
    ]
  })
}

disconnect() {
  this.disconnectBase()
  super.disconnect()
}

openCreate() {
  this.resetForm()
  this.modalTitleTarget.textContent = "최상위 메뉴 추가"
  this.setFieldValues({ parent_cd: "", menu_level: 1, menu_type: "FOLDER" })
  this.fieldMenuCdTarget.readOnly = false
  this.mode = "create"
  this.openModal()
}

handleEdit = (event) => {
  const data = event.detail.menuData
  this.resetForm()
  this.modalTitleTarget.textContent = "메뉴 수정"
  this.fieldIdTarget.value = data.id ?? ""
  this.setFieldValues({ menu_cd: data.menu_cd || "", ... })
  this.fieldMenuCdTarget.readOnly = true
  this.mode = "update"
  this.openModal()
}

resetForm() {
  this.formTarget.reset()
  this.fieldIdTarget.value = ""
  this.setFieldValues({ sort_order: 0, use_yn: "Y" })
}
```

**변경 후**
```js
connect() {
  super.connect()
  this.connectModal({
    events: [
      { name: "menu-crud:add-child", handler: this.handleAddChild },
      { name: "menu-crud:edit",      handler: this.handleEdit },
      { name: "menu-crud:delete",    handler: this.handleDelete }
    ]
  })
}

disconnect() {
  this.disconnectModal()
  super.disconnect()
}

openCreate() {
  this.openCreateModal({
    title: "최상위 메뉴 추가",
    defaults: { parent_cd: "", menu_level: 1, menu_type: "FOLDER" },
    readWrite: [this.fieldMenuCdTarget]
  })
}

handleAddChild = (event) => {
  const { parentCd, parentLevel } = event.detail
  this.openCreateModal({
    title: "하위 메뉴 추가",
    defaults: {
      parent_cd: parentCd || "",
      menu_level: Number(parentLevel || 1) + 1,
      menu_type: "MENU"
    },
    readWrite: [this.fieldMenuCdTarget]
  })
}

handleEdit = (event) => {
  const data = event.detail.menuData
  this.openEditModal(data, {
    title: "메뉴 수정",
    readOnly: [this.fieldMenuCdTarget]
  })
}

resetForm() {
  this.resetFormBase({ defaults: { sort_order: 0, use_yn: "Y" } })
}
```

> `handleAddChild` 역시 create 흐름의 한 종류이므로 공통화 대상에 포함한다.
> 이 경로를 제외하면 create 관련 중복이 절반만 제거된다.

---

### 3.2 `user_crud_controller.js`

**변경 전 (현재)**
```js
connect() {
  super.connect()
  this.handleDelete = this.handleDelete.bind(this)
  this.connectBase({
    events: [
      { name: "user-crud:edit",   handler: this.handleEdit },
      { name: "user-crud:delete", handler: this.handleDelete }
    ]
  })
}

disconnect() {
  this.disconnectBase()
  super.disconnect()
}

openCreate() {
  this.resetForm()
  this.modalTitleTarget.textContent = "사용자 추가"
  this.fieldUserIdCodeTarget.readOnly = false
  this.setFieldValues({ work_status: "ACTIVE" })
  this.mode = "create"
  this.openModal()
}

handleEdit = (event) => {
  const data = event.detail.userData
  this.resetForm()
  this.modalTitleTarget.textContent = "사용자 수정"
  this.fieldIdTarget.value = data.id ?? ""
  this.setFieldValues({ user_id_code: ..., ... })
  this.fieldUserIdCodeTarget.readOnly = true
  if (data.photo_url) { ... }
  this.mode = "update"
  this.openModal()
}

async save() {
  const formData = new FormData(this.formTarget)
  const photoFile = this.photoInputTarget.files[0]
  if (photoFile) formData.append("user[photo]", photoFile)
  // ... 중복 저장 로직 ...
}

resetForm() {
  this.formTarget.reset()
  this.fieldIdTarget.value = ""
  this.setFieldValues({ work_status: "ACTIVE" })
  this.removePhoto()
}
```

**변경 후**
```js
connect() {
  super.connect()
  this.connectModal({
    events: [
      { name: "user-crud:edit",   handler: this.handleEdit },
      { name: "user-crud:delete", handler: this.handleDelete }
    ]
  })
}

disconnect() {
  this.disconnectModal()
  super.disconnect()
}

openCreate() {
  this.openCreateModal({
    title: "사용자 추가",
    readWrite: [this.fieldUserIdCodeTarget]
  })
}

handleEdit = (event) => {
  const data = event.detail.userData
  this.openEditModal(data, {
    title: "사용자 수정",
    readOnly: [this.fieldUserIdCodeTarget],
    afterFill: (d) => {
      if (d.photo_url) {
        this.photoPreviewTarget.src = d.photo_url
        this.photoRemoveBtnTarget.hidden = false
      }
    }
  })
}

// ✅ save() 삭제 — ModalMixin의 save()가 buildMultipartFormData() 훅을 자동 인식
buildMultipartFormData() {
  const formData = new FormData(this.formTarget)
  const photoFile = this.photoInputTarget.files[0]
  if (photoFile) formData.append("user[photo]", photoFile)
  return formData
}

resetForm() {
  this.resetFormBase({
    defaults: { work_status: "ACTIVE" },
    hooks: [this.removePhoto]
  })
}
```

---

### 3.3 `notice_crud_controller.js`

**변경 전 (현재)**
```js
connect() {
  super.connect()
  this.initAttachment()
  this.handleDelete = this.handleDelete.bind(this)
  this.connectBase({
    events: [
      { name: "notice-crud:edit",   handler: this.handleEdit },
      { name: "notice-crud:delete", handler: this.handleDelete }
    ]
  })
}

disconnect() {
  this.disconnectBase()
  super.disconnect()
}

openCreate() {
  this.resetForm()
  this.modalTitleTarget.textContent = "공지사항 등록"
  this.mode = "create"
  this.openModal()
}

handleEdit = async (event) => {
  const { id } = event.detail
  // ... fetchJson으로 detail 조회 후 fillForm ...
  this.mode = "update"
  this.openModal()
}

async save() {
  const formData = new FormData(this.formTarget)
  this.appendRemovedAttachmentIds(formData, scope)
  // ... 중복 저장 로직 ...
}

resetForm() {
  this.formTarget.reset()
  this.fieldIdTarget.value = ""
  this.setRadioValue("is_top_fixed", "N")
  this.setRadioValue("is_published", "Y")
  this.setContentValue("")
  this.resetAttachment()
}
```

**변경 후**
```js
connect() {
  super.connect()
  this.connectModal({
    events: [
      { name: "notice-crud:edit",   handler: this.handleEdit },
      { name: "notice-crud:delete", handler: this.handleDelete }
    ],
    initHooks: [this.initAttachment]  // ← initAttachment를 훅으로 전달
  })
}

disconnect() {
  this.disconnectModal()
  super.disconnect()
}

openCreate() {
  this.openCreateModal({ title: "공지사항 등록" })
}

// handleEdit은 비동기 fetch 포함이라 그대로 유지 (fetchJson 후 fillForm 호출)
handleEdit = async (event) => {
  const { id } = event.detail
  if (!id) return
  this.resetForm()
  this.modalTitleTarget.textContent = "공지사항 수정"
  const url = this.updateUrlValue.replace(":id", id)
  try {
    const data = await fetchJson(url)
    this.fillForm(data)
    this.mode = "update"
    this.openModal()
  } catch {
    showAlert("상세 조회에 실패했습니다.")
  }
}

// ✅ save() 삭제 — ModalMixin의 save()가 buildMultipartFormData() 훅을 자동 인식
buildMultipartFormData() {
  const formData = new FormData(this.formTarget)
  this.appendRemovedAttachmentIds(formData, this.constructor.resourceName)
  return formData
}

resetForm() {
  this.resetFormBase({
    hooks: [
      () => this.setRadioValue("is_top_fixed", "N"),
      () => this.setRadioValue("is_published", "Y"),
      () => this.setContentValue(""),
      this.resetAttachment
    ]
  })
}
```

---

## 4. ModalMixin 추가 함수 요약

| 함수명 | 파라미터 | 설명 |
|--------|---------|------|
| `connectModal(options)` | `events`, `initHooks` | connect 시 handleDelete bind + 이벤트 등록 |
| `disconnectModal()` | — | disconnect 시 이벤트 해제 |
| `openCreateModal(options)` | `title`, `defaults`, `readOnly`, `readWrite`, `afterReset` | 신규 모달 열기 공통 흐름 |
| `openEditModal(data, options)` | `title`, `fieldMap`, `defaults`, `readOnly`, `readWrite`, `afterFill` | 수정 모달 열기 공통 흐름 |
| `resetFormBase(options)` | `defaults`, `hooks` | 폼 초기화 공통 흐름 |
| `buildMultipartFormData()` | — | **(훅)** 컨트롤러에서 구현 시 save()가 자동으로 multipart 전송 |

---

## 5. `save()` 멀티파트 지원 — 훅 패턴 흐름도

```
save() 호출
   │
   ├── buildMultipartFormData 존재? (컨트롤러에서 구현됨)
   │      ├── YES → FormData 생성 → isMultipart: true
   │      └── NO  → buildJsonPayload() → JSON body
   │
   ├── mode === "create" ? POST : PATCH
   ├── requestJson(url, { method, body, isMultipart })
   │
   ├── 성공: showAlert → closeModal → _refreshModalGrid
   └── 실패: showAlert 오류 메시지
```

---

## 6. `openEditModal` fieldMap 사용 예시

수정 이벤트의 `event.detail`에서 꺼낸 데이터 키와 폼 필드명이 다를 때 `fieldMap`을 사용한다.

```js
// event.detail.menuData = { id, menu_cd, menu_nm, ... }
handleEdit = (event) => {
  const data = event.detail.menuData
  this.openEditModal(data, {
    title: "메뉴 수정",
    // fieldMap 미지정 시 data 키를 그대로 폼 필드명으로 사용
    readOnly: [this.fieldMenuCdTarget]
  })
}
```

---

## 7. 구현 순서

1. **`modal_mixin.js` 수정**
   - `connectModal`, `disconnectModal` 추가
   - `openCreateModal`, `openEditModal` 추가
   - `resetFormBase` 추가
   - `save()` 멀티파트 훅 패턴으로 교체

2. **`attachment_mixin.js` 사용 가이드 주석 수정**
   - `save()` 계약 설명을 `buildMultipartFormData()` 기준으로 변경
   - `connect/resetForm` 예시를 `connectModal/resetFormBase` 기준으로 정리

3. **`user_crud_controller.js` 리팩토링**
   - `connect/disconnect` → `connectModal/disconnectModal`
   - `openCreate` → `openCreateModal`
   - `handleEdit` → `openEditModal`
   - `save()` 삭제 → `buildMultipartFormData()` 추가
   - `resetForm()` → `resetFormBase`

4. **`notice_crud_controller.js` 리팩토링**
   - `connect/disconnect` → `connectModal/disconnectModal` (initHooks 사용)
   - `openCreate` → `openCreateModal`
   - `save()` 삭제 → `buildMultipartFormData()` 추가
   - `resetForm()` → `resetFormBase`

5. **`menu_crud_controller.js` 리팩토링**
   - `connect/disconnect` → `connectModal/disconnectModal`
   - `openCreate` → `openCreateModal`
   - `handleAddChild` → `openCreateModal`
   - `handleEdit` → `openEditModal`
   - `resetForm()` → `resetFormBase`

6. **기존 동작 검증**
   - 각 컨트롤러별 신규 등록 / 수정 / 삭제 동작 확인
   - menu: 최상위 추가 / 하위 추가 둘 다 확인
   - notice: 첨부파일 저장/삭제 동작 확인
   - user: 사진 업로드/삭제 동작 확인

---

## 8. 변경 영향 범위

| 파일 | 변경 유형 | 비고 |
|------|---------|------|
| `modal_mixin.js` | 함수 추가 + `save()` 수정 | 기존 JSON save 동작 유지 (하위 호환) |
| `attachment_mixin.js` | 주석/계약 문서 수정 | `save()` 대신 `buildMultipartFormData()` 기준으로 갱신 필요 |
| `menu_crud_controller.js` | 기존 함수 교체 | save()는 변경 없음 (JSON 방식 유지) |
| `user_crud_controller.js` | 기존 함수 교체 + `save()` 삭제 | `buildMultipartFormData()` 추가 |
| `notice_crud_controller.js` | 기존 함수 교체 + `save()` 삭제 | `buildMultipartFormData()` 추가 |

> **주의**: `modal_mixin.js`의 `save()` 변경은 기존 컨트롤러(JSON 방식)에 영향을 주지 않는다.
> `buildMultipartFormData()`가 없으면 기존 JSON 경로로 동작하므로 하위 호환이 보장된다.
