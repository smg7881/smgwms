# PRD: 고객별시스템설정관리 (OM-CUST-SYS-CONF) - 완료

## 0. 기준 문서
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-AN13(화면정의서-V1.0)-고객별시스템설정관리.pdf`
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-DS02(화면설계서-V1.0)-고객별시스템설정관리.pdf`
- 프런트 규칙 참조: `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md`

## 1. User Flow
1. 사용자 메뉴 진입: `오더관리 > 고객별시스템설정관리`.
2. 화면 Open 시 코드 메타 로드:
- 설정단위(`OM_SETUP_UNIT`)
- 대/중/소분류(`OM_SETUP_LCLAS`, `OM_SETUP_MCLAS`, `OM_SETUP_SCLAS`)
- 설정구분(`OM_SETUP_SCTN`)
- 사용여부(`CMM_USE_YN`)
3. 조회조건 입력:
- 조회조건 폼은 `resource_form` 기반(GET submit)
- 고객은 공통 팝업(`search_popup type=client`)으로 선택
4. 조회 버튼 클릭:
- JSON API(`/om/customer_system_configs.json`)로 AG Grid 데이터 로드
5. 편집:
- 행추가/수정/삭제(soft delete) 후 변경상태(`C/U/D`) 추적
6. 저장:
- 배치 저장 API(`/om/customer_system_configs/batch_save`) 호출
- 성공 시 그리드 재조회 및 상태 리셋

## 2. UI Component List (Rails 8 기준)
| 영역 | 컴포넌트 | 구현 |
| --- | --- | --- |
| 검색영역 | `Ui::ResourceFormComponent` | 조회조건 입력, `method: :get`, `submit_label: 조회` |
| 고객선택 | `search-popup` Stimulus + popup field | 코드/명칭 동시 바인딩 |
| 목록영역 | `Ui::AgGridComponent` | 편집형 그리드, 멀티선택, 상태컬럼 |
| 툴바 | `Ui::GridToolbarComponent` | 추가/삭제/저장 |
| 액션저장 | `om-customer-system-config-grid` Stimulus | `BaseGridController` 상속, 배치 CRUD |

## 3. Data Mapping (입력필드 ↔ DB 메타)
### 3.1 검색 파라미터(`q`)
| 화면 필드 | 파라미터 | 타입 | 설명 |
| --- | --- | --- | --- |
| 설정단위 | `q[setup_unit_cd]` | String | SYSTEM/CUSTOMER |
| 고객코드 | `q[cust_cd]` | String | popup hidden code |
| 대분류 | `q[lclas_cd]` | String | 코드 |
| 설정구분 | `q[setup_sctn_cd]` | String | 코드 |
| 모듈명/항목명 | `q[module_nm]` | String | LIKE 검색 |
| 사용여부 | `q[use_yn]` | String | Y/N |

### 3.2 저장 테이블(`om_customer_system_configs`)
| 컬럼 | 타입 | NULL | 규칙 |
| --- | --- | --- | --- |
| `id` | PK | N | 자동 |
| `setup_unit_cd` | string(30) | N | SYSTEM/CUSTOMER |
| `cust_cd` | string(20) | N | SYSTEM일 때 `''`, CUSTOMER일 때 필수 |
| `lclas_cd` | string(50) | N | 대분류 코드 |
| `mclas_cd` | string(50) | N | 중분류 코드 |
| `sclas_cd` | string(50) | N | 소분류 코드 |
| `setup_sctn_cd` | string(50) | N | 설정구분 코드 |
| `module_nm` | string(150) | Y | 모듈/항목 표시명 |
| `setup_value` | string(200) | Y | 설정값(Y/N/문자) |
| `use_yn` | string(1) | N | Y/N, 삭제 시 N |
| `create_by/create_time` | audit | Y | 생성 audit |
| `update_by/update_time` | audit | Y | 수정 audit |

### 3.3 유니크 키
- `(setup_unit_cd, cust_cd, lclas_cd, mclas_cd, sclas_cd, setup_sctn_cd)` unique

## 4. Logic Definition (버튼/이벤트)
### 4.1 Open
- 코드 테이블 로딩 및 기본값 세팅
- 기본 조회조건:
  - `setup_unit_cd = SYSTEM`
  - `use_yn = Y`

### 4.2 조회(`조회` 버튼)
- `resource_form submit(GET)` 발생
- 컨트롤러에서 `q` 파라미터 기반 필터 적용
- 결과를 AG Grid JSON으로 반환

### 4.3 추가(`추가` 버튼)
- 신규 행 생성, 기본값:
  - `setup_unit_cd = SYSTEM`
  - `setup_sctn_cd = VALIDATE`
  - `use_yn = Y`

### 4.4 삭제(`삭제` 버튼)
- 선택행에 대해 soft delete 마킹
- 저장 시 `use_yn='N'` 업데이트

### 4.5 저장(`저장` 버튼)
- 변경분(`rowsToInsert/rowsToUpdate/rowsToDelete`)만 전송
- 서버 검증:
  - CUSTOMER 설정단위 + 고객코드 누락 금지
  - 필수 코드 필드 누락 금지
  - 유니크 키 중복 금지
- 성공 응답 후 그리드 새로고침

## 5. 화면 정의 (우리 시스템 맞춤)
### 5.1 레이아웃
- 상단: `resource_form` 조회영역
- 하단: `ag-grid` 편집 목록
- 그리드 상단 우측: `추가/삭제/저장`

### 5.2 컬럼
- 상태, 설정단위, 고객코드, 고객명, 대분류, 중분류, 소분류, 설정구분, 모듈명, 설정값, 사용여부, 수정자, 수정일시

### 5.3 공통규칙 반영
- Stimulus 이벤트/타겟 네이밍은 `STIMULUS_COMPONENTS_GUIDE` 규칙 준수
- 배치저장은 `BaseGridController + GridCrudManager` 표준 패턴 사용
- 조회조건은 사용자 요청대로 `resource_form` 사용

## 6. 메뉴/권한 정의
### 6.1 메뉴
- 루트 폴더: `OM`(오더관리) 자동 생성/보정
- 화면 메뉴:
  - `menu_cd: OM_CUST_SYS_CONF`
  - `menu_url: /om/customer_system_configs`
  - `tab_id: om-customer-system-configs`

### 6.2 사용자별 메뉴권한
- 마이그레이션에서 `adm_users` 전체 대상 `adm_user_menu_permissions` upsert
- 기본값 `use_yn = Y`

## 7. 구현 산출물
- 라우트: `namespace :om` + `customer_system_configs#index`, `batch_save`
- 백엔드: `Om::CustomerSystemConfigsController`, `OmCustomerSystemConfig`
- 프런트: `Om::CustomerSystemConfig::PageComponent`, `om_customer_system_config_grid_controller.js`
- DB:
  - `create_om_customer_system_configs`
  - `seed_om_customer_system_config_codes`
  - `add_om_customer_system_config_menu_and_permissions`

## 8. Merge Rule (SYSTEM + CUSTOMER Override)
1. If search is `setup_unit_cd=CUSTOMER` and `cust_cd` is provided, execute merge mode.
2. Merge key: `(lclas_cd, mclas_cd, sclas_cd, setup_sctn_cd)`.
3. Build virtual CUSTOMER rows from SYSTEM defaults first (`from_system_default=true`), then override with existing CUSTOMER rows on the same key.
4. Editing a virtual row and saving uses key-based upsert in `rowsToUpdate` so a real CUSTOMER row is created.
5. Delete uses key-based soft delete (`use_yn='N'`).
