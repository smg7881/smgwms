/**
 * AG Grid 컬럼 정의 데이터를 생성하고 포맷팅하는 유틸리티 모듈입니다.
 * 팝업 렌더러, 커스텀 포맷터 등록 및 편집 속성 등을 일괄 처리합니다.
 */

/**
 * 주어진 컬럼 정의가 팝업(Lookup) 컬럼인지 여부를 반환합니다.
 * lookup_popup_type 속성이나 context 내의 값을 확인합니다.
 *
 * @param {Object} colDef - AG Grid 컬럼 정의 객체
 * @returns {boolean} 팝업 컬럼 여부
 */
export function isLookupColumnDef(colDef) {
  if (!colDef) return false
  if (colDef.context?.lookup_popup_type) return true
  return Boolean(colDef.lookup_popup_type)
}

/**
 * 원본 컬럼 정의 배열을 받아 AG Grid에 맞게 속성들을 변환하고 적용합니다.
 *
 * @param {Array} columns - 백엔드 등에서 전달받은 원본 컬럼 배열
 * @param {Object} options - 포맷터, 렌더러 레지스트리 및 팝업 컬럼 확인 함수
 * @returns {Array} 변환이 완료된 AG Grid 컬럼 배열
 */
export function buildColumnDefs(columns, {
  formatterRegistry = {},
  rendererRegistry = {},
  isLookupColumn = isLookupColumnDef
} = {}) {
  return columns.map((column) => {
    // 얕은 복사로 원본 데이터 유지
    const def = { ...column }

    // context 객체 초기화 (AG Grid 셀 컨텍스트 용도)
    def.context = def.context || {}

    // "lookup_"으로 시작하는 속성들을 추출하여 context 내부로 이동시키고 원본에서는 제거
    Object.keys(def).forEach((key) => {
      if (key.startsWith("lookup_")) {
        def.context[key] = def[key]
        delete def[key]
      }
    })

    // 팝업 검색 컬럼인 경우 관련 기본 속성 자동 세팅
    const hasLookupPopup = isLookupColumn(def)
    if (hasLookupPopup) {
      if (!def.context.lookup_name_field && def.field) {
        def.context.lookup_name_field = def.field
      }
      if (!def.cellRenderer) {
        def.cellRenderer = "lookupPopupCellRenderer" // 기본 팝업 렌더러 지정
      }
      def.editable = false // 팝업 컬럼은 직접 텍스트 편집 불가
    }

    // 문자열로 지정된 formatter 속성이 있다면 실제 함수로 매핑
    if (def.formatter && formatterRegistry[def.formatter]) {
      def.valueFormatter = formatterRegistry[def.formatter]
      delete def.formatter
    }

    // 문자열로 지정된 cellRenderer가 있다면 레지스트리에서 컴포넌트로 매핑
    if (def.cellRenderer && rendererRegistry[def.cellRenderer]) {
      def.cellRenderer = rendererRegistry[def.cellRenderer]
    }

    // 편집 가능한 컬럼일 경우 삭제된 행(__is_deleted)은 수정할 수 없도록 함수로 변경
    if (def.editable === true) {
      def.editable = (params) => !params?.data?.__is_deleted
    }

    return def
  })
}

