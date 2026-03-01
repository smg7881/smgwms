/**
 * code_grid_controller.js
 *
 * 그룹코드(마스터) + 상세코드(디테일) 관리 화면
 * - BaseGridController의 gridRoles(parentGrid) 기반 공통 마스터-디테일 연동 사용
 */
// 다중 그리드(마스터/디테일) 공통 동작을 제공하는 베이스 컨트롤러를 가져옵니다.
import BaseGridController from "controllers/base_grid_controller"
// 경고/안내 메시지 표시 유틸을 가져옵니다.
import { showAlert } from "components/ui/alert"
// 그리드 데이터 처리 및 변경 감지에 사용하는 공통 유틸을 가져옵니다.
import {
  // GET JSON 조회를 수행하는 HTTP 유틸입니다.
  fetchJson,
  // 매니저 기반으로 그리드 rowData를 교체하고 변경 추적을 초기화합니다.
  setManagerRowData,
  // 매니저에 저장 전 변경사항이 있는지 판단합니다.
  hasPendingChanges,
  // 저장되지 않은 변경이 있으면 경고 후 true를 반환해 후속 동작을 막습니다.
  blockIfPendingChanges,
  // URL 템플릿의 치환자(:code 등)를 실제 값으로 바꿉니다.
  buildTemplateUrl,
  // "선택 코드" 같은 화면 라벨 텍스트를 표준 포맷으로 갱신합니다.
  refreshSelectionLabel
} from "controllers/grid/grid_utils"

// 코드 관리(마스터-디테일) 화면 전용 Stimulus 컨트롤러입니다.
export default class extends BaseGridController {
  // 이 컨트롤러가 사용할 Stimulus target 목록입니다.
  // BaseGridController 공통 target + master/detail 그리드 + 선택 라벨 영역을 등록합니다.
  static targets = [...BaseGridController.targets, "masterGrid", "detailGrid", "selectedCodeLabel"]

  // HTML data-* 값으로 주입받을 value 목록입니다.
  static values = {
    // 상위 컨트롤러가 사용하는 공통 values를 그대로 포함합니다.
    ...BaseGridController.values,
    // 마스터 일괄 저장 API URL입니다.
    masterBatchUrl: String,
    // 디테일 일괄 저장 API URL 템플릿입니다. (예: /codes/:code/details/batch)
    detailBatchUrlTemplate: String,
    // 디테일 조회 API URL 템플릿입니다. (예: /codes/:code/details)
    detailListUrlTemplate: String,
    // 현재 선택된 마스터 code 값을 보관합니다.
    selectedCode: String
  }

  // 컨트롤러가 DOM에 연결될 때 1회 호출됩니다.
  connect() {
    // 공통 초기화(그리드 등록/이벤트 바인딩)를 먼저 수행합니다.
    super.connect()
    // 연결 직후 "선택 코드" 라벨을 현재 상태로 맞춥니다.
    this.refreshSelectedCodeLabel()
  }

