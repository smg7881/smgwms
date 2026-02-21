/**
 * search_form_controller.js
 * 
 * 대시보드 및 리스트 페이지의 상단에 위치하는 '조회 조건 필터 폼(Search Form)' UI를 제어합니다.
 * 주요 기능:
 * 1. 폼의 접기/펼치기(Collapse) 기능 (화면 크기나 초기설정에 따라 조건 박스 공간을 절약)
 * 2. 그리드 레이아웃의 Span 계산을 통해, 우측 끄트머리에 정렬되어야 할 조회/초기화 버튼 그룹 동적 정렬
 * 3. 새로고침 및 Turbo를 통한 폼 제출 로직 제어
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",             // <form> 루트 태그
    "fieldGroup",       // 개별 검색조건 위젯 컨테이너 (한 줄 혹은 여러 줄 차지 단위)
    "collapseBtn",      // 우측 하단 접기/펼치기 토글 버튼 대상
    "collapseBtnText",  // 접기/펼치기 글자 (라벨)
    "collapseBtnIcon",  // 화살표 아이콘 등
    "buttonGroup"       // "조회", "초기화" 버튼이 묶인 div 컨테이너
  ]

  // data-* 값으로 제어받는 프로퍼티
  static values = {
    collapsed: { type: Boolean, default: true },      // 현재 폼이 다 닫혀있는지(접힘) 여부
    loading: { type: Boolean, default: false },       // 조회중 스피너/제출 락 용도
    collapsedRows: { type: Number, default: 1 },      // 닫혀있을 때 기본으로 몇 줄의 필드까지만 보여줄 건지 결정
    cols: { type: Number, default: 3 },               // 안 쓰이는 컬럼값 (하위 호환이나 레거시 추정)
    enableCollapse: { type: Boolean, default: true }  // 접기 기능 자체가 사용 가능한지(필드가 너무 적으면 작동안함 등)
  }

  // DOM 렌더링 시점에 초기 세팅 및 브라우저 리사이징 감시 등록
  connect() {
    if (!this.enableCollapseValue) {
      this.collapsedValue = false // 기능 오프라면 무조건 펼처둠
    }

    // 브라우저 윈도우 사이즈가 조절될 때, CSS Grid의 Span값이 동적으로 바뀔 가능성이 있어 
    // 변화를 캐치하고 버튼 그룹의 위치를 재계산하기 위함
    this._resizeObserver = new ResizeObserver(() => {
      if (this.collapsedValue && this.enableCollapseValue) {
        this.#applyCollapse()
      }
    })
    this._resizeObserver.observe(this.element)

    this.collapsedValueChanged() // 상태 초깃값에 맞게 DOM 변경 트리거
  }

  disconnect() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect()
      this._resizeObserver = null
    }
  }

  // 조회 버튼 Submit 요청
  search(event) {
    event.preventDefault()

    // HTML5 네이티브 validation 통과하지 못하면 브라우저 말풍선 팝업 호출 후 거절
    if (!this.formTarget.checkValidity()) {
      this.formTarget.reportValidity()
      return
    }

    // 문제 없으면 백그라운드로 폼 서밋 요청
    this.formTarget.requestSubmit()
  }

  // 초기화 버튼 클릭
  reset(event) {
    event.preventDefault()

    this.formTarget.reset() // DOM 입력폼 백지화

    const baseUrl = this.formTarget.action.split("?")[0]
    const turboFrame = this.formTarget.dataset.turboFrame

    // 필터 값 걷어내고 쌩 주소로 방문 요청하여 그리드를 완전히 초기 상태로 복구
    if (turboFrame && window.Turbo) {
      // 폼이 특정한 TurboFrame을 겨냥하고 있다면 그 영역만 교체 요청할 수 있도록 강제 visit 명령
      Turbo.visit(baseUrl, { frame: turboFrame })
    } else {
      window.location.href = baseUrl
    }
  }

  // 펼치기 / 접기 버튼 핸들러
  toggleCollapse(event) {
    event.preventDefault()
    this.collapsedValue = !this.collapsedValue // 값 변경 시 자동 collapsedValueChanged() 실행
  }

  // collapsedValue 변수 값 변경을 감지하는 Stimulus 콜백 메서드
  collapsedValueChanged() {
    if (this.collapsedValue && this.enableCollapseValue) {
      this.#applyCollapse() // 접음 로직 수행
      this.#updateCollapseButton(true)
    } else {
      this.#showAllFields() // 전부 다 보이도록 펼침
      this.#updateCollapseButton(false)
    }
    // 접히나 펴지나, 맨 밑 우측의 버튼 위치는 여백계산 하여 재배경되어야 하므로 공통 호출
    this.#updateButtonSpan()
  }

  // 1줄 (기본: col-span-24 기준으로 24칸 제한) 만큼의 필드만 보여주고 나머지는 display:none
  #applyCollapse() {
    if (!this.hasFieldGroupTarget) return

    const maxSpan = this.collapsedRowsValue * 24 // 1row = 24칸 단위 격자체계
    let accumulated = 0

    this.fieldGroupTargets.forEach(el => {
      const span = this.#spanOf(el)
      accumulated += span

      // 할당된 span 총합이 허용치 이상을 넘기면 이후 요소들은 전부 hidden 처리
      if (accumulated > maxSpan) {
        el.hidden = true
      } else {
        el.hidden = false
      }
    })
  }

  // 모조리 hidden 속성 제거
  #showAllFields() {
    if (!this.hasFieldGroupTarget) return

    this.fieldGroupTargets.forEach(el => {
      el.hidden = false
    })
  }

  // 해당 DOM 태그의 현재 화면상 grid-column 계산. Tailwind "col-span-8" 같은 CSS 적용본 추출.
  #spanOf(el) {
    const style = getComputedStyle(el)
    const gridColumn = style.gridColumnEnd

    const match = gridColumn.match(/span\s+(\d+)/)
    if (match) return parseInt(match[1], 10) // "span 8" 이면 8 리턴

    return 24 // 매칭 못하면 블록 단위 통짜 차지로 간주
  }

  // 조회 버튼 영역이 무조건 우측에 정렬되기 위해서, 앞쪽 박스들이 차지하고 남은 칸수를 뺀 
  // '나머지 빈칸' span을 동적 바인딩하는 계산 로직 (유동형 레이아웃)
  #updateButtonSpan() {
    if (!this.hasButtonGroupTarget) return

    let totalSpan = 0
    let visibleSpan = 0

    if (this.hasFieldGroupTarget) {
      this.fieldGroupTargets.forEach(el => {
        const span = this.#spanOf(el)
        totalSpan += span
        if (!el.hidden) {
          visibleSpan += span
        }
      })
    }

    const rowSpan = 24
    let targetSpan = 0

    if (this.collapsedValue && this.enableCollapseValue) {
      // 접힌 상태일 때 남은 빈 영역 계산 (수치 보정)
      const used = visibleSpan % rowSpan
      const remaining = rowSpan - used
      targetSpan = (remaining === 0) ? 24 : remaining
    } else {
      // 열린 상태일 때 전체 영역 중 남은 빈 영역 계산
      const used = totalSpan % rowSpan
      const remaining = rowSpan - used
      targetSpan = (remaining === 0) ? 24 : remaining
    }

    // 최소 너비 사이즈 방지 (버튼이 구겨지는 것 방지)
    if (targetSpan < 4) targetSpan = 24

    // 버튼 그룹(div)에 grid-column 스타일을 덮어씀
    this.buttonGroupTarget.style.gridColumn = `span ${targetSpan}`
  }

  // "접기", "▼" 표기 등을 토글링
  #updateCollapseButton(isCollapsed) {
    if (this.hasCollapseBtnTarget) {
      this.collapseBtnTarget.setAttribute("aria-expanded", String(!isCollapsed))
    }
    if (this.hasCollapseBtnTextTarget) {
      this.collapseBtnTextTarget.textContent = isCollapsed ? "펼치기" : "접기"
    }
    if (this.hasCollapseBtnIconTarget) {
      this.collapseBtnIconTarget.textContent = isCollapsed ? "▼" : "▲"
    }
  }
}
