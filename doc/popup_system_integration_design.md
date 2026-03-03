# 팝업 시스템 통합 설계안

> 작성일: 2026-03-03 (완전 통합 방향으로 업데이트)
> 목적: 두 팝업 시스템을 단일 `<dialog>` + `<turbo-frame>` 기반 엔진으로 완전 통합
> 핵심 결정: **iframe 완전 제거** → `<turbo-frame>`으로 대체, `postMessage` 통신 완전 제거

---

## 1. 현황 분석

### 1-1. 현재 두 팝업 시스템 구조

```
시스템 A: ResourceForm 검색 팝업 (입력 폼 전용)
─────────────────────────────────────────────────
_popup.html.erb
  └─ data-controller="search-popup"
       └─ search_popup_controller.js     ← Stimulus (opener)
            └─ openLookupPopup()         ← lookup_popup_modal.js
                 └─ <div id="search-popup-modal">  ← DOM div 방식
                      └─ <iframe src="/search_popups/:type">  ← 별도 window 컨텍스트
                           └─ search_popup_grid_controller.js
                                └─ window.parent.postMessage(...)  ← 벽 너머 통신

시스템 B: ModalMixin CRUD 팝업 (그리드 액션 전용)
─────────────────────────────────────────────────
modal_mixin.js (BaseGridController에 Object.assign 합성)
  └─ openModal() / closeModal()         ← <dialog> 태그 방식
  └─ startDrag() / handleDragMove()     ← 드래그 지원
  └─ save() / handleDelete()            ← CRUD 액션
  └─ buildJsonPayload()                 ← 폼 데이터 직렬화
```

### 1-2. 아키텍처 차이점 비교

| 항목 | 시스템 A (검색 팝업) | 시스템 B (CRUD 모달) |
|------|---------------------|---------------------|
| DOM 방식 | `<div>` 동적 생성 (JS) | `<dialog>` 태그 (HTML 선언) |
| 콘텐츠 렌더링 | `<iframe>` (별도 window 컨텍스트) | 인라인 HTML (Stimulus 타겟) |
| 통신 방식 | `postMessage` + `CustomEvent` | Stimulus 타겟 직접 접근 |
| 드래그 지원 | 없음 | 있음 (ModalMixin) |
| 용도 | 코드값 검색·선택 | CRUD(등록/수정/삭제) |
| 팝업 수 | 전역 싱글턴 1개 재사용 | 화면별 독립 인스턴스 |
| 상태 관리 | `activeClose` 전역 변수 | Stimulus 컨트롤러 인스턴스 |

### 1-3. 핵심 문제점

1. **이중 표준**: 동일 "팝업 열기" 행위에 `<div>`/`<dialog>` 두 가지 방식 공존
2. **중복 기능**: 모달 열기·닫기·드래그·이벤트 해제 로직이 양쪽에 분산
3. **iframe 별도 컨텍스트**: `postMessage` 우회 통신 강제, 스타일 공유 불가
4. **결합도**: `search_popup_grid_controller`가 `window.postMessage` + DOM id에 직접 의존
5. **전역 상태**: `activeClose` 전역 변수로 단일 팝업만 허용

### 1-4. iframe vs turbo-frame 비교

| 항목 | `<iframe>` (현재) | `<turbo-frame>` (목표) |
|------|-----------------|----------------------|
| window 컨텍스트 | 별도 격리 | 동일 document |
| 통신 방식 | `postMessage` 필수 | `CustomEvent` 직접 발행 |
| 스타일 공유 | 불가 | 가능 (CSS 공유) |
| 불필요 코드 | `isEmbeddedPopup()`, `postToParent()`, `messageListener` | 모두 제거 가능 |

---

## 2. 완전 통합 설계안

### 2-1. 통합 목표

- **단일 `<dialog>` + `<turbo-frame>` 기반** 팝업 엔진으로 두 시스템 완전 통일
- `<iframe>` 완전 제거 → `<turbo-frame>` 으로 대체
- `postMessage` / `isEmbeddedPopup` / `messageListener` **완전 제거**
- 기존 사용처 외부 API 시그니처 유지 (하위 호환)
- 드래그·포커스 트랩·ESC 닫기 등 UX 기능 공통화

