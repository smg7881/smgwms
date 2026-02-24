# 사전오더접수오류관리 PRD (완료)

## 1. 문서 개요
- 대상 화면: `befOrdRecpErrMngt` (사전오더접수오류관리)
- 분석 원본:
  - `D:\_LOGIS\2.오더\pdf\LogisT-OM-AN13(화면정의서-V1.0)-사전오더접수오류관리.pdf`
  - `D:\_LOGIS\2.오더\pdf\LogisT-OM-DS02(화면설계서-V1.0)-사전오더접수오류관리.pdf`
- 우리 시스템 반영 원칙:
  - 조회조건은 `resource_form` 기반
  - 목록/상세는 `ag-grid` 기반
  - 기존 OM 테이블(`om_pre_order_errors`, `om_pre_order_receptions`, `om_orders`) 재사용
  - 권한체계는 `AdmUserMenuPermission` + `Om::BaseController` 패턴 준수

## 2. User Flow
1. 사용자가 OM > 사전오더접수오류관리 메뉴 진입
2. 기본 조회조건(접수 시작일/종료일)으로 오류 목록 조회
3. 필요 시 고객 팝업, 고객오더번호, 처리여부로 필터 후 재조회
4. 목록에서 오류 건 선택 시 하단 상세(라인별 메시지/수량) 자동 조회
5. 사용자는 다음 중 하나 수행
   - 재처리: 선택 오류건 기반으로 오더 생성 재시도
   - 양식다운로드: 업로드 양식 파일 다운로드
   - 오류업로드: CSV 업로드로 오류 데이터 등록
6. 재처리 성공 시
   - `om_orders` 신규 생성
   - `om_pre_order_receptions.status_cd` 갱신
   - `om_pre_order_errors.resolved_yn/use_yn` 갱신
   - 화면에서 재조회 시 대상 건 제외

## 3. UI Component List (Rails 8)
- 페이지 컴포넌트
  - `Om::PreOrderReceptionError::PageComponent`
  - `index.html.erb`에서 Turbo Frame 렌더
- 조회영역
  - `Ui::ResourceFormComponent`
  - 필드: 고객(팝업), 고객오더번호, 처리여부, 접수 시작일, 접수 종료일
- 목록영역
  - `Ui::GridToolbarComponent` (재처리/양식다운로드/오류업로드)
  - `Ui::AgGridComponent` (오류 목록)
  - `Ui::GridActionsComponent` (컬럼 상태 저장/초기화 등 공통)
- 상세영역
  - `Ui::AgGridComponent` (오류 상세 라인)
- Stimulus
  - `om-pre-order-reception-error` 컨트롤러
  - 마스터 선택 변경 -> 상세 재조회
  - 재처리/다운로드/업로드 액션 처리
- 검색 팝업
  - `search-popup` 컨트롤러 (`popup_type: client`)

## 4. Data Mapping

### 4.1 조회조건 매핑
| 화면 필드 | 파라미터 | DB 매핑 | 비고 |
| --- | --- | --- | --- |
| 고객코드/고객명 | `q[cust_cd]`/`q[cust_nm]` | `om_pre_order_receptions.cust_cd` | 팝업 선택 |
| 고객오더번호 | `q[cust_ord_no]` | `om_pre_order_errors.cust_ord_no` | 부분검색 |
| 처리여부 | `q[resolved_yn]` | `om_pre_order_errors.resolved_yn` | `N/Y` |
| 접수 시작일 | `q[recp_start_ymd]` | `om_pre_order_errors.create_time >=` | 필수 |
| 접수 종료일 | `q[recp_end_ymd]` | `om_pre_order_errors.create_time <=` | 필수 |

