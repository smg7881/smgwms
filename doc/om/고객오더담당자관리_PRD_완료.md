# PRD: 고객오더담당자관리 (OM-CUST-ORD-OFCR) - 완료

## 0. 기준 문서
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-AN13(화면정의서-V1.0)-고객오더담당자관리.pdf`
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-DS02(화면설계서-V1.0)-고객오더담당자관리.pdf`
- 프런트 공통 규칙 참조: `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md`

## 1. User Flow
1. 사용자 메뉴 진입: `오더관리 > 고객오더담당자관리`.
2. Open 이벤트:
- 수출입내수구분 조회조건 기본값을 `전체`로 초기화한다.
- 수출입내수구분 콤보를 공통코드(`OM_EXP_IMP_DOM_SCTN`)로 로딩한다.
3. 조회조건 입력:
- 부서(코드/명) 선택: `dept` 팝업 사용.
- 고객(코드/명) 선택: `client` 팝업 사용.
- 수출입내수구분 선택.
- 담당자명 입력.
4. 조회 버튼 클릭:
- `GET /om/customer_order_officers` (json)으로 목록 조회.
- 목록은 `use_yn = 'Y'` 데이터만 표시.
5. 목록 편집:
- `추가`: 신규 행 생성(기본 수출입내수구분 `DOMESTIC`, 사용여부 `Y`).
- `삭제`: 선택 행을 삭제대기로 표시.
- 셀 편집: 부서/고객 코드는 lookup popup으로 코드-명 동기화.
6. 저장 버튼 클릭:
- `POST /om/customer_order_officers/batch_save`.
- Insert/Update/Delete(soft delete)를 일괄 처리.
7. 저장 결과:
- 성공 메시지 표시 후 목록 재조회.
- 실패 시 검증 오류 메시지 반환.

## 2. UI Component List (Rails 8 기반)
| 영역 | 컴포넌트 | 구현 방식 |
| --- | --- | --- |
| 조회조건 | `Ui::ResourceFormComponent` | `method: :get`, 4열, 조회 버튼 |
| 부서 선택 | popup field (`popup_type: "dept"`) | `search_popups#show` 공통 팝업 |
| 고객 선택 | popup field (`popup_type: "client"`) | `search_popups#show` 공통 팝업 |
| 목록 | `Ui::AgGridComponent` | 인라인 편집 + 배치 저장 |
| 그리드 툴바 | `Ui::GridToolbarComponent` | 추가/삭제/저장 |
| 그리드 액션 | `Ui::GridActionsComponent` | 컬럼상태/CSV 등 공통 액션 |
| 화면 컨테이너 | `Om::CustomerOrderOfficer::PageComponent` | `resource_form + ag-grid` 결합 |
| JS 컨트롤러 | `om-customer-order-officer-grid` | `BaseGridController` 상속 |

## 3. Data Mapping
### 3.1 조회조건 파라미터 (`q`)
| 화면 필드 | 파라미터 | 타입 | DB 매핑 |
| --- | --- | --- | --- |
| 부서코드 | `q[dept_cd]` | String | `om_customer_order_officers.ord_chrg_dept_cd` |
| 고객코드 | `q[cust_cd]` | String | `om_customer_order_officers.cust_cd` |
| 수출입내수구분 | `q[exp_imp_dom_sctn_cd]` | String | `om_customer_order_officers.exp_imp_dom_sctn_cd` |
| 담당자명 | `q[cust_ofcr_nm]` | String | `om_customer_order_officers.cust_ofcr_nm (LIKE)` |

### 3.2 목록/저장 필드 ↔ DB 메타데이터
| UI 필드 | DB 컬럼 | 타입 | 필수 | 비고 |
| --- | --- | --- | --- | --- |
| 오더담당부서코드 | `ord_chrg_dept_cd` | string(50) | Y | dept popup 코드 |
| 오더담당부서명 | `ord_chrg_dept_nm` | string(100) | N | 코드 기준 자동 보정 |
| 고객코드 | `cust_cd` | string(20) | Y | client popup 코드 |
| 고객명 | `cust_nm` | string(120) | N | 코드 기준 자동 보정 |
| 수출입내수구분 | `exp_imp_dom_sctn_cd` | string(30) | Y | `EXPORT/IMPORT/DOMESTIC` |
| 고객담당자명 | `cust_ofcr_nm` | string(100) | Y | |
| 고객담당자전화번호 | `cust_ofcr_tel_no` | string(30) | Y | |
| 고객담당자휴대전화번호 | `cust_ofcr_mbp_no` | string(30) | N | 선택 저장 |
| 사용여부 | `use_yn` | string(1) | Y | soft delete 시 `N` |
| 생성자/생성일시 | `create_by/create_time` | audit | N | `Std::Auditable` |
| 수정자/수정일시 | `update_by/update_time` | audit | N | `Std::Auditable` |

