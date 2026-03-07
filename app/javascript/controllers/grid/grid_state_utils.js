/**
 * grid_state_utils.js
 *
 * 그리드 변경 상태 체크 및 비즈니스 흐름 제어 유틸리티 함수 모음.
 * 저장 전 변경 감지, 선택값 검증, 마스터 행 로드 가능 여부 판별 등.
 */
import { showAlert } from "components/ui/alert"

/**
 * GridCrudManager가 추출해낸 `operations`(저장 대상 페이로드) 내부에
 * 실제로 추가/수정/삭제 예정인 타겟(Row)이 1건 이라도 존재하는지 확인합니다.
 *
 * @param {Object} operations {rowsToInsert: [], rowsToUpdate: [], rowsToDelete: []} 형태의 추출 객체
 * @returns {boolean} 변경 사항이 있다면 true
 */
export function hasChanges(operations) {
  return (
    operations.rowsToInsert.length > 0 ||
    operations.rowsToUpdate.length > 0 ||
    operations.rowsToDelete.length > 0
  )
}

/**
 * GridCrudManager 인스턴스를 통해 곧바로 현재 그리드 상의 미저장(Pending) 변경점이 존재하는지 파악합니다.
 * 
 * @param {Object} manager GridCrudManager 인스턴스
 * @returns {boolean} 미저장 변경점이 존재 시 true
 */
export function hasPendingChanges(manager) {
  if (!manager) return false
  return hasChanges(manager.buildOperations())
}

/**
 * 폼 전송, 혹은 계층 구조 디테일 데이터를 불러오기 전 마스터 키(Value)가 필수로 선택되어 있는지 검증합니다.
 * 값이 없으면 설정된 경고 문구를 Alert 모달로 띄워 사용자 입력을 유도합니다.
 *
 * @param {any} value 검증할 핵심 대상의 값 (ex: 마스터 그리드의 PK)
 * @param {Object} [options] 알림창 관련 설정값
 * @param {string} [options.entityLabel="Target"] 알림 문구에 표시될 대상 이름
 * @param {string} [options.title="Warning"] Alert 창의 제목 영역
 * @param {string} [options.type="warning"] Alert 테마 종류 (success, error, warning, info)
 * @param {string} [options.message=null] 커스텀 메시지를 강제로 띄울 경우 사용
 * @returns {boolean} 값이 유효(존재)하면 true, 비어있어 경고창을 띄우면 false
 */
export function requireSelection(
  value,
  {
    entityLabel = "Target",
    title = "Warning",
    type = "warning",
    message = null
  } = {}
) {
  const present = value != null && String(value).trim() !== ""
  if (present) return true

  const fallback = `${entityLabel}을(를) 먼저 선택해주세요.`
  showAlert(title, message || fallback, type)
  return false
}

/**
 * 마스터 그리드 내 특정 행 데이터(rowData)가 하위 디테일 그리드를 로드(Fetch)하기 적합한(정상 저장된) 상태인지 판별합니다.
 *
 * @param {Object} rowData 검사할 마스터 그리드 행 데이터 객체
 * @param {string} keyField 식별자(PK)로 사용 중인 필드
 * @returns {boolean} 로드 가능한 정상 행이면 true (신규 추가 중이거나, 삭제 마킹 중이면 false)
 */
export function isLoadableMasterRow(rowData, keyField) {
  if (!rowData || !keyField) return false

  const keyValue = rowData[keyField]
  if (keyValue == null || String(keyValue).trim() === "") return false
  if (rowData.__is_deleted || rowData.__is_new) return false
  return true
}

/**
 * (주로 마스터 데이터의 변경으로 인해 Detail 그리드를 갱신하려 할 때)
 * 현재 대상 그리드/폼에 "저장되지 않은 변경점" 이 남아있다면 동작을 막고 Alert을 띄웁니다.
 *
 * @param {Object} manager 대상 영역의 GridCrudManager 단위
 * @param {string} [entityLabel="마스터"] 문구에 띄워줄 대상의 이름
 * @returns {boolean} 작업 중단(Block) 조치가 취해졌다면 true
 */
export function blockIfPendingChanges(manager, entityLabel = "마스터") {
  if (!hasPendingChanges(manager)) return false
  showAlert(`${entityLabel}에 저장되지 않은 변경이 있습니다.`)
  return true
}
