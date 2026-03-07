/**
 * grid_select_utils.js
 *
 * SELECT 엘리먼트(+ TomSelect) 옵션 조작 유틸리티 함수 모음.
 * 검색폼 드롭다운 옵션 세팅/초기화에 사용.
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

export function clearSelectOptions(selectEl, blankLabel = "전체") {
  setSelectOptions(selectEl, [], "", blankLabel)
}