  // 다중 그리드 역할 정의를 반환합니다.
  // BaseGridController는 이 정보를 기준으로 마스터-디테일 자동 연동을 처리합니다.
  gridRoles() {
    // 역할 정의 객체를 반환합니다.
    return {
      // 마스터(그룹코드) 그리드 역할입니다.
      master: {
        // masterGrid target과 이 역할을 연결합니다.
        target: "masterGrid",
        // 마스터 그리드 CRUD 매니저 설정을 주입합니다.
        manager: this.masterManagerConfig(),
        // 마스터 행 변경 중복 이벤트를 줄이기 위한 키 필드입니다.
        masterKeyField: "code"
      },
      // 디테일(상세코드) 그리드 역할입니다.
      detail: {
        // detailGrid target과 이 역할을 연결합니다.
        target: "detailGrid",
        // 디테일 그리드 CRUD 매니저 설정을 주입합니다.
        manager: this.detailManagerConfig(),
        // 이 그리드는 master 역할을 부모로 가집니다.
        parentGrid: "master",
        // 마스터 행이 바뀔 때마다 호출되는 훅입니다.
        onMasterRowChange: (rowData) => {
          // 선택된 마스터 code를 내부 상태로 갱신합니다.
          this.selectedCodeValue = rowData?.code || ""
          // 상단 라벨에 선택 코드 표시를 반영합니다.
          this.refreshSelectedCodeLabel()
          // 디테일은 항상 새 마스터 기준으로 다시 로드되어야 하므로 먼저 비웁니다.
          this.clearDetailRows()
        },
        // 부모(마스터) 선택 변경 시 디테일 데이터를 불러오는 로더입니다.
        detailLoader: async (rowData) => {
          // 선택된 마스터의 code를 추출합니다.
          const code = rowData?.code
          // 실제 조회 가능한 유효 상태인지 검사합니다.
          // 조건: code 존재 + 삭제행 아님 + 신규행 아님
          const hasLoadableCode = Boolean(code) && !rowData?.__is_deleted && !rowData?.__is_new
          // 유효하지 않으면 빈 배열을 반환해 디테일을 비운 상태로 유지합니다.
          if (!hasLoadableCode) return []

          // 디테일 조회 API 호출은 네트워크 오류 가능성이 있으므로 예외 처리합니다.
          try {
            // detailListUrlTemplate의 :code를 현재 code 값으로 치환합니다.
            const url = buildTemplateUrl(this.detailListUrlTemplateValue, ":code", code)
            // 디테일 행 데이터를 조회합니다.
            const rows = await fetchJson(url)
            // 응답이 배열이면 그대로 사용하고, 아니면 안전하게 빈 배열을 사용합니다.
            return Array.isArray(rows) ? rows : []
          } catch {
            // 조회 실패 시 사용자에게 안내하고, 화면은 빈 배열로 유지합니다.
            showAlert("상세코드 목록 조회에 실패했습니다.")
            return []
          }
        }
      }
    }
  }

  // 마스터(그룹코드) CRUD 매니저 설정을 반환합니다.
  masterManagerConfig() {
    return {
      // 마스터 기본키는 code 하나입니다.
      pkFields: ["code"],
      // 컬럼별 입력 정규화 규칙입니다.
      fields: {
        // code는 앞뒤 공백을 제거합니다.
        code: "trim",
        // code_name은 앞뒤 공백을 제거합니다.
        code_name: "trim",
        // sys_sctn_cd는 공백 제거 후 대문자로 정규화합니다.
        sys_sctn_cd: "trimUpper",
        // 비고는 앞뒤 공백을 제거합니다.
        rmk: "trim",
        // use_yn은 공백 제거/대문자 처리 후 비어있으면 기본값 Y를 넣습니다.
        use_yn: "trimUpperDefault:Y"
      },
      // 신규 행 기본값입니다.
      defaultRow: {
        // 마스터 코드(신규 시 빈값 시작)
        code: "",
        // 마스터 코드명(신규 시 빈값 시작)
        code_name: "",
        // 시스템 구분 코드(신규 시 빈값 시작)
        sys_sctn_cd: "",
        // 비고(신규 시 빈값 시작)
        rmk: "",
        // 사용여부 기본값은 Y
        use_yn: "Y"
      },
      // 저장 전 필수 입력 검증 대상 컬럼입니다.
      blankCheckFields: ["code", "code_name"],
      // 변경 비교(수정 여부 판단) 대상 컬럼입니다.
      comparableFields: [
        "code_name",
        "sys_sctn_cd",
        "rmk",
        "use_yn"
      ],
      // 행 추가 직후 첫 편집 포커스를 줄 컬럼입니다.
      firstEditCol: "code",
      // 사용자 메시지에서 기본키 표시명을 한글로 정의합니다.
      pkLabels: { code: "코드" }
    }
  }

