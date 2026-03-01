# AG Grid 리팩토링 Phase 1 코드 변경 스펙

## 1. 목표
- `BaseGridController` 단일 베이스에서 마스터-디테일 자동 연동 제공
- `MasterDetailGridController`가 담당하던 공통 기능을 Base로 흡수할 기반 완성
- 기존 단일 그리드 화면은 동작 변경 없이 유지

---

## 2. 변경 대상 파일
- `app/javascript/controllers/base_grid_controller.js` (핵심)
- `app/javascript/controllers/ag_grid_controller.js` (이벤트 연동 확인/최소 수정 가능)

---

## 3. 설계 규약

## 3.1 `gridRoles()` 확장 스키마
```js
gridRoles() {
  return {
    master: {
      target: "masterGrid",
      manager: { ... },              // 선택: CRUD 필요 시
      masterKeyField: "code",        // 선택: 중복 디테일 조회 방지 키
      autoLoadOnReady: true          // 선택: rowDataUpdated 시 첫 행 자동 포커스/연동
    },
    detail: {
      target: "detailGrid",
      manager: { ... },              // null 또는 생략 가능(읽기 전용)
      parentGrid: "master",          // 필수(디테일로 동작하려면)
      detailLoader: async (row) => [],
      onMasterRowChange: (row) => {}
    }
  }
}
```

## 3.2 호환 규칙
- `gridRoles() === null`: 기존 단일 그리드 모드 유지
- role에 `parentGrid` 미지정: 기존 다중 독립 그리드로 간주
- role에 `manager` 미지정: 읽기 전용 API 컨트롤러로 등록

---

## 4. BaseGridController 변경 상세

## 4.1 내부 상태(Private) 추가
- `#roleConfigs`: role 원본 설정 캐시
- `#parentToChildren`: `{ parentRole: [childRole...] }` 매핑
- `#masterLastKey`: `{ masterRole: lastKey }` 캐시 (중복 조회 방지)
- `#allGridsReady`: 전체 등록 완료 여부
- `#beforeSearchHandler`: `grid:before-search` 리스너 핸들러

## 4.2 `connect()/disconnect()` 확장
- `connect()`:
  - 기존 초기화 + role 메타 파싱
  - `document.addEventListener("grid:before-search", ...)` 등록
- `disconnect()`:
  - 기존 정리 + 위 이벤트 해제

## 4.3 다중 그리드 등록 로직 확장
- 기존 `#registerMultiGrid(...)`에서 role 등록 시 아래 처리 추가:
  - role별 `manager` 생성/attach (설정 존재 시)
  - role별 grid 이벤트 바인딩
    - 마스터 role: `rowDataUpdated`, `rowFocused` 경로 연결
  - 전체 role 준비 완료 시 `#allGridsReady=true`, `onAllGridsReady()` 호출

## 4.4 마스터 행 변경 공통 핸들러 추가
- 신규 메서드(예시):
  - `#handleMasterRowFocus(masterRole, rowData)`
  - `#dispatchMasterToChildren(masterRole, rowData)`
  - `#resolveMasterKey(masterRole, rowData)`
- 동작:
  - `masterKeyField` 기준 중복 키면 skip
  - 자식 role 순회:
    - `onMasterRowChange?.(rowData)` 실행
    - `detailLoader` 있으면 await 후 rowData 주입
      - manager 있으면 `setManagerRowData`
      - manager 없으면 `setRows(role, rows)`

## 4.5 첫 행 자동 포커스/조회 공통화
- 신규 public 메서드:
  - `selectFirstRow(roleName, { ensureVisible=true, select=false })`
  - `selectFirstMasterRow(masterRole)` (편의 메서드)
- `rowDataUpdated` 시:
  - 자식 manager `resetTracking()`
  - 첫 행 포커스 설정
  - 동일한 마스터 행 변경 경로로 디테일 조회

## 4.6 조회 직전 clear 처리 (`grid:before-search`)
- Base에서 공통 수행:
  - 마스터/자식 role 데이터 clear
  - `#masterLastKey` 초기화
  - 자식 manager tracking 초기화

---

## 5. 이벤트 연동 스펙

## 5.1 우선 이벤트
- 우선: `ag-grid:rowFocused` (클릭/키보드 공통, 액션 컬럼 제외된 이벤트)

## 5.2 fallback 이벤트
- 필요 시 AG Grid API `cellFocused` 바인딩 허용
- 단, 액션/체크박스 컬럼 필터링 후 처리

## 5.3 `ag_grid_controller.js` 확인 포인트
- 현재 `onCellFocused` -> `ag-grid:rowFocused` 발행 구조 유지
- Base는 해당 커스텀 이벤트를 소비하는 방식으로 우선 구현

---

## 6. 기존 API/오버라이드 호환

## 6.1 유지되는 오버라이드
- `configureManager()`, `gridRoles()`, `onAllGridsReady()`
- `addRow/deleteRows/saveRowsWith` 등 단일 CRUD 액션

## 6.2 신규 권장 오버라이드
- 다중 마스터-디테일 화면:
  - `gridRoles()`에서 `parentGrid`, `detailLoader`, `onMasterRowChange` 사용

## 6.3 이 Phase에서 미변경
- 도메인 컨트롤러 실제 전환 작업은 Phase 2+
- `MasterDetailGridController` 파일 삭제는 Phase 6

---

