# PRD: 오더담당자관리 (ordOfcrMngt) - 완료

## 0. 기준 문서
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-AN13(화면정의서-V1.0)-오더담당자관리.pdf`
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-DS02(화면설계서-V1.0)-오더담당자관리.pdf`
- 프런트 공통 규칙: `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`

본 문서는 동일 화면명의 정의서/설계서를 묶어서 분석했고, 현재 Rails 8 + Hotwire + AG Grid 구조에 맞게 재정의했습니다.

## 1. User Flow
1. 사용자 메뉴 진입: `오더관리 > 오더담당자관리`.
2. Open 이벤트:
- `수출입내수구분` 코드(`OM_EXP_IMP_DOM_SCTN`)를 로딩한다.
- 조회조건 기본값은 `부서/고객/담당자 = 공백`, `수출입내수구분 = 전체`.
3. 조회조건 입력:
- `부서`, `고객`, `담당자`는 공통 팝업(검색)으로 선택하거나 코드 직접 입력.
- `수출입내수구분` 선택.
4. 조회 버튼 클릭:
- `GET /om/order_officers` (JSON) 호출.
- `use_yn = 'Y'` 데이터만 그리드 표시.
5. 그리드 편집:
- `추가`: 신규 행 추가(기본값 `exp_imp_dom_sctn_cd = DOMESTIC`, `use_yn = Y`).
- `삭제`: 선택 행을 삭제 대기 상태로 전환.
- `담당자` 선택 시 이름/연락처 자동 반영.
6. 저장 버튼 클릭:
- `POST /om/order_officers/batch_save`.
- Insert/Update/Delete(soft delete)를 단일 트랜잭션으로 처리.
7. 결과 처리:
- 성공 시 성공 메시지 + 목록 재조회.
- 실패 시 검증/저장 오류 메시지 노출.

## 2. UI Component List (Rails 8)
| 영역 | 컴포넌트 | 구현 방식 |
| --- | --- | --- |
| 화면 컨테이너 | `Om::OrderOfficer::PageComponent` | `resource_form + ag-grid` 조합 |
| 조회조건 폼 | `Ui::ResourceFormComponent` | `method: :get`, 4열 |
| 부서 선택 | popup field (`popup_type: "dept"`) | `search_popups#show` 공통 팝업 |
| 고객 선택 | popup field (`popup_type: "client"`) | `search_popups#show` 공통 팝업 |
| 담당자 선택 | popup field (`popup_type: "user"`) | `search_popups#show` + 연락처 반환 |
| 목록 그리드 | `Ui::AgGridComponent` | 인라인 편집 + 배치저장 |
| 그리드 툴바 | `Ui::GridToolbarComponent` | 추가/삭제/저장 |
| 그리드 액션 | `Ui::GridActionsComponent` | 컬럼/CSV 공통 액션 |
| Stimulus 컨트롤러 | `om-order-officer-grid` | `BaseGridController` 상속 |

## 3. Data Mapping
### 3.1 조회조건 파라미터 (`q`)
| 화면 필드 | 파라미터 | 타입 | DB 매핑 |
| --- | --- | --- | --- |
| 부서코드 | `q[dept_cd]` | String | `om_order_officers.ord_chrg_dept_cd` |
| 고객코드 | `q[cust_cd]` | String | `om_order_officers.cust_cd` |
| 수출입내수구분 | `q[exp_imp_dom_sctn_cd]` | String | `om_order_officers.exp_imp_dom_sctn_cd` |
| 담당자아이디 | `q[ofcr_cd]` | String | `om_order_officers.ofcr_cd` |

### 3.2 그리드 입력/출력 필드
| UI 필드 | DB 컬럼 | 타입 | 필수 | 비고 |
| --- | --- | --- | --- | --- |
| 오더담당부서코드 | `ord_chrg_dept_cd` | string(50) | Y | dept popup 코드 |
| 오더담당부서명 | `ord_chrg_dept_nm` | string(100) | N | 코드 기반 자동 보정 |
| 고객코드 | `cust_cd` | string(20) | Y | client popup 코드 |
| 고객명 | `cust_nm` | string(120) | N | 코드 기반 자동 보정 |
| 수출입내수구분 | `exp_imp_dom_sctn_cd` | string(30) | Y | EXPORT/IMPORT/DOMESTIC |
| 담당자아이디 | `ofcr_cd` | string(30) | Y | user popup 코드 |
| 담당자명 | `ofcr_nm` | string(100) | Y | user popup 이름 |
| 전화번호 | `tel_no` | string(30) | N | user 연락처 자동 반영 |
| 휴대전화번호 | `mbp_no` | string(30) | N | 시스템상 별도 모바일이 없으면 전화번호로 보정 |
| 사용여부 | `use_yn` | string(1) | Y | soft delete 시 `N` |
| 생성/수정 audit | `create_by/create_time/update_by/update_time` | audit | N | `Std::Auditable` |