  // 디테일(상세코드) CRUD 매니저 설정을 반환합니다.
  detailManagerConfig() {
    return {
      // 디테일 기본키는 detail_code입니다.
      pkFields: ["detail_code"],
      // 컬럼별 입력 정규화 규칙입니다.
      fields: {
        // 상세코드는 공백 제거
        detail_code: "trim",
        // 상세코드명은 공백 제거
        detail_code_name: "trim",
        // 약칭은 공백 제거
        short_name: "trim",
        // 상위코드는 공백 제거 후 대문자
        upper_code: "trimUpper",
        // 상위상세코드는 공백 제거 후 대문자
        upper_detail_code: "trimUpper",
        // 비고는 공백 제거
        rmk: "trim",
        // 확장 속성1은 공백 제거
        attr1: "trim",
        // 확장 속성2는 공백 제거
        attr2: "trim",
        // 확장 속성3는 공백 제거
        attr3: "trim",
        // 확장 속성4는 공백 제거
        attr4: "trim",
        // 확장 속성5는 공백 제거
        attr5: "trim",
        // 정렬순서는 숫자로 정규화
        sort_order: "number",
        // 사용여부는 공백 제거/대문자 처리 후 기본값 Y
        use_yn: "trimUpperDefault:Y"
      },
      // 신규 디테일 행 기본값입니다.
      defaultRow: {
        // 부모 마스터 코드(FK)
        code: "",
        // 상세코드(PK)
        detail_code: "",
        // 상세코드명
        detail_code_name: "",
        // 약칭
        short_name: "",
        // 상위코드
        upper_code: "",
        // 상위상세코드
        upper_detail_code: "",
        // 비고
        rmk: "",
        // 확장 속성1
        attr1: "",
        // 확장 속성2
        attr2: "",
        // 확장 속성3
        attr3: "",
        // 확장 속성4
        attr4: "",
        // 확장 속성5
        attr5: "",
        // 정렬순서 기본값
        sort_order: 0,
        // 사용여부 기본값
        use_yn: "Y"
      },
      // 저장 전 필수 입력 검증 대상 컬럼입니다.
      blankCheckFields: ["detail_code", "detail_code_name"],
      // 변경 비교(수정 여부 판단) 대상 컬럼입니다.
      comparableFields: [
        "detail_code_name",
        "short_name",
        "upper_code",
        "upper_detail_code",
        "rmk",
        "attr1",
        "attr2",
        "attr3",
        "attr4",
        "attr5",
        "sort_order",
        "use_yn"
      ],
      // 행 추가 직후 첫 편집 포커스를 줄 컬럼입니다.
      firstEditCol: "detail_code",
      // 사용자 메시지에서 기본키 표시명을 한글로 정의합니다.
      pkLabels: { detail_code: "상세코드" }
    }
  }

  // master 역할의 GridCrudManager 인스턴스를 편의 getter로 노출합니다.
  get masterManager() {
    return this.gridManager("master")
  }

  // detail 역할의 GridCrudManager 인스턴스를 편의 getter로 노출합니다.
  get detailManager() {
    return this.gridManager("detail")
  }

  // 검색 실행 직전(BaseGridController 공통 훅) 상태를 초기화합니다.
  beforeSearchReset() {
    // 선택 코드 상태를 비웁니다.
    this.selectedCodeValue = ""
    // 선택 라벨 UI도 비어있는 상태로 갱신합니다.
    this.refreshSelectedCodeLabel()
  }

  // 마스터 신규 행을 추가합니다.
  addMasterRow() {
    this.addRow({
      // 추가 대상은 마스터 매니저입니다.
      manager: this.masterManager,
      // 행 추가 직후 후처리 콜백입니다.
      onAdded: (rowData) => {
        // 방금 추가된 행의 code를 선택 코드 상태로 반영합니다.
        this.selectedCodeValue = rowData?.code || ""
        // 라벨에 선택 코드 표시를 갱신합니다.
        this.refreshSelectedCodeLabel()
        // 마스터가 바뀌었으므로 기존 디테일 데이터를 초기화합니다.
        this.clearDetailRows()
      }
    })
  }

  // 마스터에서 선택된 행(들)을 삭제 상태로 전환합니다.
  deleteMasterRows() {
    this.deleteRows({ manager: this.masterManager })
  }

  // 마스터 변경사항을 저장합니다.
  async saveMasterRows() {
    // 공통 saveRowsWith를 통해 변경점 계산/검증/POST/성공 후처리를 수행합니다.
    await this.saveRowsWith({
      // 저장 대상 매니저는 마스터입니다.
      manager: this.masterManager,
      // 마스터 일괄 저장 API URL입니다.
      batchUrl: this.masterBatchUrlValue,
      // 저장 성공 시 표시할 메시지입니다.
      saveMessage: "코드 데이터가 저장되었습니다.",
      // 저장 성공 후 마스터 목록을 다시 조회합니다.
      onSuccess: () => this.refreshGrid("master")
    })
  }

