# PRD - 사전오더파일업로드 (befOrdFileUl)

## 1. 화면 정의

| 항목 | 내용 |
|---|---|
| 화면ID | `befOrdFileUl` |
| 화면명 | 사전오더파일업로드 |
| 메뉴코드 | `OM_PRE_ORD_FILE_UL` |
| URL | `/om/pre_order_file_uploads` |
| 목적 | 고객사 Excel/CSV 파일 기반 사전오더 데이터 업로드, 필수항목 검증, 오더 반영 |
| 기본 UI 원칙 | 조회/입력 영역은 `resource_form`, 결과 목록은 `ag-grid` 사용 |
| 적용 가이드 | `doc/frontend/STIMULUS_COMPONENTS_GUIDE.md`, `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md` |

## 2. User Flow

1. 사용자 진입 시 업로드 폼(`resource_form`)과 결과 그리드(`ag-grid`)가 표시된다.
2. 사용자가 업로드 파일(`.xls/.xlsx/.csv`)을 선택한다.
3. `파일미리보기` 클릭 시 파일을 파싱하고 행별 결과를 그리드에 표시한다.
4. `필수항목체크` 클릭 시 필수값/날짜/수량 규칙을 검증하고 성공/오류 건수를 표시한다.
5. 오류가 없으면 `업로드저장` 버튼이 활성화된다.
6. `업로드저장` 클릭 시 배치 이력 생성 후 사전오더/오더 데이터 반영을 수행한다.
7. 저장 완료 후 배치번호, 처리건수, 오류건수를 사용자에게 반환한다.
8. `양식다운로드` 클릭 시 표준 업로드 템플릿(`OM_beforeORDERregister.xlsx`)을 다운로드한다.

## 3. UI Component List (Rails 8 기준)

- `Om::PreOrderFileUpload::PageComponent`
- `Ui::ResourceFormComponent`
- `Ui::AgGridComponent`
- `Ui::GridToolbarComponent`
- `Ui::GridActionsComponent`
- Stimulus:
  - `resource-form`
  - `ag-grid`
  - `om-pre-order-file-upload`

## 4. Data Mapping

### 4.1 업로드 입력 필드 -> 도메인 필드

| 입력 필드 | 내부 필드 | 저장 테이블 | 설명 |
|---|---|---|---|
| 사전오더번호 | `bef_ord_no` | `om_pre_order_receptions` | 사전오더 식별자 |
| 오더번호(선택) | `ord_no` | `om_orders` | 미입력 시 시스템 생성 |
| 고객코드 | `cust_cd` | `om_pre_order_receptions`, `om_orders` | 고객 식별 코드 |
| 고객오더번호 | `cust_ord_no` | `om_pre_order_receptions`, `om_orders` | 고객 요청 오더 번호 |
| 오더요청고객코드 | `ord_req_cust_cd` | `om_orders.contract_cust_cd` | 계약/요청 고객 매핑 |
| 청구고객코드 | `bilg_cust_cd` | `om_orders.billing_cust_cd` | 청구 고객 코드 |
| 출발지코드 | `dpt_ar_cd` | `om_orders.dpt_ar_cd` | 출발지 |
| 도착지코드 | `arv_ar_cd` | `om_orders.arv_ar_cd` | 도착지 |
| 시작요청일자 | `strt_req_ymd` | 검증 전용 | 납기요청일자와 비교 검증 |
| 납기요청일자 | `aptd_req_ymd` | `om_orders.aptd_req_ymd` | 납기일 |
| 아이템코드 | `item_cd` | `om_pre_order_receptions`, `om_orders` | 품목코드 |
| 아이템명 | `item_nm` | `om_pre_order_receptions`, `om_orders` | 품목명 |
| 수량/중량/부피 | `qty/wgt/vol` | `om_pre_order_receptions`, `om_orders` | 오더 수치 데이터 |

### 4.2 업로드 배치/오류 메타데이터

| 테이블 | 주요 필드 | 용도 |
|---|---|---|
| `om_pre_order_upload_batches` | `upload_batch_no`, `file_nm`, `upload_stat_cd`, `error_cnt` | 업로드 실행 이력 |
| `om_pre_order_errors` | `upload_batch_no`, `line_no`, `err_type_cd`, `err_msg` | 행 단위 오류 상세 |

## 5. Logic Definition

### 5.1 Open
- 업로드 폼/결과 그리드를 초기화한다.
- 저장 버튼은 기본 비활성화한다.

### 5.2 파일미리보기 (`POST /om/pre_order_file_uploads/preview`)
- 파일 파싱 수행
- 행별 파싱 결과를 즉시 반환
- `succ_yn`, `err_msg`를 그리드에 표시

### 5.3 필수항목체크 (`POST /om/pre_order_file_uploads/validate_rows`)
- 필수값 검증:
  - `bef_ord_no`, `cust_cd`, `cust_ord_no`, `item_cd`, `qty`, `strt_req_ymd`, `aptd_req_ymd`, `dpt_ar_cd`, `arv_ar_cd`
- 업무 검증:
  - `qty > 0`
  - `wgt/vol >= 0`
  - `aptd_req_ymd >= strt_req_ymd`
- 오류가 0건이면 저장 버튼 활성화

### 5.4 업로드저장 (`POST /om/pre_order_file_uploads/save`)
- 재검증 후 저장
- 실패 시:
  - `om_pre_order_upload_batches`에 `FAILED` 배치 생성
  - `om_pre_order_errors`에 오류 저장
- 성공 시:
  - `om_pre_order_upload_batches`에 `SUCCESS` 배치 생성
  - `om_pre_order_receptions` 업서트
  - `om_orders` 생성/갱신
  - 수신 상태를 `ORDER_CREATED`로 갱신

### 5.5 양식다운로드 (`GET /om/pre_order_file_uploads/download_template`)
- 표준 컬럼 헤더 + 샘플 1행이 포함된 템플릿 엑셀 제공

## 6. 화면 간 유기적 흐름

- 사전오더파일업로드 -> (저장 성공) -> 사전오더접수/오더조회 화면에서 데이터 확인 가능
- 업로드 배치 실패건은 오류 테이블 기준으로 재처리 대상 관리 가능
- 동일 고객오더/품목 조합은 기존 오더 갱신 우선, 미존재 시 신규 생성

## 7. 우리 시스템 반영 사항

1. 원 문서의 Java 모듈 호출 구조는 Rails 서비스 객체(`Om::PreOrderFileUploadService`)로 대체
2. 기존 스키마(`om_pre_order_*`, `om_orders`)에 맞게 저장 로직 재설계
3. 화면 구현은 ViewComponent + Stimulus 규약 준수
4. 업로드 화면은 `OM` 네임스페이스 하위로 생성

## 8. 메뉴 및 사용자별 메뉴권한

- 신규 메뉴:
  - `menu_cd`: `OM_PRE_ORD_FILE_UL`
  - `menu_nm`: `사전오더파일업로드`
  - `menu_url`: `/om/pre_order_file_uploads`
  - `parent_cd`: `OM`
- 권한 부여:
  - `adm_user_menu_permissions`에 전체 사용자(`adm_users`) 대상 `use_yn=Y`로 자동 생성
  - 비관리자 접근 시 메뉴 권한 체크 강제