### 3.3 유니크 키
- 비즈니스 유니크 인덱스: `(ord_chrg_dept_cd, cust_cd, exp_imp_dom_sctn_cd, cust_ofcr_nm)`.

## 4. Logic Definition
### 4.1 Open
- 수출입내수구분 콤보를 공통코드에서 조회한다.
- 조회조건 수출입내수구분은 `전체("")`로 시작한다.

### 4.2 부서선택/고객선택
- 검색영역:
- 코드 직접 입력 또는 팝업 선택.
- 선택 시 코드/명이 함께 반영된다.
- 그리드영역:
- lookup popup으로 코드 선택 가능.
- 코드 변경 시 기존 명칭 컬럼은 빈값으로 초기화 후 저장/조회 시 보정.

### 4.3 조회
- 조건별 필터:
- 부서코드 일치.
- 고객코드 일치.
- 수출입내수구분 일치.
- 담당자명 부분일치.
- 조회결과는 활성행(`use_yn='Y'`)만 노출한다.

### 4.4 추가
- 신규 행 기본값:
- `exp_imp_dom_sctn_cd = DOMESTIC`
- `use_yn = Y`
- 필수값 검증 후 저장대상(`rowsToInsert`)으로 전송.

### 4.5 삭제
- 물리삭제가 아닌 soft delete:
- `rowsToDelete` 대상 행 `use_yn = 'N'` 업데이트.

### 4.6 저장
- 배치 요청 본문:
- `rowsToInsert[]`, `rowsToUpdate[]`, `rowsToDelete[]`.
- 서버 처리:
- Insert: 신규 생성.
- Update: `id` 기준 갱신, 누락 시 upsert 생성.
- Delete: `id` 기준 비활성화.
- 오류가 하나라도 있으면 전체 롤백.

## 5. 화면 정의 (우리 시스템 맞춤)
### 5.1 화면 구조
- 상단 조회조건: `resource_form` 사용.
- 하단 목록: `ag-grid` 사용.
- 우측 툴바: 추가/삭제/저장.

### 5.2 조회조건
- 부서(팝업), 고객(팝업), 수출입내수구분(select), 담당자(input).

### 5.3 목록 컬럼
- 상태, 오더담당부서코드/명, 고객코드/명, 수출입내수구분, 고객담당자명, 고객담당자전화번호, 수정자, 수정일시.

### 5.4 공통 프런트 규약 반영
- `BaseGridController` 기반 배치 CRUD.
- `resource_form_controller`, `ag_grid_controller`, lookup popup 이벤트 체계를 유지.
- 이벤트/target/data-attribute 구조는 Stimulus 가이드 규약을 따름.

## 6. 메뉴 및 사용자별 메뉴권한
### 6.1 메뉴 생성
- 부모 폴더 보정: `OM`(오더관리) 없으면 자동 생성.
- 신규 메뉴:
- `menu_cd: OM_CUST_ORD_OFCR`
- `menu_nm: 고객오더담당자관리`
- `menu_url: /om/customer_order_officers`
- `tab_id: om-customer-order-officers`

### 6.2 사용자별 메뉴권한 생성
- `adm_users` 전 사용자 대상 `adm_user_menu_permissions` upsert.
- 기본값 `use_yn = 'Y'`.

## 7. 구현 산출물
- 라우트: `om/customer_order_officers#index`, `batch_save`.
- 백엔드:
- `Om::CustomerOrderOfficersController`
- `OmCustomerOrderOfficer`
- `Om::CustomerOrderOfficerSearchForm`
- 프런트:
- `Om::CustomerOrderOfficer::PageComponent`
- `om_customer_order_officer_grid_controller.js`
- 마이그레이션:
- `ensure_om_customer_order_officers_schema`
- `seed_om_customer_order_officer_codes`
- `add_om_customer_order_officer_menu_and_permissions`
