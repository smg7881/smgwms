# PRD: 사전오더접수관리 (OM-PRE-ORDER-RECEPTION) - 완료

## 0. 분석 기준 문서
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-AN13(화면정의서-V1.0)-사전오더접수관리.pdf`
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-DS02(화면설계서-V1.0)-사전오더접수관리.pdf`
- 프런트 규약 참조: `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md`

화면정의서(AN13)와 화면설계서(DS02)를 같은 화면명(사전오더접수관리, `befOrdRecpMngt`) 기준으로 묶어 통합 분석했다.

## 1. User Flow
1. 사용자가 메뉴 `사전오더접수관리` 진입
2. 기본 조회조건 초기화
   - 접수시작일/종료일: 당일
   - 고객/고객오더번호/사전오더번호/상태: 공백(전체)
3. `조회` 클릭
   - 사전오더접수 목록(마스터 AG Grid) 조회
4. 목록에서 1건 이상 선택
   - 선택한 대표 행 기준으로 상세 AG Grid 조회(품목 라인)
5. `오더생성` 클릭
   - 선택한 사전오더번호들에 대해 오더 생성
   - 생성 성공 시 사전오더 상태를 `ORDER_CREATED`로 업데이트
6. 마스터/상세 그리드 재조회 후 결과 확인

## 2. UI Component List (Rails 8 기준)
| 구분 | 컴포넌트/기술 | 역할 |
| --- | --- | --- |
| 검색영역 | `Ui::ResourceFormComponent` | 조회조건 입력 (`q[...]`) |
| 마스터 목록 | `Ui::AgGridComponent` | 사전오더접수 목록 표시/선택 |
| 상세 목록 | `Ui::AgGridComponent` | 선택건의 라인 상세 표시 |
| 툴바 | `Ui::GridToolbarComponent` | `오더생성` 버튼 |
| 그리드 부가액션 | `Ui::GridActionsComponent` | 컬럼상태 저장/초기화, 필터 초기화, CSV |
| 페이지 제어 | Stimulus `om-pre-order-reception` | 마스터 선택-상세 연동, 오더생성 API 호출 |
| 컨트롤러 | `Om::PreOrderReceptionsController` | HTML/JSON, 상세조회, 오더생성 처리 |

## 3. Data Mapping

### 3.1 검색 조건 -> DB 매핑
| 화면 필드 | 파라미터 | DB 컬럼 | 타입/길이 | 비고 |
| --- | --- | --- | --- | --- |
| 고객 | `q[cust_cd]` | `om_pre_order_receptions.cust_cd` | string(20) | 팝업 선택 |
| 고객오더번호 | `q[cust_ord_no]` | `om_pre_order_receptions.cust_ord_no` | string(40) | LIKE 검색 |
| 사전오더번호 | `q[bef_ord_no]` | `om_pre_order_receptions.bef_ord_no` | string(30) | LIKE 검색 |
| 상태 | `q[status_cd]` | `om_pre_order_receptions.status_cd` | string(30) | equals |
| 접수시작일/종료일 | `q[recp_start_ymd]`, `q[recp_end_ymd]` | `om_pre_order_receptions.create_time` | datetime | 일자 범위 조회 |

### 3.2 마스터 그리드 -> DB 매핑
| 화면 컬럼 | DB 컬럼 | 타입 | 매핑 규칙 |
| --- | --- | --- | --- |
| 접수순번(`recp_seq`) | - | integer(가상) | 조회 결과 row_number |
| 사전오더번호 | `bef_ord_no` | string(30) | 직접 매핑 |
| 상태 | `status_cd` | string(30) | 직접 매핑 |
| 고객오더번호 | `cust_ord_no` | string(40) | 직접 매핑 |
| 고객코드 | `cust_cd` | string(20) | 직접 매핑 |
| 고객명 | `cust_nm` | string(120) | 직접 매핑 |
| 품목코드 | `item_cd` | string(40) | 직접 매핑 |
| 품목명 | `item_nm` | string(150) | 직접 매핑 |
| 수량 | `qty` | decimal(14,3) | 직접 매핑 |
| 중량 | `wgt` | decimal(14,3) | 직접 매핑 |
| 부피 | `vol` | decimal(14,3) | 직접 매핑 |
| 접수일자 | `create_time` | datetime | `YYYY-MM-DD` 포맷 |
| 생성오더번호 | `om_orders.ord_no` | string(30) | `cust_ord_no` 기준 최신 오더번호 연결 |

### 3.3 상세 그리드 -> DB 매핑
| 화면 컬럼 | DB 컬럼 | 타입 | 매핑 규칙 |
| --- | --- | --- | --- |
| 라인번호(`line_no`) | - | integer(가상) | 선택 주문 내 row_number |
| 품목코드 | `item_cd` | string(40) | 직접 매핑 |
| 품목명 | `item_nm` | string(150) | 직접 매핑 |
| 수량 | `qty` | decimal(14,3) | 직접 매핑 |
| 중량 | `wgt` | decimal(14,3) | 직접 매핑 |
| 부피 | `vol` | decimal(14,3) | 직접 매핑 |
| 수량/중량/부피 단위코드 | - | - | 현행 스키마 부재로 `null` 반환 |

