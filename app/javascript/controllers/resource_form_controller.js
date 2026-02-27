import { Controller } from "@hotwired/stimulus"

/**
 * resource_form_controller.js
 * 
 * CRUD 모달 창 내부 또는 개별 작성/수정 화면 등의 메인 '입력 폼(Form)' 요소를 제어하는 컨트롤러입니다.
 * - [핵심기능 1] 브라우저 기본 유효성(required, regexp 등) 통과 여부를 검사하고 시각적인 에러 메시지를 통제
 * - [핵심기능 2] 'A를 선택하면 B목록이 바뀐다'와 같은 Select 필드 간 계층형 종속(의존성) 로직 제어
 * - [핵심기능 3] 통신 중 중복 클릭을 막기 위한 버튼 스피너/락(Lock) 처리
 */
export default class extends Controller {
  // 타겟 바인딩 - 폼 내 각 구성요소 추적 가능
  static targets = [
    "form",             // 모달/페이지 내 실제 <form> 엘리먼트
    "fieldGroup",       // 각 입력단(Label + Input + Error Span 구조)을 감싸는 div 래퍼 그룹
    "input",            // 입력 가능한 모든 타겟 필드 (input, select, textarea 모두 포괄)
    "dependentField",   // 다른 select 조건에 따라 바뀔 "의존받는 자식 필드"
    "submitBtn",        // 전송(저장) 버튼
    "submitText",       // 전송 버튼 안의 글씨
    "submitSpinner",    // 전송 버튼 안의 빙글빙글 도는 스피너 로딩 HTML
    "resetBtn",         // 초기화/취소 버튼
    "errorSummary",     // 상단에 위치하여 전역 에러를 크게 보여줄 박스 영역
    "buttonGroup"       // 하단 버튼들 묶음 랩퍼
  ]

  // 설정용 상태 변수
  static values = {
    loading: { type: Boolean, default: false }, // 통신 진행 혹은 대기 상태 여부 기록 (버튼 잠금 제어용)
    // dependencies 포맷: { "child_field_name": { parent: "parent_field_name", filter_key: "비교키값" } }
    dependencies: { type: Object, default: {} }
  }

  connect() {
    // 컨트롤러 DOM 부착 완료 직후 의존성 필드 초기 렌더링 검사 실시
    this.#initializeDependencies()
  }

  // ── Actions ──

  // 사용자가 "저장" 버튼 클릭이나 엔터로 폼 제출(onsubmit)을 시도할 경우 중간에서 가로채는 로직
  submit(event) {
    // 로딩 중(처리 중)이면 백엔드로 중복 요청 발사되는 것을 막음(이중 결제/저장 방지)
    if (this.loadingValue) {
      event.preventDefault()
      return
    }

    // HTML5 네이티브 속성에 따른 규격(required, max length 등)에 들어맞는지 1차 검증
    if (!this.formTarget.checkValidity()) {
      event.preventDefault()           // 폼 전송 일단 정지
      this.formTarget.reportValidity() // 브라우저 제공 경고풍선 노출
      this.#highlightInvalidFields()   // 자체 구현한 빨간색 테두리 등을 위해 강제 스타일 부착
      return
    }

    // 유효성에 문제 없으면 스피너 돌리고 버튼 비활성화를 위해 값을 True로 바꿈 (자동으로 loadingValueChanged 발생)
    this.loadingValue = true
  }

  // 사용자가 폼 내용을 비우기(초기화) 버튼을 클릭할 때 작동
  reset(event) {
    event.preventDefault()

    this.formTarget.reset()       // 브라우저 네이티브 리셋 명령 (value 싹 비우기)
    this.loadingValue = false     // 로딩 락 풀기
    this.#clearErrors()           // 빨갛게 물든 에러 메시지 스타일 초기화
    this.#initializeDependencies()// Select 콤보박스 연결 필드들 옵션 목록도 초기상태로 되돌림
  }

  // 필드 개별 변경 이벤트(oninput, onchange 등) 발생 시마다 개별 유효성 즉각 반응 UI
  validateField(event) {
    const input = event.target
    // 필드를 감싼 wrapper. 에러 말풍선을 여기 안에 부착함
    const fieldGroup = input.closest("[data-field-name]")
    if (!fieldGroup) return

    if (input.checkValidity()) {
      // 값이 올바르게 채워지면 에러 클래스와 말풍선 해제
      input.classList.remove("rf-field-error")
      this.#hideFieldError(fieldGroup)
    } else {
      // 아직 안 맞을 시 다시 빨간 띄 칠하고 이유를 브라우저 Native 메시지로 따옴
      input.classList.add("rf-field-error")
      this.#showFieldError(fieldGroup, input.validationMessage)
    }
  }

  // 부모 Select 필드 값 변경을 캐치하여, 연계된 자식 필드 목록을 동적으로 재설정하는 핸들러
  onSelectChange(event) {
    const parentField = event.target.closest("[data-field-name]")
    if (!parentField) return

    // 자신(부모)의 이름을 알고 변경된 밸류를 전달함
    const parentName = parentField.dataset.fieldName
    this.#updateDependentFields(parentName, event.target.value)
  }

