# client_grid_controller 공통화/정리 계획서

## 1. 목적
- 대상 파일: `app/javascript/controllers/client_grid_controller.js` (약 832 lines)
- 목표: 탭(담당자/작업장) 중심의 중복 로직을 공통화해 유지보수 비용과 변경 리스크를 낮춘다.
- 제약: 본 계획 단계에서는 **소스 수정 없이 설계/작업 순서만 정의**한다.

## 2. 현재 구조 요약
- 마스터 거래처 + 상세 폼 + 탭 2개(담당자/작업장) CRUD를 단일 컨트롤러가 모두 담당.
- 화면 동작은 안정적이지만, 동일 패턴이 메서드 단위로 반복되어 코드량이 커짐.
- 특히 탭별 CRUD/조회/초기화 흐름이 거의 대칭 구조로 존재.

## 3. 공통화 후보 (핵심)

### 3.1 탭별 CRUD 액션 중복
- 구간: `L354-L426` (`add/delete/save` Contact/Workplace 각각 존재)
- 중복 패턴:
  - `manager 존재 체크`
  - `마스터 변경 여부 체크`
  - `selectedClientValue 체크`
  - `batchUrl 생성 + saveRowsWith 호출`
- 제안:
  - `runDetailAction(tabKey, action)` 공통 가드
  - `saveDetailRows(tabKey)` 공통 저장 진입점

### 3.2 탭별 조회/초기화 중복
- 구간: `L428-L468`, `L471-L473`
- 중복 패턴:
  - `isApiAlive` 체크
  - 코드 없으면 clear
  - URL template + fetchJson + setManagerRowData
- 제안:
  - `loadDetailRows(tabKey, clientCode)`
  - `clearDetailRows(tabKey)`
  - `clearAllDetails()`는 tab registry 순회 방식으로 단순화

### 3.3 탭 설정 객체 중복
- 구간: `L221-L282` (`configureContactManager`, `configureWorkplaceManager`)
- 중복 패턴:
  - 동일 키 구조(`pkFields`, `fields`, `defaultRow`, `registration` 등)
- 제안:
  - `buildDetailManagerConfig(definition)` 팩토리 도입
  - Contact/Workplace는 `definition` 데이터만 유지

### 3.4 폼 정규화 로직 분산
- 구간: `L597-L627`, `L815-L824`
- 이슈:
  - 상세 입력 정규화와 마스터 셀 정규화 규칙이 분산되어 동기화 리스크 존재
- 제안:
  - `field_normalizers.js`로 규칙 테이블화
  - 상세/마스터가 같은 정규화 함수 세트를 재사용

### 3.5 팝업 필드 처리 결합도
- 구간: `L732-L813`
- 이슈:
  - 팝업 DOM 접근, display/code 동기화, 금융기관명 조회/캐시가 한 덩어리
- 제안:
  - `popup_field_sync.js` 분리
  - 컨트롤러는 orchestration만 담당

## 4. 목표 구조(안)
```text
app/javascript/controllers/client_grid/
  detail_tab_registry.js        # 탭 메타(contacts/workplaces)
  detail_tab_actions.js         # 공통 CRUD/조회/초기화
  detail_manager_factory.js     # configure*Manager 공통 빌더
  field_normalizers.js          # 상세/마스터 정규화 규칙
  popup_field_sync.js           # search-popup 연동/표시/캐시
```

## 5. 단계별 실행 계획

### Phase 0. 안전장치 확보
- 현재 동작 기준선 확인:
  - 거래처 선택 -> 담당자/작업장 자동 조회
  - 상세 입력 동기화
  - 각 탭 CRUD 저장
- 스모크 체크리스트 문서화(수동 테스트 케이스).

### Phase 1. 탭 메타데이터 도입
- `detail_tab_registry`에 탭별 차이만 데이터로 선언:
  - managerKey, controllerKey, listUrlTemplateValueKey, batchUrlTemplateValueKey
  - 메시지(조회 실패/저장 성공), 그리드 targetName
- 기존 메서드는 유지하되 내부에서 registry 조회 방식으로 전환.

### Phase 2. CRUD/조회 공통 함수 추출
- 공통 함수:
  - `ensureDetailActionAllowed(tabKey)`
  - `loadDetailRows(tabKey, clientCode)`
  - `saveDetailRows(tabKey)`
  - `addDetailRow(tabKey)`, `deleteDetailRows(tabKey)`, `clearDetailRows(tabKey)`
- 기존 public 액션(`addContactRow` 등)은 래퍼만 남겨 HTML `data-action` 호환성 유지.

### Phase 3. Manager 설정 빌더 공통화
- `configureContactManager`/`configureWorkplaceManager`를 definition 기반으로 재구성.
- 타입/규칙 변경은 definition에서만 수행하도록 변경 포인트 단일화.

### Phase 4. 정규화/팝업 로직 모듈화
- `field_normalizers`로 `normalizeDetailFieldValue`, `normalizeMasterField` 규칙 통합.
- `popup_field_sync`로 DOM 처리와 이름 해석(caching/fetch) 분리.
- 컨트롤러는 이벤트 연결과 상태만 보유.

### Phase 5. 마무리 정리
- 불필요 헬퍼 제거, 메서드 순서 재정렬(읽기 흐름 최적화).
- 주석 정리(동작 설명 중심, 중복 설명 제거).

## 6. 우선순위
1. 탭 CRUD/조회 공통화 (효과 대비 리스크 낮음)
2. Manager 설정 빌더 공통화
3. 정규화 규칙 통합
4. 팝업 연동 모듈화

## 7. 기대 효과
- 컨트롤러 라인 수 20~35% 감소(탭 대칭 코드 축소 기준).
- 탭 추가 시 변경 파일/변경 지점 최소화(메타 등록 중심).
- 버그 수정 시 Contact/Workplace 동시 반영 누락 위험 감소.

## 8. 리스크 및 대응
- 리스크: 공통화 과정에서 탭별 예외 동작이 묻힐 수 있음.
  - 대응: registry에 `hooks` 슬롯(`beforeSave`, `afterLoad`) 확보.
- 리스크: 기존 `data-action` 메서드명 변경 시 뷰 연동 깨짐.
  - 대응: 기존 public 메서드명 유지, 내부 구현만 위임.
- 리스크: 정규화 통합 시 기존 입력 포맷 차이 이슈.
  - 대응: 필드별 회귀 케이스(`bizman_no`, 코드필드, 날짜필드) 우선 검증.

## 9. 완료 기준 (Definition of Done)
- `client_grid_controller.js`에서 Contact/Workplace 대칭 코드가 공통 함수로 치환됨.
- 탭 신규 1개를 registry 확장만으로 붙일 수 있는 구조 확인.
- 기존 사용자 시나리오(조회/추가/수정/삭제/저장/탭전환) 회귀 이상 없음.
- 관련 계획/체크리스트 문서가 `doc/`에 최신화됨.
