import { Controller } from "@hotwired/stimulus"

// 리소스 폼을 제어하는 Stimulus 컨트롤러
// 폼 유효성 검사, 의존성 필드 처리, 로딩 상태 관리 등을 담당합니다.
export default class extends Controller {
  static targets = [
    "form",             // 폼 엘리먼트
    "fieldGroup",       // 각 필드를 감싸는 그룹 (레이블 + 입력)
    "input",            // 입력 필드 (input, select, textarea 등)
    "dependentField",   // 다른 필드 값에 의존하는 필드
    "submitBtn",        // 제출 버튼
    "submitText",       // 제출 버튼 텍스트
    "submitSpinner",    // 로딩 스피너
    "resetBtn",         // 초기화 버튼
    "errorSummary",     // 상단 에러 메시지 영역
    "buttonGroup"       // 버튼 그룹 컨테이너
  ]

  static values = {
    loading: { type: Boolean, default: false }, // 로딩 상태 (true/false)
    dependencies: { type: Object, default: {} } // 필드 간 의존성 설정 객체
  }

  connect() {
    // 컨트롤러 연결 시 의존성 필드 초기화
    this.#initializeDependencies()
  }

  // ── Actions ──

  // 폼 제출 처리
  submit(event) {
    // 로딩 중이면 중복 제출 방지
    if (this.loadingValue) {
      event.preventDefault()
      return
    }

    // 브라우저 기본 유효성 검사 실행
    if (!this.formTarget.checkValidity()) {
      event.preventDefault()
      this.formTarget.reportValidity() // 브라우저 에러 메시지 표시
      this.#highlightInvalidFields()   // 유효하지 않은 필드 강조
      return
    }

    // 유효성 검사 통과 시 로딩 상태로 변경
    this.loadingValue = true
  }

  // 폼 초기화
  reset(event) {
    event.preventDefault()

    this.formTarget.reset()       // 폼 리셋
    this.loadingValue = false     // 로딩 상태 해제
    this.#clearErrors()           // 에러 메시지 제거
    this.#initializeDependencies()// 의존성 필드 상태 재설정
  }

  // 개별 필드 유효성 검사 (input 이벤트 등에서 호출)
  validateField(event) {
    const input = event.target
    const fieldGroup = input.closest("[data-field-name]")
    if (!fieldGroup) return

    if (input.checkValidity()) {
      // 유효하면 에러 클래스 및 메시지 제거
      input.classList.remove("rf-field-error")
      this.#hideFieldError(fieldGroup)
    } else {
      // 유효하지 않으면 에러 클래스 추가 및 메시지 표시
      input.classList.add("rf-field-error")
      this.#showFieldError(fieldGroup, input.validationMessage)
    }
  }

  // Select 필드 변경 시 호출 (의존성 처리)
  onSelectChange(event) {
    const parentField = event.target.closest("[data-field-name]")
    if (!parentField) return

    const parentName = parentField.dataset.fieldName
    // 변경된 부모 필드에 의존하는 자식 필드 업데이트
    this.#updateDependentFields(parentName, event.target.value)
  }

  // ── Value Callbacks ──

