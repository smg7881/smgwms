/**
 * grid_select_utils.js
 *
 * SELECT 엘리먼트(+ TomSelect) 옵션 조작 유틸리티 함수 모음.
 * 검색폼 드롭다운 옵션 세팅/초기화에 사용.
 */

/**
 * 네이티브 HTML `<select>` 와 TomSelect 인스턴스 모두에 대해
 * 주어진 옵션 배열을 주입하고, 필요시 초기 선택값을 반영합니다.
 * 
 * @param {HTMLSelectElement} selectEl 조작할 SELECT 돔 엘리먼트
 * @param {Array<{value: string, label: string}>} options 주입할 `{value, label}` 객체 배열
 * @param {string} [selectedValue=""] 세팅 후 기본으로 선택되게 할 value 값
 * @param {string|null} [blankLabel="전체"] 옵션 맨 첫번째 공간을 차지할 빈 값 라벨명 (null 이면 생성 생략)
 * @returns {string} 최종 선택 처리된 value 값
 */
export function setSelectOptions(selectEl, options, selectedValue = "", blankLabel = "전체") {
  if (!selectEl) return ""

  const normalized = (selectedValue || "").toString()
  const values = options.map((o) => o.value.toString())
  const canSelect = normalized && values.includes(normalized)

  selectEl.innerHTML = ""

  if (blankLabel !== null) {
    const blank = document.createElement("option")
    blank.value = ""
    blank.textContent = blankLabel
    selectEl.appendChild(blank)
  }

  options.forEach((opt) => {
    const el = document.createElement("option")
    el.value = opt.value
    el.textContent = opt.label
    selectEl.appendChild(el)
  })

  selectEl.value = canSelect ? normalized : ""

  const tomSelect = selectEl.tomselect
  if (tomSelect) {
    tomSelect.clearOptions()

    if (blankLabel !== null) {
      tomSelect.addOption({ value: "", text: blankLabel })
    }

    options.forEach((opt) => {
      tomSelect.addOption({ value: opt.value, text: opt.label })
    })

    if (selectEl.multiple) {
      const selectedValues = Array.from(selectEl.selectedOptions).map((option) => option.value)
      tomSelect.setValue(selectedValues, true)
    } else if (canSelect) {
      tomSelect.setValue(normalized, true)
    } else {
      tomSelect.clear(true)
    }

    tomSelect.refreshOptions(false)
  }

  return selectEl.value
}

/**
 * 네이티브 HTML `<select>` 와 TomSelect 인스턴스의 하위 옵션들을 빈칸 혹은 "전체" 라벨 1개만 남기고 모두 지웁니다.
 *
 * @param {HTMLSelectElement} selectEl 클리어할 SELECT 돔 엘리먼트
 * @param {string|null} [blankLabel="전체"] 남겨둘 빈 옵션의 라벨명 (null 이면 완전 비움)
 */
export function clearSelectOptions(selectEl, blankLabel = "전체") {
  setSelectOptions(selectEl, [], "", blankLabel)
}