### 4.2 목록/상세 매핑
| 화면 컬럼 | 소스 필드 | 매핑 규칙 |
| --- | --- | --- |
| 접수순번(`recp_seq`) | 서버 계산 | 조회 결과 순번 |
| 구분(`sctn_cd`) | `om_pre_order_errors.err_type_cd` | 코드값 노출 |
| 메시지코드(`msg_cd`) | `om_pre_order_errors.err_type_cd` | 현행 시스템 대체 매핑 |
| 메시지(`err_msg`) | `om_pre_order_errors.err_msg` | 오류 원문 |
| 고객오더번호 | `om_pre_order_errors.cust_ord_no` | - |
| 고객코드/고객명 | `om_pre_order_receptions.cust_cd/cust_nm` | `cust_ord_no` 조인 |
| 접수일자 | `om_pre_order_errors.create_time` | `YYYY-MM-DD` |
| 품목코드 | `om_pre_order_errors.item_cd` | - |
| 수량/중량/부피 | `om_pre_order_receptions.qty/wgt/vol` | `cust_ord_no + item_cd` 기준 |
| 생성오더번호 | `om_orders.ord_no` | `cust_ord_no` 기준 최신 1건 |
| 처리여부 | `om_pre_order_errors.resolved_yn` | `N/Y` |
| 상세 라인번호 | `om_pre_order_errors.line_no` | 정렬키 |

## 5. Logic Definition

### 5.1 Open
- 기본값 설정:
  - 접수 시작일/종료일 = 당일
  - 처리여부 = 미처리(`N`)

### 5.2 조회 버튼
- 검증:
  - 시작일/종료일 필수
  - 종료일 < 시작일이면 서버에서 자동 스왑
- 처리:
  - `om_pre_order_errors` 기본 조회(`use_yn = 'Y'`)
  - 조건 필터 적용
  - `om_pre_order_receptions`, `om_orders` 조인 데이터 보강

### 5.3 목록 선택
- 이벤트: 마스터 그리드 `selectionChanged`
- 처리:
  - 선택건의 `error_id` 전달
  - 동일 주문 기준 상세 라인 재조회
  - 하단 상세 그리드 갱신

### 5.4 재처리 버튼
- 입력: 선택 오류 ID 배열
- 처리:
  - 선택건별 사전오더 데이터(`om_pre_order_receptions`) 확인
  - 이미 생성된 오더 존재 시 스킵
  - 미생성 건은 `om_orders` 생성
  - 성공 시:
    - `om_pre_order_receptions.status_cd = ORDER_CREATED`
    - 연관 오류 `resolved_yn = 'Y'`, `use_yn = 'N'`
- 출력: 생성/스킵/실패 건수 메시지

### 5.5 양식다운로드 버튼
- 처리: 서버에서 템플릿 CSV(`OM_beforeORDERErrorRegister.csv`) `send_data`

### 5.6 오류업로드 버튼
- 입력: CSV 파일
- 처리:
  - 파일 확장자/필수 컬럼 검증
  - 업로드 배치번호 발급
  - `om_pre_order_errors` 다건 Insert
  - 필요 시 `line_no` 자동보정

## 6. 화면 정의

### 6.1 상단 조회영역
- 고객 팝업 + 고객오더번호 + 처리여부 + 접수일자 범위
- `resource_form`의 submit/reset/validation 규칙 준수

### 6.2 중단 목록영역 (AG Grid)
- 선택 체크 + 오류 식별 컬럼 + 주문/고객/품목/메시지 + 처리여부
- 다중선택 허용(재처리 대상)
- 컬럼 상태 저장/복원 지원

### 6.3 하단 상세영역 (AG Grid)
- 라인번호, 메시지, 품목, 수량/중량/부피, 단위
- 읽기전용

## 7. 메뉴/권한 설계
- 메뉴 코드: `OM_PRE_ORD_ERR`
- 메뉴명: `사전오더접수오류관리`
- URL: `/om/pre_order_reception_errors`
- 부모 메뉴: `OM`
- 권한:
  - `adm_user_menu_permissions`에 사용자별 `OM_PRE_ORD_ERR` 부여
  - 비관리자 미권한 시 `403/루트 리다이렉트` 처리

## 8. 구현 산출물
- Backend
  - `Om::PreOrderReceptionErrorsController`
  - `OmPreOrderError`, `OmPreOrderUploadBatch` 모델
  - `Om::PreOrderReceptionErrorSearchForm`
- Frontend
  - `Om::PreOrderReceptionError::PageComponent` + 템플릿
  - Stimulus `om_pre_order_reception_error_controller.js`
- Infra
  - 라우트 추가
  - 메뉴/권한 마이그레이션 추가
- Test
  - 컨트롤러 통합 테스트(조회/상세/재처리/권한)