### 2-2. 통합 아키텍처 다이어그램

```
통합 전 (현재)                          통합 후 (목표)
──────────────────────────────────────────────────────────────────
시스템 A:                               단일 팝업 엔진:
  <div> + <iframe>                        popup_manager.js
  window.postMessage                         <dialog>
                                              ├─ lookup: <turbo-frame>
시스템 B:                                   │   src="/search_popups/:type"
  <dialog> + 인라인HTML                    │   ← 같은 document, CustomEvent
  ModalMixin 스타일 조작                   └─ inline: 기존 dialogEl 재사용
                                               (CRUD 모달)

                                          공통:
                                            showModal() / close()
                                            drag (popup_drag_mixin.js)
                                            ESC / backdrop 닫기
                                            Promise 반환
```

### 2-3. 신규 파일 구조

```
app/javascript/
  controllers/
    popup/
      popup_manager.js          ← 핵심 엔진 (신규)
      popup_drag_mixin.js       ← 드래그 로직 분리 (신규)
    lookup_popup_modal.js       ← popup_manager 래퍼로 교체 (수정)
    concerns/
      modal_mixin.js            ← popup_manager.open() 위임으로 변경 (수정)
    search_popup_grid_controller.js  ← postMessage 제거, CustomEvent 직접 발행 (수정)

app/views/
  search_popups/
    show.html.erb               ← turbo_frame_tag "popup-frame" 래핑 (수정)
```

### 2-4. popup_manager.js 인터페이스 설계

```js
/**
 * PopupManager — 단일 <dialog> 기반 팝업 엔진
 *
 * url 제공 시   → <dialog> + <turbo-frame src="url"> 로드 (검색 팝업)
 * dialogEl 제공 → 기존 <dialog> 요소를 열기 (CRUD 모달)
 */

// 검색 팝업 (시스템 A 대체) — turbo-frame으로 로드
const result = await PopupManager.open({
  url: "/search_popups/customer",  // turbo-frame src
  title: "거래처 조회",
  keyword: "삼성",
  width: "min(980px, calc(100vw - 24px))",
  draggable: true
})
// result: { code, name, display, ...rawRow } | null

// CRUD 모달 (시스템 B 대체) — 기존 dialog 요소 재사용
const instance = PopupManager.open({
  dialogEl: this.overlayTarget,    // 기존 <dialog> 요소
  title: "사용자 등록",
  draggable: true
})
instance.close()
```

### 2-5. 통신 방식 변경: postMessage → CustomEvent

#### 기존 (iframe + postMessage)

```
search_popup_grid_controller.js (iframe 내부)
  └─ window.parent.postMessage({ type: "search-popup-select", detail }, origin)
       └─ lookup_popup_modal.js (부모 window)
            └─ window.addEventListener("message", onMessage)
                 └─ resolve(selection)
```

#### 변경 후 (turbo-frame + CustomEvent)

```
search_popup_grid_controller.js (같은 document)
  └─ this.element.dispatchEvent(new CustomEvent("popup:select", { bubbles: true, detail }))
       └─ <dialog> 까지 버블링
            └─ popup_manager.js
                 └─ dialog.addEventListener("popup:select", ...)
                      └─ resolve(selection)
```

### 2-6. 각 파일별 변경 상세

#### `search_popup_grid_controller.js` — 제거 대상 코드

```js
// 아래 3개 항목 완전 삭제

// ① connect() 내 messageListener 등록
this.messageListener = (event) => {
  if (event.data?.source === "search-popup-modal" && ...) { ... }
}
window.addEventListener("message", this.messageListener)

// ② disconnect() 내 messageListener 해제
window.removeEventListener("message", this.messageListener)

// ③ isEmbeddedPopup() / postToParent() 메서드 전체
isEmbeddedPopup() { ... }
postToParent(type, detail) { ... }
```

