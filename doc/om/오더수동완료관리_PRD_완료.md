# PRD: 오더수동완료관리 (OM-ORD-MANL-CMPT) - 완료

## 0. 기준 문서
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-AN13(화면정의서-V1.0)-오더수동완료관리.pdf`
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-DS02(화면설계서-V1.0)-오더수동완료관리.pdf`
- 프런트 구현 규칙: `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md`

## 1. User Flow
1. 사용자가 `오더관리 > 오더수동완료관리` 메뉴로 진입한다.
2. 조회조건(`고객`, `일자구분`, `시작일자`, `종료일자`, `오더번호`)을 입력한다.
3. `조회` 버튼으로 수동완료 대상 목록을 조회한다.
4. 대상 목록에서 수동완료할 오더를 다중 선택한다.
5. 목록 행 클릭 시 하단 상세 그리드에 아이템/오더/실적/잔여 정보를 표시한다.
6. `수동완료 사유` 입력 후 `오더수동완료` 버튼을 클릭한다.
7. 서버는 선택 오더별 검증 후 완료 가능한 건에 대해 상태를 완료로 변경한다.
8. 처리 결과(성공/실패 건수)를 사용자에게 알리고 목록을 재조회한다.

## 2. UI Component List (Rails 8 기준)
| 영역 | 컴포넌트 | 구현 상세 |
| --- | --- | --- |
| 조회조건 | `Ui::ResourceFormComponent` | `method: :get`, `q` 파라미터 기반 검색폼 |
| 고객 선택 | `search-popup` Stimulus | `popup_type: client`, `cust_cd/cust_nm` 바인딩 |
| 목록 툴바 | `Ui::GridToolbarComponent` 스타일 버튼 | 사유 입력 + `오더수동완료` 버튼 |
| 대상 목록 | `Ui::AgGridComponent` | 다중선택(`row_selection: multiple`), 읽기전용 컬럼 |
| 대상 상세 | `Ui::AgGridComponent` | 오더/실적/잔여 수치 표시 |
| 화면 제어 | `om-order-manual-completion` Stimulus | 목록 선택, 상세 조회, 완료 API 호출 |

## 3. Data Mapping (입력필드 ↔ DB 메타데이터)

### 3.1 검색 조건 매핑
| 화면 필드 | 파라미터 | DB 컬럼/로직 |
| --- | --- | --- |
| 고객코드 | `q[cust_cd]` | `om_orders.cust_cd` |
| 고객명 | `q[cust_nm]` | 조회조건 표시용(코드 팝업 Display) |
| 일자구분 | `q[date_type]` | `create_time` 또는 `aptd_req_ymd` |
| 시작일자 | `q[start_date]` | 기간 시작, 월 시작일 이전 입력 시 월 시작일로 보정 |
| 종료일자 | `q[end_date]` | 기간 종료, 월말 이후 입력 시 월말로 보정 |
| 오더번호 | `q[ord_no]` | `om_orders.ord_no LIKE` |

### 3.2 목록 그리드 매핑
| 화면 컬럼 | DB 컬럼 |
| --- | --- |
| 오더상태 | `om_orders.ord_stat_cd` |
| 오더번호 | `om_orders.ord_no` |
| 오더유형명 | `om_orders.ord_type_nm` (없으면 `ord_type_cd`) |
| 오더생성일시 | `om_orders.create_time` |
| 고객납기요청일자 | `om_orders.aptd_req_ymd` |
| 출발지명 | `om_orders.dpt_ar_nm` |
| 도착지명 | `om_orders.arv_ar_nm` |

### 3.3 상세 그리드 매핑
| 화면 컬럼 | DB 컬럼/연산 |
| --- | --- |
| 분배차수 | `COUNT(om_work_routes where ord_no)` |
| 아이템코드/명 | `om_orders.item_cd`, `om_orders.item_nm` |
| 작업상태 | `om_orders.work_stat_cd` (없으면 `작업중`) |
| 오더 수량/중량/부피 | `om_orders.ord_qty/ord_wgt/ord_vol` |
| 실적 수량/중량/부피 | `SUM(om_work_route_results.rslt_qty/rslt_wgt/rslt_vol)` |
| 잔여 수량/중량/부피 | `오더 - 실적` |

