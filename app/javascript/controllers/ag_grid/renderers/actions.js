import { emit, createActionButton } from "controllers/ag_grid/renderers/common"

/**
 * 공통 액션 셀 렌더러
 *
 * page_component.rb의 cellRendererParams.actions 배열을 읽어 버튼을 동적 생성합니다.
 *
 * actions 배열 각 요소 형식:
 *   - type: 버튼 타입 키워드 (아래 ACTION_TYPES 매핑 참조, text보다 우선)
 *       "edit"        → "✎", 제목: "수정"
 *       "delete"      → "X", 제목: "삭제" (danger 스타일 자동 적용)
 *       "add_child"   → "+", 제목: 하위추가 (title 필수)
 *   - text: 버튼 텍스트 직접 지정 (type 미사용 시)
 *   - title: 버튼 툴팁
 *   - eventName: 발행할 이벤트 이름
 *   - dataKeys: 이벤트 데이터 매핑 객체
 *       - { 이벤트속성: "data필드명" } → { 이벤트속성: data[필드명] }
 *       - 값이 null이면 params.data 전체를 해당 키에 할당
 *       - "field1||field2" 형태로 fallback 지원 → data[field1] || data[field2]
 *   - classes: 추가 CSS 클래스 배열 (선택)
 *
 * 사용 예 (page_component.rb):
 *   cellRenderer: "actionCellRenderer",
 *   cellRendererParams: { actions: [
 *     { type: "edit",   eventName: "user-crud:edit",   dataKeys: { userData: nil } },
 *     { type: "delete", eventName: "user-crud:delete", dataKeys: { id: "id", userNm: "user_nm" } }
 *   ]}
 */

// 버튼 타입별 텍스트/제목/스타일 매핑
const ACTION_TYPES = {
  edit: { text: "\u270E", title: "수정", classes: [] },
  delete: { text: "X", title: "삭제", classes: ["grid-action-btn--danger"] },
  add_child: { text: "+", title: "추가", classes: [] }
}

/**
 * dataKeys 매핑으로 이벤트 데이터 객체를 생성합니다.
 * @param {Object} data - params.data (행 데이터)
 * @param {Object} dataKeys - 매핑 정의
 * @returns {Object} 이벤트에 전달할 데이터
 */
function buildEventData(data, dataKeys) {
  const result = {}
  for (const [key, fieldSpec] of Object.entries(dataKeys)) {
    if (fieldSpec == null) {
      // 값이 null이면 전체 행 데이터를 할당
      result[key] = data
    } else if (typeof fieldSpec === "string" && fieldSpec.includes("||")) {
      // "field1||field2" 형태: fallback 지원
      const fields = fieldSpec.split("||").map(f => f.trim())
      result[key] = fields.reduce((val, f) => val || data[f], undefined)
    } else {
      // 단순 필드명 매핑
      result[key] = data[fieldSpec]
    }
  }
  return result
}

export const ACTION_RENDERER_REGISTRY = {
  /**
   * 공통 액션 셀 렌더러
   * cellRendererParams.actions 배열로 버튼을 동적 생성합니다.
   */
  actionCellRenderer: (params) => {
    const container = document.createElement("div")
    container.classList.add("grid-action-buttons")

    const actions = params.colDef?.cellRendererParams?.actions || []

    actions.forEach((action) => {
      // type 키워드가 있으면 해당 타입의 기본값 사용, 없으면 직접 지정값 사용
      const preset = ACTION_TYPES[action.type] || {}
      const text = action.text ?? preset.text ?? ""
      const title = action.title ?? preset.title ?? ""
      const classes = action.classes ?? preset.classes ?? []
      const dataKeys = action.dataKeys || {}

      container.appendChild(createActionButton({
        text,
        title,
        classes,
        onClick: () => emit(container, action.eventName, buildEventData(params.data, dataKeys))
      }))
    })

    return container
  }
}