```js
// selectRow() / closeModal() 변경

// Before
selectRow(row) {
  if (this.isEmbeddedPopup()) {
    this.postToParent("search-popup-select", detail)
    return
  }
  const modal = document.getElementById("search-popup-modal")
  modal.dispatchEvent(new CustomEvent("search-popup:select", { bubbles: true, detail }))
}

// After
selectRow(row) {
  if (!row) return
  // ...detail 구성 동일...
  this.element.dispatchEvent(new CustomEvent("popup:select", { bubbles: true, detail }))
}

closeModal() {
  this.element.dispatchEvent(new CustomEvent("popup:close", { bubbles: true }))
}
```

#### `search_popups/show.html.erb` — turbo_frame_tag 래핑

```erb
<%# 기존 콘텐츠를 turbo-frame으로 감싸기 %>
<%= turbo_frame_tag "popup-frame" do %>
  <%# 기존 검색폼 + 그리드 컨텐츠 그대로 %>
<% end %>
```

#### `lookup_popup_modal.js` — 내부 교체 (시그니처 유지)

```js
// 외부 호출부 변경 없음
export async function openLookupPopup({ type, url, keyword, title } = {}) {
  const baseUrl = url || `/search_popups/${encodeURIComponent(type)}`
  return PopupManager.open({          // ← 내부만 위임
    url: buildFrameSrc(baseUrl, keyword),
    title: title || defaultTitle(type)
  })
}
```

#### `modal_mixin.js` — openModal/closeModal 위임

```js
// Before
openModal() {
  const overlay = this.overlayTarget
  overlay.showModal()
  overlay.style.display = "flex"
  overlay.style.position = "fixed"
  // ... 스타일 직접 조작 8줄 ...
}

// After
openModal() {
  this._popupInstance = PopupManager.open({
    dialogEl: this.overlayTarget,
    draggable: true
  })
}

closeModal() {
  this._popupInstance?.close()
}
```

### 2-7. popup_drag_mixin.js — 드래그 로직 분리

`modal_mixin.js`의 드래그 코드를 독립 모듈로 추출:

```js
// popup_drag_mixin.js
export function attachDrag(dialogEl, handleEl) {
  let dragState = null

  function startDrag(event) { /* 기존 startDrag 로직 */ }
  function handleDragMove(event) { /* 기존 handleDragMove 로직 */ }
  function endDrag() { /* 기존 endDrag 로직 */ }

  handleEl.addEventListener("mousedown", startDrag)
  window.addEventListener("mousemove", handleDragMove)
  window.addEventListener("mouseup", endDrag)

  return {
    destroy() {
      handleEl.removeEventListener("mousedown", startDrag)
      window.removeEventListener("mousemove", handleDragMove)
      window.removeEventListener("mouseup", endDrag)
    }
  }
}
```

### 2-8. `<dialog>` 태그 통일의 장점

| 항목 | 기존 `<div>` 방식 | `<dialog>` 태그 |
|------|-----------------|----------------|
| 포커스 트랩 | 수동 구현 필요 | 브라우저 내장 |
| ESC 닫기 | 수동 keydown 리스너 | `cancel` 이벤트 자동 발생 |
| 접근성(aria) | 수동 속성 추가 | `role=dialog` 내장 |
| backdrop | CSS z-index + div 레이어 | `::backdrop` pseudo-element |
| z-index 관리 | 수동 (2147483000) | 최상위 레이어 자동 배치 |

---

## 3. 삭제 가능 코드 목록

통합 완료 후 제거할 수 있는 코드:

| 위치 | 제거 대상 |
|------|----------|
| `lookup_popup_modal.js` | `MODAL_ID`, `activeClose`, `buildOverlayElement()`, `ensureModal()`, `applyModalBaseStyle()`, `openModalElement()`, `closeModalElement()` 전체 |
| `lookup_popup_modal.js` | `window.addEventListener("message", onMessage)` 블록 |
| `search_popup_grid_controller.js` | `messageListener`, `isEmbeddedPopup()`, `postToParent()` |
| `search_popup_grid_controller.js` | `connect()`/`disconnect()` 내 `window.addEventListener/removeEventListener("message", ...)` |
| `modal_mixin.js` | `openModal()` 내 스타일 직접 조작 8줄 |
| `modal_mixin.js` | `startDrag()`, `handleDragMove()`, `endDrag()` (popup_drag_mixin.js로 이동) |