### 3.4 오더 생성 시 타 테이블 매핑
| 대상 테이블 | 대상 컬럼 | 원천 컬럼/값 |
| --- | --- | --- |
| `om_orders` | `ord_no` | 시스템 생성값 (`ORD + timestamp + random`) |
| `om_orders` | `cust_cd`, `cust_nm`, `cust_ord_no` | `om_pre_order_receptions` 동일 컬럼 |
| `om_orders` | `item_cd`, `item_nm` | `om_pre_order_receptions` 동일 컬럼 |
| `om_orders` | `ord_qty`, `ord_wgt`, `ord_vol` | `qty`, `wgt`, `vol` |
| `om_orders` | `ord_stat_cd` | 고정 `ORDER_CREATED` |
| `om_orders` | `ord_type_cd`, `ord_type_nm` | `PRE_ORDER`, `Pre Order` |
| `om_orders` | `work_stat_cd` | 고정 `WAITING` |
| `om_pre_order_receptions` | `status_cd` | 생성 후 `ORDER_CREATED` 업데이트 |

## 4. Logic Definition (버튼/이벤트 상세)

### 4.1 Open(초기 진입)
- 검색 폼 기본값 세팅
  - `recp_start_ymd = today`
  - `recp_end_ymd = today`

### 4.2 조회 버튼
- 입력 검증
  - 시작일/종료일 필수
  - 종료일 < 시작일이면 서버에서 자동 보정(스왑)
- 조회 처리
  - `GET /om/pre_order_receptions.json?q[...]`
  - 조건 기반 `om_pre_order_receptions` 조회
  - 결과를 마스터 그리드에 바인딩

### 4.3 마스터 행 선택
- `ag-grid:selectionChanged` 이벤트 수신
- 대표 선택행의 `cust_ord_no`(fallback: `bef_ord_no`)로 상세조회
  - `GET /om/pre_order_receptions/items?cust_ord_no=...&bef_ord_no=...`
- 상세 그리드 갱신

### 4.4 오더생성 버튼
- 선택행 0건이면 중단
- 선택행의 `bef_ord_no` 목록 중복 제거 후 사용자 확인(confirm)
- `POST /om/pre_order_receptions/create_orders`
  - payload: `{ bef_ord_nos: [...] }`
- 서버 처리
  - 이미 생성 상태(`ORDER_CREATED`/`CREATED`)는 skip
  - 기존 오더 존재 시 skip + 상태 보정
  - 미생성 건은 `om_orders` insert + 사전오더 상태 update
- 처리 결과 메시지 반환 후 마스터/상세 재조회

## 5. 화면 정의

### 5.1 레이아웃
1. 상단: 조회조건(Resource Form, 4열)
2. 중단: 사전오더접수 목록(마스터 AG Grid, 멀티 선택)
3. 하단: 사전오더접수 상세(디테일 AG Grid)

### 5.2 마스터 컬럼(핵심)
- 접수순번, 사전오더번호, 상태, 고객오더번호, 고객코드, 고객명
- 품목코드, 품목명, 수량, 중량, 부피, 접수일자, 생성오더번호

### 5.3 상세 컬럼(핵심)
- 라인번호, 품목코드, 품목명, 수량/수량단위, 중량/중량단위, 부피/부피단위

## 6. 우리 시스템 맞춤 수정 사항
1. 원 설계서 대비 현행 DB(`om_pre_order_receptions`)에 없는 항목(배차지/도착지, 담당자, 단위코드 일부)은 `null` 정책으로 반환
2. 접수일자는 별도 컬럼이 없어 `create_time`를 접수일자로 사용
3. 상세 라인 테이블이 분리되어 있지 않아, 동일 `cust_ord_no`(보조키 `bef_ord_no`) 묶음으로 상세 구성
4. 상태코드 표준화
   - 접수: `RECEIVED`
   - 생성완료: `ORDER_CREATED`
5. 기존 오더 존재 건은 중복 생성하지 않고 skip 처리

## 7. 메뉴/권한 생성 정의
- 메뉴 코드: `OM_PRE_ORD_RECP`
- 메뉴명: `사전오더접수관리`
- URL: `/om/pre_order_receptions`
- 상위 메뉴: `OM` (오더관리 폴더)
- 사용자별 메뉴권한: `adm_users` 전체 사용자에 대해 `adm_user_menu_permissions` 자동 `use_yn='Y'` 부여
- 마이그레이션: `db/migrate/20260225003000_add_om_pre_order_reception_menu_and_permissions.rb`

## 8. 개발 산출물
- Controller: `app/controllers/om/pre_order_receptions_controller.rb`
- Models:
  - `app/models/om_pre_order_reception.rb`
  - `app/models/om_order.rb`
  - `app/models/om/pre_order_reception_search_form.rb`
- ViewComponent:
  - `app/components/om/pre_order_reception/page_component.rb`
  - `app/components/om/pre_order_reception/page_component.html.erb`
- View:
  - `app/views/om/pre_order_receptions/index.html.erb`
- Stimulus:
  - `app/javascript/controllers/om_pre_order_reception_controller.js`
- Route:
  - `config/routes.rb` 내 `namespace :om` 리소스 추가
- Test:
  - `test/controllers/om/pre_order_receptions_controller_test.rb`
