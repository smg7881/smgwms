import BaseGridController from "controllers/base_grid_controller"
import { GridEventManager, rowDataFromGridEvent } from "controllers/grid/grid_event_manager"
import { isApiAlive, focusFirstRow, setManagerRowData } from "controllers/grid/grid_utils"
import { registerGridInstance } from "controllers/grid/core/grid_registration"

/**
 * MasterDetailGridController
 *
 * 마스터-디테일 구조 화면의 공통 베이스 컨트롤러입니다.
 *
 * 핵심 동작:
 * 1. 조회 버튼 클릭 시 → 마스터/디테일 그리드 clear
 *    → 서버 조회 후 마스터 데이터 로드
 *    → onRowDataUpdated 콜백에서 첫 행 선택 + 디테일 조회
 * 2. 마스터 행 클릭/이동/키보드 → 해당 행으로 디테일 조회
 *
 * 하위 컨트롤러 오버라이드 포인트:
 * - detailGridConfigs()   디테일 그리드 등록 설정
 * - isDetailReady()       디테일 영역 준비 상태 확인
 * - handleMasterRowChange(rowData) 마스터 행 변경 시 디테일 처리
 * - clearAllDetails()     상세 그리드 데이터 전체 비우기
 */
export default class MasterDetailGridController extends BaseGridController {

  connect() {
    super.connect()
    this.masterGridEvents = new GridEventManager()
    // 조회 직전 clear를 위해 search_form_controller가 발행하는 이벤트를 수신합니다.
    this._beforeSearchHandler = () => this.handleBeforeSearch()
    document.addEventListener("grid:before-search", this._beforeSearchHandler)
  }

  disconnect() {
    document.removeEventListener("grid:before-search", this._beforeSearchHandler)
    this._beforeSearchHandler = null
    this.masterGridEvents?.unbindAll()
    super.disconnect()
  }

  // ─── 그리드 등록 ───

  registerGrid(event) {
    registerGridInstance(event, this, this.masterDetailGridConfigs(), () => {
      this.onMasterDetailGridsReady()
    })
  }

  masterDetailGridConfigs() {
    return [
      {
        target: this.hasMasterGridTarget ? this.masterGridTarget : null,
        isMaster: true,
        setup: (event) => super.registerGrid(event)
      },
      ...this.detailGridConfigs()
    ]
  }

  // 기본 구현: configure*Manager() + registration 메타로 자동 구성하고,
  // 추가 수동 설정(manualDetailGridConfigs)을 병합합니다.
  detailGridConfigs() {
    return [
      ...this.autoDetailGridConfigs(),
      ...this.manualDetailGridConfigs()
    ]
  }

  // 읽기 전용 detail 등 자동화 대상이 아닌 설정을 수동으로 추가할 때 사용합니다.
  manualDetailGridConfigs() {
    return []
  }

  detailManagerMethods() {
    const methods = []
    const seen = new Set()

    let proto = Object.getPrototypeOf(this)
    while (proto && proto !== BaseGridController.prototype && proto !== Object.prototype) {
      const names = Object.getOwnPropertyNames(proto)
      names.forEach((name) => {
        if (seen.has(name)) return
        if (name === "constructor" || name === "configureManager") return
        if (!/^configure.+Manager$/.test(name)) return

        const descriptor = Object.getOwnPropertyDescriptor(proto, name)
        if (!descriptor) return

        const isCallable = typeof descriptor.value === "function"
        const isGetter = typeof descriptor.get === "function"
        if (!isCallable && !isGetter) return

        seen.add(name)
        methods.push(name)
      })

      proto = Object.getPrototypeOf(proto)
    }

    return methods
  }

  autoDetailGridConfigs() {
    const configs = []

    this.detailManagerMethods().forEach((configMethod) => {
      const source = this[configMethod]
      const rawConfig = typeof source === "function" ? source.call(this) : source
      const { registration } = this.splitManagerConfig(rawConfig)
      if (!registration) return

      const targetName = registration.targetName
      if (!targetName || typeof targetName !== "string") return

      const target = this.resolveTargetByName(targetName)
      if (!target) {
        console.warn(`[${this.identifier}] detail grid target not found: ${targetName}`)
        return
      }

      const detailConfig = {
        target,
        configMethod
      }

      if (registration.controllerKey) {
        detailConfig.controllerKey = registration.controllerKey
      }
      if (registration.managerKey) {
        detailConfig.managerKey = registration.managerKey
      }

      configs.push(detailConfig)
    })

    return configs
  }

  resolveTargetByName(targetName) {
    const hasTargetKey = `has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`
    const targetKey = `${targetName}Target`

    if (this[hasTargetKey] && this[targetKey]) {
      return this[targetKey]
    }

    return null
  }

  // ─── 마스터/디테일 준비 완료 ───

  onMasterDetailGridsReady() {
    this.bindMasterGridEvents()
    // 그리드에 이미 데이터가 있으면 첫 행으로 디테일 조회
    this.selectFirstMasterRow()
  }

  // ─── 마스터 이벤트 바인딩 ───

  bindMasterGridEvents() {
    this.masterGridEvents.unbindAll()
    this.masterGridEvents.bind(this.manager?.api, "rowClicked", this.handleMasterGridEvent)
    this.masterGridEvents.bind(this.manager?.api, "cellFocused", this.handleMasterGridEvent)
  }

  // 마스터 그리드 이벤트(rowClicked, cellFocused)를 처리합니다.
  handleMasterGridEvent = async (event) => {
    const rowData = rowDataFromGridEvent(this.manager?.api, event)
    if (!rowData) return
    await this.handleMasterRowChange(rowData)
  }

  // ─── 핵심 로직 ───

  // 마스터 그리드에서 첫 번째 행을 선택하고 디테일을 조회합니다.
  // onRowDataUpdated 콜백, 그리드 준비 완료 시점에서 호출합니다.
  selectFirstMasterRow() {
    if (!isApiAlive(this.manager?.api) || !this.isDetailReady()) return

    const firstData = focusFirstRow(this.manager.api, { ensureVisible: true, select: false })
    if (!firstData) {
      // 마스터가 비어 있으면 디테일도 비웁니다.
      this.handleMasterRowChange(null)
      return
    }
    this.handleMasterRowChange(firstData)
  }

  // 하위 클래스 훅: 마스터 행 변경 시 디테일 처리를 구현합니다.
  // rowData가 null이면 디테일을 비워야 합니다.
  async handleMasterRowChange(rowData) {
    // 하위 컨트롤러에서 오버라이드
  }

  // ─── 조회 직전 clear ───

  // 조회 버튼 클릭 직전(grid:before-search) 이벤트 처리
  handleBeforeSearch() {
    this.clearMasterGrid()
    this.clearAllDetails()
  }

  // 마스터 그리드 데이터를 비웁니다.
  clearMasterGrid() {
    if (isApiAlive(this.manager?.api)) {
      setManagerRowData(this.manager, [])
    }
  }

  // 하위 클래스 훅: 모든 상세 그리드 데이터를 비웁니다.
  clearAllDetails() { }

  // ─── 하위 클래스 오버라이드 포인트 ───

  // 디테일 영역 준비 상태 확인 (기본값: 항상 준비됨)
  isDetailReady() {
    return true
  }
}