## 7. 구현 순서(코딩 단계)
1. `BaseGridController`에 private 상태/리스너 골격 추가  
2. role 파싱/부모-자식 맵 구성 로직 추가  
3. 다중 등록 시 manager 자동 attach + 이벤트 바인딩 추가  
4. 마스터 포커스 변경 -> 자식 로딩 공통 메서드 추가  
5. `grid:before-search` clear 처리 추가  
6. `rowDataUpdated` 첫 행 자동 처리 공통화  
7. 단일/다중 회귀 확인  

---

## 8. 검증 체크리스트

## 8.1 단일 그리드(회귀)
- 기존 조회/추가/삭제/저장 정상
- 오류/콘솔 경고 없음

## 8.2 다중 그리드(파일럿 대상 준비)
- 마스터 조회 시 디테일 clear
- 마스터 1건 이상이면 첫 행 자동 포커스
- 첫 행 기준 디테일 자동 조회
- 키보드 이동 시 디테일 재조회
- 동일 키 재포커스 시 중복 호출 없음

---

## 9. 리스크 및 대응
- 리스크: rowFocused 이벤트 누락 시 자동 조회 미동작
  - 대응: fallback으로 `selectFirstMasterRow()` 내부 직접 dispatch
- 리스크: 비동기 응답 역전(stale)
  - 대응: `masterKeyField` + 마지막 키 검증으로 늦은 응답 무시
- 리스크: 다중 role에서 manager null 처리 누락
  - 대응: `manager` 유무 분기 강제(`setManagerRowData` vs `setRows`)

---

## 10. 완료 조건(Phase 1 Done)
- `BaseGridController` 단독으로 마스터-디테일 공통 흐름 제공
- 기존 단일 그리드 컨트롤러 회귀 없음
- 파일럿(`code_grid_controller`) 전환 준비 상태 확보

---

## 11. AG Grid 이벤트 기반 자동 연동 흐름 (상세)

```
[마스터 데이터 로드] → AG Grid rowDataUpdated
  → BaseGridController: 모든 디테일 manager.resetTracking()
  → BaseGridController: api.setFocusedCell(0, firstCol) → 첫 행 포커스
    → AG Grid cellFocused 이벤트 발생
      → BaseGridController #onMasterCellFocused()
        → masterKeyField로 중복 조회 방지 (이전 키와 동일하면 skip)
        → 각 디테일 role: onMasterRowChange?.(rowData) + detailLoader(rowData)

[사용자 마스터 행 클릭/키보드 이동] → AG Grid cellFocused
  → 동일한 #onMasterCellFocused() 로직 실행
```

**rowClicked 이벤트는 더 이상 바인딩하지 않음** — `cellFocused`가 클릭과 키보드를 모두 커버

---

## 12. Phase 1 이후 마이그레이션 유형별 대상 요약

### 유형 A: 단순 1:1 마스터-디테일 (Phase 2~3)
| 컨트롤러 | 구조 |
|----------|------|
| `code_grid_controller.js` | 그룹코드 + 상세코드 (Phase 2 파일럿) |
| `std_corporation_grid_controller.js` | 법인 + 국가 |
| `wm_pur_fee_rt_grid_controller.js` | 매입요율 + 상세 |

### 유형 B: 마스터 + 다중 디테일 (Phase 3)
| 컨트롤러 | 구조 |
|----------|------|
| `client_grid_controller.js` | 거래처 + (담당자 + 작업장) |
| `sell_contract_grid_controller.js` | 매출계약 + (정산 + 이력) |
| `purchase_contract_grid_controller.js` | 매입계약 + (정산 + 이력) |

### 유형 C: 마스터 + 읽기전용 디테일 (Phase 3)
| 컨트롤러 | 구조 |
|----------|------|
| `wm_gr_prar_grid_controller.js` | 입고예정 + (입고상세 + 실행이력) |

### registerGridInstance 직접 사용 (Phase 4)
| 컨트롤러 |
|----------|
| `om_pre_order_file_upload_controller.js` |
| `role_user_grid_controller.js` |
| `search_popup_grid_controller.js` |
| `std_favorite_grid_controller.js` |
| `std_region_zip_grid_controller.js` |
| `user_menu_role_grid_controller.js` |
| `zone_grid_controller.js` |

---

## 13. 단일 그리드 / 기존 gridRoles 호환성 보장

### 단일 그리드 모드 (기존 ~30개 컨트롤러)
`gridRoles()`가 null 반환 → 기존과 100% 동일하게 동작. **Phase 1에서 변경 불필요**

### 기존 gridRoles 다중 그리드 (OM 모듈 ~6개)
`parentGrid` 없는 role → 기존처럼 읽기전용 다중 그리드. **Phase 1에서 변경 불필요**

---

## 14. 파일 유지/삭제 판단 (Phase 1 관점)

Phase 1에서는 **삭제 없음**. 아래 파일은 Phase 6(최종 정리)에서 처리:

| 파일 | 최종 판단 |
|------|----------|
| `master_detail_grid_controller.js` | Phase 6 삭제 |
| `grid/core/grid_registration.js` | Phase 6 삭제 |
| `grid/grid_utils.js` | Phase 6 pass-through 제거 |
| `grid/grid_event_manager.js` | Phase 6 `resolveAgGridRegistration` 제거 |

Phase 1 완료 시점에는 `BaseGridController`가 마스터-디테일 기반을 제공하되, 기존 파일은 모두 그대로 유지합니다.