  // 디테일 신규 행을 추가합니다.
  addDetailRow() {
    // 디테일 매니저가 없으면 처리할 수 없으므로 종료합니다.
    if (!this.detailManager) return
    // 마스터 미저장 변경이 있으면 디테일 작업을 막습니다.
    if (this.blockDetailActionIfMasterChanged()) return

    // 선택된 마스터 코드가 없으면 디테일 추가를 허용하지 않습니다.
    if (!this.selectedCodeValue) {
      showAlert("코드를 먼저 선택해주세요.")
      return
    }

    this.addRow({
      // 추가 대상은 디테일 매니저입니다.
      manager: this.detailManager,
      // 신규 디테일에는 현재 선택 마스터 code(FK)를 강제로 넣습니다.
      overrides: { code: this.selectedCodeValue }
    })
  }

  // 디테일에서 선택된 행(들)을 삭제 상태로 전환합니다.
  deleteDetailRows() {
    // 디테일 매니저가 없으면 종료합니다.
    if (!this.detailManager) return
    // 마스터 미저장 변경이 있으면 디테일 작업을 막습니다.
    if (this.blockDetailActionIfMasterChanged()) return

    // 삭제 처리 대상은 디테일 매니저입니다.
    this.deleteRows({ manager: this.detailManager })
  }

  // 디테일 변경사항을 저장합니다.
  async saveDetailRows() {
    // 디테일 매니저가 없으면 저장할 수 없으므로 종료합니다.
    if (!this.detailManager) return
    // 마스터 미저장 변경이 있으면 디테일 저장을 막습니다.
    if (this.blockDetailActionIfMasterChanged()) return

    // 선택된 마스터 코드가 없으면 디테일 저장을 허용하지 않습니다.
    if (!this.selectedCodeValue) {
      showAlert("코드를 먼저 선택해주세요.")
      return
    }

    // 디테일 저장 URL 템플릿의 :code를 현재 선택 코드로 치환합니다.
    const batchUrl = buildTemplateUrl(this.detailBatchUrlTemplateValue, ":code", this.selectedCodeValue)
    // 공통 saveRowsWith를 통해 변경점 계산/검증/POST/성공 후처리를 수행합니다.
    await this.saveRowsWith({
      // 저장 대상 매니저는 디테일입니다.
      manager: this.detailManager,
      // 디테일 배치 저장 URL입니다.
      batchUrl,
      // 저장 성공 시 표시할 메시지입니다.
      saveMessage: "상세코드 데이터가 저장되었습니다.",
      // 저장 성공 후 마스터 목록을 다시 조회해 화면 전체 정합성을 맞춥니다.
      onSuccess: () => this.refreshGrid("master")
    })
  }

  // 디테일 그리드를 빈 데이터로 초기화합니다.
  clearDetailRows() {
    setManagerRowData(this.detailManager, [])
  }

  // 상단 "선택 코드" 라벨 텍스트를 현재 선택 상태로 갱신합니다.
  refreshSelectedCodeLabel() {
    // 라벨 target이 없는 화면 구성에서는 조용히 종료합니다.
    if (!this.hasSelectedCodeLabelTarget) return
    // 값이 있으면 "선택 코드: X", 없으면 안내 문구를 표시합니다.
    refreshSelectionLabel(this.selectedCodeLabelTarget, this.selectedCodeValue, "코드", "코드를 먼저 선택해주세요.")
  }

  // 마스터에 저장 전 변경사항이 남아있는지 반환합니다.
  hasMasterPendingChanges() {
    return hasPendingChanges(this.masterManager)
  }

  // 마스터 미저장 변경이 있으면 디테일 동작을 차단하고 경고를 표시합니다.
  blockDetailActionIfMasterChanged() {
    return blockIfPendingChanges(this.masterManager, "마스터 코드")
  }
}