---

## 4. 통합 구현 단계 (Phase Plan)

### Phase 1 — 드래그 로직 분리 (사이드 이펙트 없음)
- `popup_drag_mixin.js` 신규 생성
- `modal_mixin.js`의 `startDrag` / `handleDragMove` / `endDrag` 이동
- `modal_mixin.js`에서 `attachDrag()` import 후 위임
- 기존 동작 동일 유지

### Phase 2 — popup_manager.js 신규 생성
- `url` 제공 시: `<dialog>` 생성 + `<turbo-frame>` 삽입
- `dialogEl` 제공 시: 기존 `<dialog>` 요소 받아서 공통 처리
- `popup:select` / `popup:close` CustomEvent 리스닝
- 드래그: `popup_drag_mixin.attachDrag()` 활용
- ESC / backdrop 클릭 닫기 통합

### Phase 3 — 서버 사이드 turbo-frame 래핑
- `app/views/search_popups/show.html.erb` 에 `turbo_frame_tag "popup-frame"` 추가

### Phase 4 — search_popup_grid_controller.js 정리
- `messageListener` / `isEmbeddedPopup()` / `postToParent()` 제거
- `selectRow()` / `closeModal()` → `CustomEvent` 직접 발행으로 교체

### Phase 5 — lookup_popup_modal.js 교체
- 기존 `openLookupPopup()` 시그니처 유지
- 내부 구현 `PopupManager.open()` 위임
- 불필요 함수 전체 제거

### Phase 6 — modal_mixin.js 교체
- `openModal()` / `closeModal()` → `PopupManager.open()` 위임
- 스타일 직접 조작 코드 제거

### Phase 7 — 검증 (Smoke Test)
- 기존 검색 팝업 동작 확인 (거래처, 작업장, 품목)
- 기존 CRUD 모달 동작 확인 (system/* 화면)
- 드래그, ESC 닫기, backdrop 클릭 확인

---

## 5. 수정 대상 파일 목록

| 파일 | 작업 | Phase |
|------|------|-------|
| `app/javascript/controllers/popup/popup_manager.js` | **신규 생성** | 2 |
| `app/javascript/controllers/popup/popup_drag_mixin.js` | **신규 생성** | 1 |
| `app/views/search_popups/show.html.erb` | `turbo_frame_tag` 래핑 추가 | 3 |
| `app/javascript/controllers/search_popup_grid_controller.js` | `postMessage` 제거, `CustomEvent` 직접 발행 | 4 |
| `app/javascript/controllers/lookup_popup_modal.js` | 내부 교체 (시그니처 유지) | 5 |
| `app/javascript/controllers/concerns/modal_mixin.js` | `openModal`/`closeModal` 교체, 드래그 이동 | 6 |
| `app/views/shared/resource_form/fields/_popup.html.erb` | 변경 없음 | — |
| `app/components/ui/resource_form_component.rb` | 변경 없음 | — |
| `app/javascript/controllers/search_popup_controller.js` | 변경 없음 | — |

---

## 6. 검증 체크리스트

- [ ] 거래처 검색 팝업 열기 → turbo-frame 로드 확인
- [ ] 항목 선택 → CustomEvent 버블링 → 코드/표시명 입력 확인
- [ ] 품목/작업장 검색 팝업 동일 확인
- [ ] system/* 화면 CRUD 모달 등록·수정·삭제 확인
- [ ] 모달 헤더 드래그 이동, 뷰포트 경계 초과 방지 확인
- [ ] ESC 키 누르면 모달 닫힘 확인
- [ ] 모달 바깥 영역(backdrop) 클릭 시 닫힘 확인
- [ ] 팝업 열려 있는 상태에서 새 팝업 열기 → 기존 팝업 자동 닫힘 확인
- [ ] 브라우저 네트워크 탭에서 `postMessage` 통신 완전 제거 확인
- [ ] `iframe` DOM 요소 미생성 확인 (turbo-frame으로 대체 확인)