  // ── Public Helpers ──

  /**
   * 폼 내 HTML DOM을 검색하여 특정 필드(fieldName)의 값을 반환하는 공통 함수
   * (input, select, radio, checkbox 등 지원)
   * @param {string} fieldName 찾고자 하는 필드의 name 속성 (예: 'user[dept_cd]')
   * @returns {any} 필드의 값
   */
  getResourceFieldValue(fieldName) {
    if (!this.hasFormTarget) return null

    const elements = this.formTarget.querySelectorAll(`[name="${fieldName}"]`)
    if (elements.length === 0) return null

    // 라디오 버튼 처리
    if (elements[0].type === "radio") {
      const checkedRadio = Array.from(elements).find(el => el.checked)
      return checkedRadio ? checkedRadio.value : null
    }

    // 체크박스 처리 (Rails의 hidden 우선 생성 패턴 대비, 실제 checkbox 요소만 추출)
    const checkboxes = Array.from(elements).filter(el => el.type === "checkbox")
    if (checkboxes.length > 0) {
      const checked = checkboxes.filter(el => el.checked)
      if (checkboxes.length === 1) {
        return checked.length > 0 ? checked[0].value : null
      }
      return checked.map(el => el.value)
    }

    // 다중 선택 Select 처리
    if (elements[0].tagName === "SELECT" && elements[0].multiple) {
      return Array.from(elements[0].selectedOptions).map(opt => opt.value)
    }

    // 일반 input (text, hidden, number 등), select(single), textarea 등
    // (동일 이름이 중복된 경우, 화면 구조상 주로 맨 뒤의 요소가 유효값을 담고 있으므로 마지막 요소를 선택)
    return elements[elements.length - 1].value
  }

  /**
   * 특정 필드(fieldName)에 값을 세팅하는 공통 함수
   * @param {string} fieldName 세팅하고자 하는 필드의 name 속성
   * @param {any} value 세팅할 값
   */
  setResourceFieldValue(fieldName, value) {
    if (!this.hasFormTarget) return

    const elements = this.formTarget.querySelectorAll(`[name="${fieldName}"]`)
    if (elements.length === 0) return

    // 라디오 버튼 값 지정
    if (elements[0].type === "radio") {
      let isSet = false
      elements.forEach(el => {
        if (el.value === String(value)) {
          el.checked = true
          isSet = true
        } else {
          el.checked = false
        }
      })
      if (isSet) elements[0].dispatchEvent(new Event("change", { bubbles: true }))
      return
    }

    // 체크박스 값 지정
    const checkboxes = Array.from(elements).filter(el => el.type === "checkbox")
    if (checkboxes.length > 0) {
      if (Array.isArray(value)) {
        checkboxes.forEach(el => {
          el.checked = value.includes(el.value)
        })
      } else {
        checkboxes.forEach(el => {
          el.checked = (value === true || el.value === String(value))
        })
      }
      checkboxes[0].dispatchEvent(new Event("change", { bubbles: true }))
      return
    }

    // 입력 필드(text, hidden), 달력 등 실제 값 세팅 요소
    const targetEl = elements[elements.length - 1]

    // 다중 선택 Select 처리
    if (targetEl.tagName === "SELECT" && targetEl.multiple) {
      const valArray = Array.isArray(value) ? value : [String(value)]
      Array.from(targetEl.options).forEach(opt => {
        opt.selected = valArray.includes(opt.value)
      })
    } else {
      // 일반 단일 입력/선택 값 지정
      targetEl.value = value
    }

    // 변경된 값을 UI나 그리드 등 외부에서 알 수 있도록 이벤트 트리거 발생
    targetEl.dispatchEvent(new Event("input", { bubbles: true }))
    targetEl.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // ── Value Callbacks ──

  // loadingValue 값이 변동될 때 자동 호출 (Stimulus 기본 컨벤션)
  loadingValueChanged() {
    // 저장 버튼 클릭 방지 상태 토글
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = this.loadingValue
    }
    // "저장중..." 스피너 표시 토글
    if (this.hasSubmitTextTarget && this.hasSubmitSpinnerTarget) {
      this.submitSpinnerTarget.hidden = !this.loadingValue
    }
  }

  // ── Private ──

  // HTML Data 속성으로부터 넘겨받은 {자식: 부모} 종속성 객체를 순회하면서
  // 부모 셀렉트의 '변경(change)' 이벤트를 가로챌 Stimulus Action을 강제로 주입
  #initializeDependencies() {
    if (!this.hasDependenciesValue || Object.keys(this.dependenciesValue).length === 0) return

