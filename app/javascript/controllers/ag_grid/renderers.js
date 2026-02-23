/**
 * renderers.js
 * 
 * AG Grid에서 사용되는 커스텀 셀 렌더러(Cell Renderer)들을 모아둔 파일입니다.
 * 셀 안에 단순 텍스트가 아닌 버튼, 링크, 트리 구조 등 복잡한 HTML 요소를 그릴 때 사용합니다.
 */

// 그리드 컨테이너(DOM)에 커스텀 이벤트를 발생시키는 헬퍼 함수입니다.
// Stimulus 컨트롤러나 상위 요소에서 이벤트 위임(Delegation)을 통해 이 이벤트를 감지하고 처리합니다.
function emit(container, eventName, detail) {
  const event = new CustomEvent(eventName, { detail, bubbles: true })
  container.dispatchEvent(event)
}

// 렌더러 내에서 반복적으로 사용되는 액션 버튼(추가, 수정, 삭제)을 동적 생성하는 헬퍼 함수입니다.
function createActionButton({ text, title, classes = [], onClick }) {
  const button = document.createElement("button")
  button.type = "button"
  button.innerHTML = text
  button.title = title
  button.classList.add("grid-action-btn", ...classes) // 공통 클래스 및 추가 클래스 부여
  button.addEventListener("click", onClick) // 클릭 이벤트 바인딩
  return button
}

/**
 * RENDERER_REGISTRY
 * 
 * AG Grid 컬럼 정의 시 `cellRenderer: 'rendererName'` 형태로 지정하면
 * ag_grid_controller에서 이 객체의 함수와 매핑해줍니다.
 */