### 3.3 유니크 키 / 인덱스
- 업무 유니크 인덱스: `(ord_chrg_dept_cd, cust_cd, exp_imp_dom_sctn_cd, ofcr_cd)`.
- 조회 인덱스: `ord_chrg_dept_cd`, `cust_cd`, `use_yn`.

## 4. Logic Definition
### 4.1 Open
- 수출입내수구분 코드 로딩.
- 조회조건 초기값 세팅.

### 4.2 팝업 선택 로직
- 부서/고객/담당자 코드 입력 또는 팝업 선택 가능.
- 그리드 lookup popup 선택 시:
  - 부서코드 변경 -> 부서명 초기화 후 재매핑.
  - 고객코드 변경 -> 고객명 초기화 후 재매핑.
  - 담당자아이디 변경 -> 담당자명/전화/휴대전화 초기화 후 재매핑.

### 4.3 조회
- 조건별 동적 필터:
  - `ord_chrg_dept_cd` 일치
  - `cust_cd` 일치
  - `exp_imp_dom_sctn_cd` 일치
  - `ofcr_cd` 일치
- 활성 데이터(`use_yn = 'Y'`)만 조회.

### 4.4 추가
- 신규 행 기본값:
  - `exp_imp_dom_sctn_cd = DOMESTIC`
  - `use_yn = Y`
- 필수값 미입력 행은 저장 시 제외.

### 4.5 삭제
- 물리 삭제가 아닌 soft delete:
  - `rowsToDelete` 대상에 `use_yn = 'N'` 업데이트.

### 4.6 저장
- 배치 요청 바디:
  - `rowsToInsert[]`, `rowsToUpdate[]`, `rowsToDelete[]`
- 서버 처리:
  - Insert: 신규 생성
  - Update: `id` 우선 수정, 누락 시 신규 upsert
  - Delete: `id` 기준 비활성화
- 오류 발생 시 전체 롤백.

## 5. 화면 정의
### 5.1 레이아웃
- 상단 조회조건: `resource_form` 사용.
- 하단 목록: `ag-grid` 사용.
- 우측 툴바: `추가 / 삭제 / 저장`.

### 5.2 조회조건
- `부서(팝업)`, `고객(팝업)`, `수출입내수구분(select)`, `담당자(팝업)`.

### 5.3 그리드 컬럼
- 상태, 오더담당부서코드/명, 고객코드/명, 수출입내수구분, 담당자아이디/명, 전화번호, 휴대전화번호, 수정자, 수정일시.

### 5.4 Stimulus 규약 반영
- `BaseGridController` 기반 배치 CRUD.
- 이벤트/타겟/action 네이밍은 `STIMULUS_COMPONENTS_GUIDE` 규칙 준수.
- `ag-grid:lookup-selected` 이벤트로 담당자 부가정보(연락처) 후처리.

## 6. 우리 시스템 맞춤 설계
- 원문 설계의 `담당자선택(EmpSlcPopup)`은 현재 시스템의 `search_popups/:type=user`로 통합.
- 사용자 마스터(`adm_users`)에는 단일 연락처(`phone`) 구조이므로:
  - `tel_no` 우선 매핑
  - `mbp_no`는 별도 모바일 정보 부재 시 동일 값으로 보정 가능
- 기존 공통코드 체계와 일치하도록 수출입내수구분은 `OM_EXP_IMP_DOM_SCTN` 사용.

## 7. 메뉴/권한
### 7.1 메뉴 생성
- `menu_cd: OM_ORD_OFCR`
- `menu_nm: 오더담당자관리`
- `menu_url: /om/order_officers`
- `tab_id: om-order-officers`
- 부모 `OM`(오더관리) 폴더 없으면 자동 생성.

### 7.2 사용자별 메뉴 권한 생성
- `adm_users` 전체 사용자 대상 `adm_user_menu_permissions` upsert.
- 기본값 `use_yn = 'Y'`.

## 8. 구현 산출물
- 라우트: `om/order_officers#index`, `batch_save`.
- 백엔드:
  - `Om::OrderOfficersController`
  - `OmOrderOfficer`
  - `Om::OrderOfficerSearchForm`
- 프런트:
  - `Om::OrderOfficer::PageComponent`
  - `om_order_officer_grid_controller.js`
- 마이그레이션:
  - `ensure_om_order_officers_schema`
  - `add_om_order_officer_menu_and_permissions`