### 3.4 수동완료 업데이트 매핑
| 업무 항목 | DB 컬럼 | 값 |
| --- | --- | --- |
| 오더상태코드 | `om_orders.ord_stat_cd` | `60` |
| 오더완료구분코드 | `om_orders.ord_cmpt_div_cd` | `20` |
| 오더완료일시 | `om_orders.ord_cmpt_dtm` | `Time.current` |
| 수동완료사유 | `om_orders.manl_cmpt_rsn` | 화면 입력값 |

## 4. Logic Definition

### 4.1 Open
- 기본 조회기간은 `당월 1일 ~ 당일`로 세팅한다.
- 종료일이 시작일보다 작으면 종료일을 시작일로 보정한다.
- 수동완료 대상 기본 필터:
  - `use_yn = 'Y'`
  - `ord_stat_cd in ('50', 'WORKING', 'IN_PROGRESS')`
  - `ord_type_cd <> '30'`

### 4.2 조회 (`GET /om/order_manual_completions.json`)
- 검색 조건을 적용해 대상 오더를 조회한다.
- 정렬은 `create_time DESC, ord_no DESC`를 적용한다.
- 목록 그리드 바인딩용 JSON 배열을 반환한다.

### 4.3 상세조회 (`GET /om/order_manual_completions/:ord_no/details`)
- 선택 오더 1건 기준으로 상세 행을 구성한다.
- 실적은 `om_work_route_results` 합계로 계산한다.
- 실적이 없으면 0으로 처리한다.

### 4.4 오더수동완료 (`POST /om/order_manual_completions/complete`)
- 입력 검증:
  - 선택 오더 1건 이상 필수
  - 수동완료 사유 필수
- 오더별 처리:
  - 오더 존재 여부 확인
  - 수동완료 가능 상태인지 재검증
  - 가능 시 상태/완료구분/완료일시/사유 업데이트
- 결과:
  - 전체 성공 시 `success=true`
  - 일부 실패 시 완료건/실패건을 함께 반환

## 5. 화면 정의 (우리 시스템 반영)
- 검색영역은 `resource_form`으로 구성한다.
- 목록/상세는 모두 `ag-grid`로 구성한다.
- 팝업은 공통 `search-popup(client)`를 재사용한다.
- 레이아웃:
  - 상단: 조회조건
  - 중단: 수동완료 대상 목록 + 사유/완료 버튼
  - 하단: 선택 오더 상세
- 기존 문서의 TB 기준 용어는 현재 스키마(`om_orders`, `om_work_routes`, `om_work_route_results`)로 매핑해 적용한다.

## 6. 메뉴 및 사용자별 메뉴권한
### 6.1 메뉴 생성
- `menu_cd`: `OM_ORD_MANL_CMPT`
- `menu_nm`: `오더수동완료관리`
- `menu_url`: `/om/order_manual_completions`
- `parent_cd`: `OM`
- `tab_id`: `om-order-manual-completions`

### 6.2 사용자별 권한 생성
- 대상: `adm_users` 전체 사용자
- 처리: `adm_user_menu_permissions`에 `(user_id, menu_cd)` 기준 upsert
- `use_yn = 'Y'`로 부여

## 7. 개발 산출물
- `app/controllers/om/order_manual_completions_controller.rb`
- `app/models/om/order_manual_completion_search_form.rb`
- `app/models/om_order.rb` (수동완료 로직 추가)
- `app/models/om_work_route.rb`
- `app/models/om_work_route_result.rb`
- `app/components/om/order_manual_completion/page_component.rb`
- `app/components/om/order_manual_completion/page_component.html.erb`
- `app/views/om/order_manual_completions/index.html.erb`
- `app/javascript/controllers/om_order_manual_completion_controller.js`
- `config/routes.rb` (`namespace :om` 내 라우트 추가)
- `db/migrate/20260225013000_add_manual_completion_fields_to_om_orders.rb`
- `db/migrate/20260225013001_add_order_manual_completion_menu_and_permissions.rb`