export const RENDERER_REGISTRY = {
  // [공통 링크 렌더러]
  // 셀 데이터를 클릭할 수 있는 하이퍼링크(<a> 태그)로 변환합니다.
  // 사용 예: colDef에 cellRendererParams: { path: '/users/${id}' } 와 같이 경로 템플릿 제공
  link: (params) => {
    if (params.value == null) return ""

    const pathTemplate = params.colDef.cellRendererParams?.path
    if (!pathTemplate) return String(params.value) // 템플릿 미지정 시 텍스트만 렌더링

    // ${key} 부분을 실제 행 데이터(params.data)의 값으로 치환합니다.
    const href = pathTemplate.replace(/\${(\w+)}/g, (_, key) => {
      const value = params.data?.[key]
      return encodeURIComponent(value ?? "")
    })

    const anchor = document.createElement("a")
    anchor.className = "ag-grid-link"             // 스타일 요소 클래스 지정
    anchor.dataset.turboFrame = "_top"            // Turbo 프레임 이탈 링크 명시
    anchor.href = href
    anchor.textContent = String(params.value)     // 실제 셀에 보여지는 표시값
    return anchor
  },

  // [트리형 메뉴 레이블 렌더러]
  // 메뉴 트리에서 레벨(depth)에 따라 좌측에 들여쓰기(indent)를 주고 폴더 여부 아이콘을 달아줍니다.
  treeMenuCellRenderer: (params) => {
    const level = Number(params.data?.menu_level || 1)
    const indent = Math.max(level - 1, 0) * 20 // 1레벨당 20px 씩 들여쓰기
    const isFolder = params.data?.menu_type === "FOLDER"
    const icon = isFolder ? "[+]" : "[-]"

    const span = document.createElement("span")
    span.style.paddingLeft = `${indent}px`
    span.textContent = `${icon} ${params.value ?? ""}`
    if (isFolder) span.classList.add("tree-menu-folder") // 폴더일 경우 별도 클래스 부여 (CSS 굵기 등)
    return span
  },

  // [작업자 재직 상태 렌더러]
  // ACTIVE(초록색), RESIGNED(빨간색) 텍스트를 상태에 맞게 렌더링
  workStatusCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "ACTIVE") {
      span.style.color = "#18a058"
      span.textContent = "ACTIVE"
    } else {
      span.style.color = "#d03050"
      span.textContent = "RESIGNED"
    }
    return span
  },

  // [사용자 관리 액션 버튼 렌더러]
  // 각 사용자 행마다 수정(✎), 삭제(X) 버튼 세트를 렌더링하고,
  // 클릭 시 user-crud 컨트롤러로 메시지를 보냅니다.
  userActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    // 수정 버튼: 전체 userData를 emit
    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "user-crud:edit", { userData: params.data })
    }))
    // 삭제 버튼: id와 이름만 emit
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "user-crud:delete", { id: params.data.id, userNm: params.data.user_nm })
    }))
    return container
  },

  // [STD 작업장 관리 액션 버튼 렌더러]
  stdWorkplaceActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "std-workplace-crud:edit", { workplaceData: params.data })
    }))
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "std-workplace-crud:delete", {
        id: params.data.id || params.data.workpl_cd,
        workplNm: params.data.workpl_nm || params.data.workpl_cd
      })
    }))

    return container
  },

  // [부서 트리형 레이블 렌더러]
  // 부서 계층에 따라 동일하게 레벨당 들여쓰기를 처리하는 렌더러
  deptTreeCellRenderer: (params) => {
    const level = Number(params.data?.dept_level || 1)
    const indent = Math.max(level - 1, 0) * 20
    const icon = level === 1 ? "[+]" : "[-]"

    const span = document.createElement("span")
    span.style.paddingLeft = `${indent}px`
    span.textContent = `${icon} ${params.value ?? ""}`
    return span
  },

  // [로그인 성공 여부 렌더러]
  // 로그인 이력 화면 등에서 true(성공)/false(실패) 여부를 색상 텍스트로 치환합니다.
  loginSuccessCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === true) {
      span.style.color = "#18a058"
      span.textContent = "성공"
    } else {
      span.style.color = "#d03050"
      span.textContent = "실패"
    }
    return span
  },

  // [부서 사용/미사용 상태 렌더러]
  deptUseYnCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "Y") {
      span.style.color = "#18a058"
      span.textContent = "Y"
    } else {
      span.style.color = "#d03050"
      span.textContent = "N"
    }
    return span
  },

  // [공통코드 사용/미사용 상태 렌더러] 
  codeUseYnCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "Y") {
      span.style.color = "#18a058"
      span.textContent = "Y"
    } else {
      span.style.color = "#d03050"
      span.textContent = "N"
    }
    return span
  },

  // [재고 여부 플래그 렌더러] (예: 입고, 출고 관련 등 Y/N)
  stockYnCellRenderer: (params) => {
    const span = document.createElement("span")
    const value = (params.value || "").toString().toUpperCase()
    span.style.fontWeight = "bold"

    if (value === "Y") {
      span.style.color = "#d03050" // 위험/주목도 높은 색상
      span.textContent = "Y"
    } else {
      span.style.color = "#18a058"
      span.textContent = "N"
    }

    return span
  },

  // [가상 셀 상태(추가/수정/삭제 예정) 아이콘 렌더러]
  // Batch 처리형 Grid에서 클라이언트가 작성 중인 상태(더티 체킹)를 시각적으로 좌측에 아이콘 표시
  rowStatusCellRenderer: (params) => {
    const row = params.data || {}
    const span = document.createElement("span")
    span.className = "row-status-icon" // CSS 파일에 디자인 정의됨

    if (row.__is_deleted) {
      span.textContent = "−"
      span.title = "행삭제"
      span.classList.add("is-delete") // 삭제 대기 상태 스타일
      return span
    }

    if (row.__is_new) {
      span.textContent = "+"
      span.title = "행추가"
      span.classList.add("is-add")    // 신규 작성건 상태 스타일
      return span
    }

    if (row.__is_updated) {
      span.textContent = "✎"
      span.title = "행수정"
      span.classList.add("is-edit")   // 값 변경 상태 스타일
      return span
    }

    // 변경된 건이 없으면 빈 값 유지
    span.textContent = ""
    span.title = ""
    return span
  },

  // [팝업 그리드 선택 버튼 렌더러]
  popupSelectCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    container.appendChild(createActionButton({
      text: "선택",
      title: "선택",
      onClick: () => emit(container, "search-popup-grid:select", { row: params.data })
    }))
    return container
  },

  // [조회용 명칭 + 돋보기 렌더러]
  // lookup_popup_type / lookup_code_field 메타가 설정된 컬럼에서 공통으로 사용됩니다.
  lookupPopupCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("ag-lookup-cell")

    const valueEl = document.createElement("span")
    valueEl.classList.add("ag-lookup-cell__value")
    valueEl.textContent = params.value == null ? "" : String(params.value)
    container.appendChild(valueEl)

    const button = createActionButton({
      text: "🔍",
      title: "찾기",
      classes: ["ag-lookup-cell__btn"],
      onClick: (event) => {
        event.preventDefault()
        event.stopPropagation()

        emit(container, "ag-grid:lookup-open", {
          rowNode: params.node,
          rowIndex: params.rowIndex,
          colId: params.column?.getColId?.(),
          keyword: params.value,
          colDef: params.colDef
        })
      }
    })
    button.setAttribute("aria-label", "찾기")
    container.appendChild(button)

    return container
  },

  // [부서 관리 액션 버튼 렌더러]
  // 부서는 트리 계층 구조를 가지므로 하위 요소 추가(+) 버튼이 포함됩니다.
  deptActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    // 하위 부서 추가 버튼
    container.appendChild(createActionButton({
      text: "+",
      title: "하위부서추가",
      onClick: () => emit(container, "dept-crud:add-child", { parentCode: params.data.dept_code })
    }))
    // 부서 정보 수정 버튼
    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "dept-crud:edit", { deptData: params.data })
    }))
    // 부서 삭제 버튼
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "dept-crud:delete", { id: params.data.id, deptNm: params.data.dept_nm })
    }))
    return container
  },

  // [공지사항 - 상단 고정 플래그 표시 렌더러]
  noticeTopFixedCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    span.style.fontSize = "12px"
    if (params.value === "Y") {
      span.style.color = "#d03050" // 빨간색 계열
      span.textContent = "공지"
    } else {
      span.style.color = "#8b949e" // 일반 무채색 계열
      span.textContent = "일반"
    }
    return span
  },

  // [공지사항 - 게시/미게시 상태 표시 렌더러]
  noticePublishedCellRenderer: (params) => {
    const span = document.createElement("span")
    span.style.fontWeight = "bold"
    if (params.value === "Y") {
      span.style.color = "#18a058"
      span.textContent = "게시"
    } else {
      span.style.color = "#d08700"
      span.textContent = "미게시"
    }
    return span
  },

  // [공지사항 - 제목 클릭 렌더러 (상세 내용 수정 모달 오픈용)]
  noticeTitleCellRenderer: (params) => {
    const button = document.createElement("button")
    button.type = "button"
    button.classList.add("ag-grid-link")              // 링크처럼 보이는 텍스트 버튼 스타일
    button.textContent = params.value ?? ""
    button.style.cursor = "pointer"
    button.style.background = "transparent"
    button.style.border = "0"
    button.style.padding = "0"
    button.style.textAlign = "left"
    // 제목 클릭 시 수정 이벤트를 트리거합니다.
    button.addEventListener("click", () => emit(button, "notice-crud:edit", { id: params.data.id }))
    return button
  },

  // [공지사항 - 우측 액션 버튼 모음 렌더러]
  noticeActionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    // 수정 버튼
    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "notice-crud:edit", { id: params.data.id })
    }))
    // 삭제 버튼
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "notice-crud:delete", { id: params.data.id, title: params.data.title })
    }))
    return container
  },

  // [메뉴 관리 액션 버튼 렌더러 (actionCellRenderer)]
  // 메뉴 트리를 조회하는 화면에서 [하위메뉴 추가], [수정], [삭제] 3종 버튼 표시
  actionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    // 하위 메뉴 추가 버튼
    container.appendChild(createActionButton({
      text: "+",
      title: "하위메뉴추가",
      onClick: () => emit(container, "menu-crud:add-child", {
        parentCd: params.data.menu_cd,
        parentLevel: params.data.menu_level
      })
    }))
    // 메뉴 수정
    container.appendChild(createActionButton({
      text: "✎",
      title: "수정",
      onClick: () => emit(container, "menu-crud:edit", { menuData: params.data })
    }))
    // 메뉴 삭제
    container.appendChild(createActionButton({
      text: "X",
      title: "삭제",
      classes: ["grid-action-btn--danger"],
      onClick: () => emit(container, "menu-crud:delete", {
        id: params.data.id,
        menuCd: params.data.menu_cd
      })
    }))
    return container
  }
}