    for (const [childField, config] of Object.entries(this.dependenciesValue)) {
      // 1. 부모 DOM 탐색
      const parentEl = this.element.querySelector(`[data-field-name="${config.parent}"] select`)
      if (parentEl) {
        // 이미 액션 바인딩이 안돼있다면 data-action 문자열에 "change->resource-form#onSelectChange" 추가
        if (!parentEl.dataset.action?.includes("resource-form#onSelectChange")) {
          parentEl.dataset.action = (parentEl.dataset.action || "") + " change->resource-form#onSelectChange"
        }

        // 초기 시작 상태 조정을 위해 최초 1회 즉시 실행 (예: "과일"이 기본으로 떠있으면 "사과/바나나" 세팅)
        this.#updateDependentFields(config.parent, parentEl.value)
      }
    }
  }

  // 특정 부모 컨트롤이 바뀌었음을 통보받았을 때, 이에 영향받아 갱신되어야 할 "자식"들을 전부 찾아서 필터링 수행
  #updateDependentFields(parentName, parentValue) {
    const deps = this.dependenciesValue

    // deps 구조 예: { "city_code": { parent: "country_code", filter_key: "국가아이디" } }
    for (const [childField, config] of Object.entries(deps)) {
      if (config.parent !== parentName) continue

      const childGroup = this.element.querySelector(`[data-field-name="${childField}"]`)
      if (!childGroup) continue

      const childSelect = childGroup.querySelector("select")
      if (!childSelect) continue

      // 부모의 현재 값(parentValue)과 비교 속성(filter_key) 정보를 넘기며 자식 옵션 재구축 오더
      this.#filterDependentOptions(childSelect, parentValue, config.filter_key)
    }
  }

  // 자식 select 박스의 <option> 목록을 '조건'에 따라 넣었다 뺐다 하는 핵심 메서드
  #filterDependentOptions(selectEl, parentValue, filterKey) {
    // 팁: 서버에서 <option>을 숨기는 것이 아니라, 부모에서 미리 모든 연관 옵션을 JSON String으로 data-all-options 에 담아뒀음
    const allOptionsJson = selectEl.dataset.allOptions
    if (!allOptionsJson) return

    let allOptions
    try {
      allOptions = JSON.parse(allOptionsJson) // 캐싱된 완전체 옵션 배열 복원
    } catch {
      return
    }

    // "선택해주세요(빈칸)" 옵션은 필터링에서 제외하고 무조건 1개는 띄우기 위해 백업해둠
    const blankOption = selectEl.querySelector('option[value=""]')
    selectEl.innerHTML = "" // 모든 옵션 청소 (비우기)

    if (blankOption) {
      selectEl.appendChild(blankOption)
    }

    // 부모 값이 있으면 필터 돌리고, 빈칸이면 조건이 없는 것으로 간주해 모든 자식을 다 띄울지 논의 필요. 
    // 본 소스는 부모값이 있어야만 자식이 노출되는 방향으로 짜여짐.
    const filtered = parentValue
      ? allOptions.filter(opt => {
        const filterVal = opt[filterKey] || opt[`${filterKey}`] // 옵션 JSON안에 박힌 외래키
        return String(filterVal) === String(parentValue) // 부모 PK 값과 대조 일치 분기
      })
      : allOptions

    // 필터링 통과한 목록만 DOM에 렌더링 부착
    for (const opt of filtered) {
      const option = document.createElement("option")
      option.value = opt.value || opt["value"]
      option.textContent = opt.label || opt["label"]
      selectEl.appendChild(option)
    }

    // 자식의 항목도 변경된 것이므로 자식에게 연쇄 의존성이 걸려있는 "손자" 요소를 위해 change 이벤트 버블링 발생시킴
    selectEl.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // 유효성에 어긋난 필드들을 모조리 찾아서 빨간 외곽선 클래스를 씌워주는 일괄 연산 유틸리티
  #highlightInvalidFields() {
    this.inputTargets.forEach(input => {
      if (!input.checkValidity()) {
        input.classList.add("rf-field-error")
      }
    })
  }

  // 클라 오류 통제용으로 씌웠던 클래스 등 전부 백지화
  #clearErrors() {
    // 하위 랩퍼 순회
    this.element.querySelectorAll(".rf-field-error").forEach(el => {
      el.classList.remove("rf-field-error")
    })
    this.element.querySelectorAll(".rf-error-msg").forEach(el => {
      el.textContent = " " // 스크린리더를 위한 공백문자 
      el.classList.add("invisible")
    })

    // Rails Form Builder에 의해 생성된 전역 Summary 컴포넌트 강제 삭제
    if (this.hasErrorSummaryTarget) {
      this.errorSummaryTarget.remove()
    }
  }

  // 개별 필드 오류 메시지 UI 삽입 컴포넌트
  #showFieldError(fieldGroup, message) {
    let errorEl = fieldGroup.querySelector(".rf-error-msg")
    if (!errorEl) {
      errorEl = document.createElement("span")
      errorEl.classList.add("rf-error-msg")
      fieldGroup.appendChild(errorEl)
    }
    errorEl.textContent = message
    errorEl.classList.remove("invisible")
  }

  #hideFieldError(fieldGroup) {
    const errorEl = fieldGroup.querySelector(".rf-error-msg")
    // 만약 서버에서 준 백엔드 비즈니스단위의 100% 필수오류(dataset.serverError)라면
    // JS 클라이언트단 수치 맞춤통과 만으로는 메시지를 끄지 못하도록 보호 조건문.
    if (errorEl && !errorEl.dataset.serverError) {
      errorEl.textContent = " "
      errorEl.classList.add("invisible")
    }
  }
}