  // loading 값 변경 시 UI 업데이트
  loadingValueChanged() {
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = this.loadingValue // 버튼 비활성화
    }
    if (this.hasSubmitTextTarget && this.hasSubmitSpinnerTarget) {
      this.submitSpinnerTarget.hidden = !this.loadingValue // 스피너 표시/숨김
    }
  }

  // ── Private ──

  // 의존성 설정 초기화
  #initializeDependencies() {
    if (!this.hasDependenciesValue || Object.keys(this.dependenciesValue).length === 0) return

    // 설정된 각 의존성에 대해 부모 필드 찾기 및 이벤트 리스너 설정
    for (const [childField, config] of Object.entries(this.dependenciesValue)) {
      const parentEl = this.element.querySelector(`[data-field-name="${config.parent}"] select`)
      if (parentEl) {
        // 부모 필드에 change 이벤트 액션 추가 (이미 있으면 추가하지 않도록 주의 필요하나 여기서는 단순 연결)
        // 실제로는 data-action 속성을 동적으로 수정하는 방식
        if (!parentEl.dataset.action?.includes("resource-form#onSelectChange")) {
          parentEl.dataset.action = (parentEl.dataset.action || "") + " change->resource-form#onSelectChange"
        }

        // 초기 로드 시 상태 업데이트
        this.#updateDependentFields(config.parent, parentEl.value)
      }
    }
  }

  // 부모 필드 변경에 따라 자식 필드 업데이트
  #updateDependentFields(parentName, parentValue) {
    const deps = this.dependenciesValue

    for (const [childField, config] of Object.entries(deps)) {
      if (config.parent !== parentName) continue

      const childGroup = this.element.querySelector(`[data-field-name="${childField}"]`)
      if (!childGroup) continue

      const childSelect = childGroup.querySelector("select")
      if (!childSelect) continue

      // 자식 필드 옵션 필터링
      this.#filterDependentOptions(childSelect, parentValue, config.filter_key)
    }
  }

  // 자식 Select 옵션 필터링 로직
  #filterDependentOptions(selectEl, parentValue, filterKey) {
    // 모든 옵션 데이터는 data-all-options 속성에 JSON으로 저장되어 있어야 함
    const allOptionsJson = selectEl.dataset.allOptions
    if (!allOptionsJson) return

    let allOptions
    try {
      allOptions = JSON.parse(allOptionsJson)
    } catch {
      return
    }

    // 빈 옵션(선택해주세요 등) 보존
    const blankOption = selectEl.querySelector('option[value=""]')
    selectEl.innerHTML = "" // 기존 옵션 초기화

    if (blankOption) {
      selectEl.appendChild(blankOption)
    }

    // 부모 값이 있으면 필터링, 없으면 전체 표시 (또는 정책에 따라 다름)
    // 여기서는 parentValue가 있을 때만 해당 key로 필터링
    const filtered = parentValue
      ? allOptions.filter(opt => {
        // 필터 키에 해당하는 값이 부모 값과 일치하는지 확인
        const filterVal = opt[filterKey] || opt[`${filterKey}`]
        return String(filterVal) === String(parentValue)
      })
      : allOptions // 부모 선택이 없으면 전체 옵션 노출 (또는 빈 상태로 둘 수도 있음)

    // 필터링된 옵션 추가
    for (const opt of filtered) {
      const option = document.createElement("option")
      option.value = opt.value || opt["value"]
      option.textContent = opt.label || opt["label"]
      selectEl.appendChild(option)
    }

    // 자식 필드 값 변경 이벤트 트리거 (연쇄 의존성 처리를 위해)
    selectEl.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // 유효하지 않은 모든 필드 강조 표시
  #highlightInvalidFields() {
    this.inputTargets.forEach(input => {
      if (!input.checkValidity()) {
        input.classList.add("rf-field-error")
      }
    })
  }

  // 에러 메시지 및 스타일 초기화
  #clearErrors() {
    // 필드 레벨 에러 제거
    this.element.querySelectorAll(".rf-field-error").forEach(el => {
      el.classList.remove("rf-field-error")
    })
    this.element.querySelectorAll(".rf-error-msg").forEach(el => {
      el.remove()
    })

    // 상단 에러 요약 제거
    if (this.hasErrorSummaryTarget) {
      this.errorSummaryTarget.remove()
    }
  }

  // 필드 에러 메시지 표시
  #showFieldError(fieldGroup, message) {
    let errorEl = fieldGroup.querySelector(".rf-error-msg")
    if (!errorEl) {
      errorEl = document.createElement("span")
      errorEl.classList.add("rf-error-msg")
      fieldGroup.appendChild(errorEl)
    }
    errorEl.textContent = message
  }

  // 필드 에러 메시지 숨김 (서버 사이드 에러는 유지할지 여부 결정 필요)
  #hideFieldError(fieldGroup) {
    const errorEl = fieldGroup.querySelector(".rf-error-msg")
    // data-server-error 속성이 없는 클라이언트 에러만 제거
    if (errorEl && !errorEl.dataset.serverError) {
      errorEl.remove()
    }
  }
}


