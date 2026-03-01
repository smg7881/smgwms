# Detail Grid 자동 등록 설계서

## 1. 목적
- `detailGridConfigs()`의 반복 구현을 줄이고, `configureManager()`/`configureDetailManager()`에 등록 메타데이터를 선언하면 자동으로 상세 그리드 등록 설정이 구성되도록 설계한다.
- 본 문서는 설계안만 포함하며, 실제 소스 수정은 범위에서 제외한다.

## 2. 대상 파일
- `app/javascript/controllers/base_grid_controller.js`
- `app/javascript/controllers/master_detail_grid_controller.js`
- `app/javascript/controllers/code_grid_controller.js` (적용 예시)

## 3. 현재 구조와 문제점
- `MasterDetailGridController` 하위 컨트롤러마다 `detailGridConfigs()`를 수동 구현하고 있다.
- 동일한 키(`target`, `controllerKey`, `managerKey`, `configMethod`)가 화면별로 반복된다.
- `configureDetailManager()`가 이미 존재해도 등록 설정을 별도로 작성해야 하므로 누락/오타 가능성이 있다.
- 다중 상세 그리드 화면에서 보일러플레이트가 커진다.

## 4. 설계 원칙
- 기존 동작 호환 우선: 기존 `detailGridConfigs()` 오버라이드 방식은 계속 지원한다.
- 선언 위치 단일화: CRUD 규칙과 등록 메타데이터를 같은 `configure*Manager` 반환 객체에 둔다.
- 점진 적용: 기존 화면은 즉시 변경하지 않고, 신규/수정 화면부터 적용 가능해야 한다.

## 5. 제안 API

### 5.1 Manager 설정 객체 확장
`configureManager()`/`configureDetailManager()` 반환 객체에 `registration` 블록을 추가한다.

```javascript
configureDetailManager() {
  return {
    pkFields: ["detail_code"],
    fields: { ... },
    defaultRow: { ... },
    blankCheckFields: [...],
    comparableFields: [...],
    firstEditCol: "detail_code",
    pkLabels: { detail_code: "상세코드" },
    registration: {
      targetName: "detailGrid",
      controllerKey: "detailGridController",
      managerKey: "detailManager"
    }
  }
}
```

### 5.2 자동 상세 등록 규칙
- `MasterDetailGridController`는 `configure*Manager` 메서드 중 `configureManager`(마스터) 제외 대상을 스캔한다.
- 각 메서드 반환값의 `registration`을 읽어 `detailGridConfigs()` 기본값을 자동 생성한다.
- 자동 생성 시 `configMethod`는 스캔된 메서드명으로 채운다.

생성 결과 예시:

```javascript
[
  {
    target: this.hasDetailGridTarget ? this.detailGridTarget : null,
    controllerKey: "detailGridController",
    managerKey: "detailManager",
    configMethod: "configureDetailManager"
  }
]
```

## 6. 파일별 변경 설계

### 6.1 `base_grid_controller.js`
- 신규 유틸 메서드 설계:
  - `splitManagerConfig(rawConfig)`:
    - 입력: `configure*Manager()` 원본 객체
    - 출력: `{ managerConfig, registration }`
    - `managerConfig`에는 `registration`을 제외한 CRUD 설정만 남긴다.
- 목적:
  - `GridCrudManager`에 불필요한 메타 필드를 주입하지 않도록 경계를 명확히 한다.

### 6.2 `master_detail_grid_controller.js`
- `detailGridConfigs()` 기본 구현을 자동 생성 방식으로 변경:
  - `this.autoDetailGridConfigs()` 호출
  - 하위 클래스가 오버라이드하면 기존 오버라이드 우선
- 신규 보조 메서드 설계:
  - `detailManagerMethods()`:
    - 인스턴스 메서드에서 `configure*Manager` 패턴 수집 (`configureManager` 제외)
  - `autoDetailGridConfigs()`:
    - 각 메서드 실행 -> `splitManagerConfig`로 `registration` 추출
    - `targetName`으로 `hasXTarget`/`xTarget`를 동적으로 resolve
    - `registerGridInstance` 형식의 config 배열 반환

### 6.3 `code_grid_controller.js` (적용 예시)
- `configureManager()`:
  - 필요 시 마스터 등록 메타를 동일 포맷으로 선언 가능 (선택)
- `configureDetailManager()`:
  - `registration` 추가 (targetName/controllerKey/managerKey)
- `detailGridConfigs()`:
  - 자동 생성으로 대체 가능하므로 제거 대상
  - 단, 1차 적용 시에는 안전하게 유지 후 동작 검증 뒤 제거하는 단계적 전환 권장

## 7. 호환성 정책
- 기존 수동 `detailGridConfigs()`가 있으면 그대로 동작.
- `registration`이 없는 `configureDetailManager()`는 자동 등록 대상에서 제외.
- 읽기 전용 상세 그리드(`controllerKey`만 필요, `managerKey` 없음)는 수동 `detailGridConfigs()` 또는 별도 `manualDetailGridConfigs()` 훅으로 유지.

## 8. 전환 전략
1. 공통부(`base_grid_controller`, `master_detail_grid_controller`)에 자동 생성 로직 추가
2. `code_grid_controller`에 `registration` 메타 선언 추가
3. `code_grid_controller`의 기존 `detailGridConfigs()` 제거 또는 Deprecated 처리
4. 타 화면(`client`, `purchase_contract`, `sell_contract` 등) 순차 전환

## 9. 검증 계획
- 단일 상세 그리드 화면:
  - 초기 로딩 시 상세 manager attach 확인
  - 마스터 행 변경 시 상세 조회/초기화 정상 동작 확인
- 다중 상세 그리드 화면:
  - 각 상세 manager/controllerKey 매핑 정확성 확인
- 회귀 확인:
  - 기존 수동 `detailGridConfigs()` 화면 동작 영향 없음 확인
  - `onAllReady` 시점이 기존과 동일한지 확인

## 10. 리스크와 대응
- 리스크: 메서드 스캔 기반 자동화 시 의도치 않은 `configure*Manager`가 포함될 수 있음  
  대응: `registration` 존재 여부를 필수 조건으로 제한
- 리스크: target 이름 오타(`targetName`)  
  대응: `hasXTarget` 미존재 시 경고 로그 + 해당 config skip
- 리스크: 읽기 전용 detail grid 자동화 범위 혼선  
  대응: CRUD manager 필요 없는 상세 그리드는 수동 설정 유지 정책 명시

## 11. 결정 사항
- 핵심 결정: 상세 등록의 소스 오브 트루스를 `configure*Manager()`로 통합한다.
- 유지 결정: 복잡한 예외 화면을 위해 수동 `detailGridConfigs()` 확장 포인트는 유지한다.
