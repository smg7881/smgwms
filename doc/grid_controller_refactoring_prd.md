# Grid 컨트롤러 공통 로직 추출 및 리팩토링 PRD

## 1. 개요

### 1.1 배경
현재 8개의 Grid Stimulus 컨트롤러에서 동일한 CRUD/추적/유틸리티 로직이 복사-붙여넣기로 반복되고 있다.
총 3,060줄 중 약 59%가 중복 코드이며, 새 그리드 화면 추가 시마다 동일한 보일러플레이트를 복사해야 하는 유지보수 부담이 존재한다.

### 1.2 목표
- 공통 로직을 `GridCrudManager` + `BaseGridController` + `grid_utils`로 추출
- 각 컨트롤러는 설정(static config)만 선언하여 상속받아 사용
- 기존 기능 100% 동일 동작 보장

### 1.3 범위
- 대상 컨트롤러: role_grid, workplace_grid, area_grid, location_grid, zone_grid, code_grid, role_user_grid, user_menu_role_grid
- 기존 BaseCrudController(모달 CRUD)는 변경 없이 유지

## 2. 아키텍처

### 2.1 계층 구조

```
grid/grid_utils.js          ← 순수 유틸리티 함수 (named exports)
grid/grid_crud_manager.js   ← CRUD 상태 추적 클래스 (AG Grid API 래핑)
base_grid_controller.js     ← 단일 그리드 CRUD Stimulus 베이스 컨트롤러
```

### 2.2 컨트롤러별 적용 전략

| 유형 | 컨트롤러 | 적용 방식 |
|---|---|---|
| 단순 단일 그리드 | role_grid, workplace_grid | BaseGridController 상속, config만 선언 |
| 복합 PK 단일 그리드 | area_grid, location_grid | BaseGridController 상속 + 고유 훅 오버라이드 |
| 마스터-디테일 | zone_grid, code_grid | Controller 직접 상속 + GridCrudManager 인스턴스 조합 |
| 유틸리티만 사용 | role_user_grid, user_menu_role_grid | isApiAlive, getCsrfToken만 import 대체 |

## 3. 모듈 상세 설계

### 3.1 grid_utils.js

순수 함수만 제공하며 상태를 갖지 않는다.

| 함수 | 시그니처 | 설명 |
|---|---|---|
| `isApiAlive` | `(api) → boolean` | AG Grid API 생존 확인 |
| `uuid` | `() → string` | 임시 행 ID 생성 |
| `getCsrfToken` | `() → string` | CSRF 토큰 추출 |
| `postJson` | `(url, body) → Promise<boolean>` | JSON POST + 에러 처리 |
| `hideNoRowsOverlay` | `(api) → void` | "No Rows" 오버레이 숨김 |
| `collectRows` | `(api) → Array` | forEachNode로 행 수집 |
| `refreshStatusCells` | `(api, rowNodes) → void` | __row_status 컬럼 새로고침 |
| `hasChanges` | `(operations) → boolean` | insert/update/delete 존재 여부 |
| `numberOrNull` | `(value) → number|null` | 숫자 변환 |

### 3.2 GridCrudManager

단일 AG Grid의 CRUD 상태 추적/조작을 캡슐화하는 순수 JS 클래스.

**Config:**
```javascript
{
  pkFields: ["workpl_cd", "area_cd"],
  fields: { field_name: "trim|trimUpper|number|trimUpperDefault:Y" },
  defaultRow: { ... },
  blankCheckFields: ["code", "name"],
  comparableFields: ["name", "use_yn"],
  firstEditCol: "code",
  pkLabels: { code: "코드" }
}
```

**Public API:**
- `attach(api)` — 그리드 연결 + 이벤트 바인딩
- `detach()` — 이벤트 해제 + 정리
- `addRow(overrides)` — 새 행 추가
- `deleteRows({ beforeDelete })` — 선택 행 삭제
- `buildOperations()` — rowsToInsert/Update/Delete 분류
- `resetTracking()` — originalMap 재설정
- `stopEditing()` — 편집 중지

### 3.3 BaseGridController

단일 그리드 CRUD 패턴용 Stimulus 베이스 컨트롤러.

**서브클래스 훅:**
- `configureManager()` — GridCrudManager config 반환
- `buildNewRowOverrides()` — 새 행 기본값 오버라이드
- `beforeDeleteRows(selectedNodes)` — 삭제 전 검증
- `onCellValueChanged(event)` — 셀 값 변경 후 커스텀 처리
- `afterSaveSuccess()` — 저장 성공 후 커스텀 처리
- `saveMessage` — 저장 완료 메시지

## 4. 검증 방법

1. 각 컨트롤러 리팩토링 후 해당 화면에서 기능 테스트
2. `bin/rails test` 전체 테스트 통과
3. 브라우저 콘솔에서 JS 에러 없음 확인
4. 각 그리드 화면별 CRUD 전체 시나리오 수동 검증
