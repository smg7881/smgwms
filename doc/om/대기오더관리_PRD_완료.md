# PRD: 대기오더관리 (OM-WAITING-ORD) - 완료

## 0. 기준 문서
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-AN13(화면정의서-V1.0)-대기오더관리.pdf`
- `D:\_LOGIS\2.오더\pdf\LogisT-OM-DS02(화면설계서-V1.0)-대기오더관리.pdf`
- 프런트 규칙 참조: `doc/com/frontend/STIMULUS_COMPONENTS_GUIDE.md`

## 1. User Flow
1. **메뉴 진입**: 사용자가 `오더 > 대기오더관리` 메뉴에 진입합니다.
2. **조회조건 입력**: 
   - 고객코드/명(공통 팝업), 일자(오더생성일자/납기요청일자), 시작/종료일자(현재일 기본값)를 설정.
   - `resource_form`을 사용하여 검색 폼을 구성.
3. **대기오더 조회**:
   - `조회` 버튼 클릭 시, JSON API(`/om/waiting_orders.json`)를 호출하여 대기 상태(`STB_ORD_YN = 'Y'`, 또는 상태코드 기준)인 오더 및 가용재고 정보를 AG Grid에 바인딩.
4. **가용재고 확인 및 오더 분배**:
   - 목록에서 오더를 선택하고 하단 아이템 상세 그리드에서 분배할 수량/중량/부피를 입력.
   - 가용재고량 내에서만 분배 가능 여부를 프론트엔드/백엔드에서 검증.
   - `오더분배` 버튼 클릭 시 분배 API(`/om/waiting_orders/distribute`) 호출.
5. **분배 완료**:
   - 모든 오더량에 대하여 분배가 끝나면 대기오더 상태가 해제(대기오더여부 = 'N' 또는 상태 변경)됨.
   - 그리드 재조회하여 화면 갱신.

## 2. UI Component List (Rails 8 기준)
| 영역 | 컴포넌트 | 구현 방안 |
| --- | --- | --- |
| **검색 폼** | `Ui::ResourceFormComponent` | `resource_form` 헬퍼 사용, `method: :get`, `submit_label: 조회` |
| **고객 선택** | `search-popup` (Stimulus) | 거래처(고객) 선택 공통 팝업, `cust_cd`, `cust_nm` 바인딩 |
| **상단 그리드** | `Ui::AgGridComponent` | 대기오더 목록 (Read Only) |
| **하단 그리드** | `Ui::AgGridComponent` | 대기오더 상세 (아이템별 분배량 입력 가능하도록 Editable 컬럼 제공) |
| **버튼 툴바** | `Ui::GridToolbarComponent` | `오더분배`, `가용재고조회(동기화)` 버튼 제공 |
| **JS 컨트롤러**| `om-waiting-order-grid` | 2개의 그리드를 연동 및 오더분배 Submit 로직 처리 (Stimulus) |

## 3. Data Mapping (입력필드 ↔ DB 메타)
> *현재 DB 스키마(`om_orders`)가 오더와 아이템을 1:1로 가지고 있는 구조임을 반영하여 매핑.*

### 3.1 검색 폼 (`q`)
| 화면 필드 | 파라미터 | 매핑 컬럼 / 로직 |
| --- | --- | --- |
| 고객 | `q[cust_cd]` | `om_orders.cust_cd` |
| 일자 구분 | `q[date_type]` | 오더생성일(`create_time`) / 납기요청일(`aptd_req_ymd`) 선택 |
| 시작/종료일자 | `q[start_date]`, `q[end_date]` | 선택된 일자 구분에 따른 기간 필터 (기본값: 당일 ~ 당월 말) |

### 3.2 그리드 데이터 (`om_orders` 등)
| 화면 컬럼 | 매핑 컬럼 | 필수/편집 | 비고 |
| --- | --- | --- | --- |
| 오더상태 | `ord_stat_cd` | R | 공통코드 연계 |
| 오더번호 | `ord_no` | R | |
| 오더유형 | `ord_type_cd` | R | 공통코드 연계 |
| 생성일시 | `create_time` | R | |
| 고객납기요청 | `aptd_req_ymd` | R | |
| 변경납기일시 | `chg_aptd_date`(예상) | E | 필요 시 변경 가능 |
| 출발지 | `dpt_ar_nm` | R | |
| 도착지 | `arv_ar_nm` | R | |
| 아이템코드 | `item_cd` | R | `om_orders` 내 포함 |
| 아이템명 | `item_nm` | R | `om_orders` 내 포함 |
| 수량/중량/부피(오더) | `ord_qty`, `ord_wgt`, `ord_vol` | R | |
| 분배 수/중/부피 | `dist_qty`, `dist_wgt`, `dist_vol` | E | API 전송용 입력 필드 (잔여량 이하로만 입력 제한) |
| 가용재고 | `avail_qty` 등 | R | 보관시스템 연계 결과 (임시 연산 결과 바인딩) |
| 잔여 수/중/부피 | (UI 연산) | R | `오더량 - 분배완료량 - 입력 분배량` |

## 4. Logic Definition (버튼 클릭 트랜잭션 등)
### 4.1 화면 Open (`initialize`)
- 검색조건 `시작일자`, `종료일자`는 현재일 기준으로 세팅. `종료일자`는 월말을 넘기지 않음.
- 대기오더 여부를 판별하는 조건(상태코드 등)이 기본 필터로 적용.

### 4.2 대기오더조회 (`조회` 버튼)
- `resource_form` submit 이벤트 호출 (GET).
- `Om::WaitingOrdersController#index`에서 JSON 형태의 리스트 반환 시 상/하단 또는 마스터 구조로 AG Grid 렌더링.

### 4.3 가용재고조회
- 선택된 행의 아이템 및 작업장 기준으로 보관시스템 쪽에 가용재고 API 질의 (현재는 시스템 내 mock 로직 또는 프로시저 호출로 구현).
- 결과를 그리드 `가용재고량` 컬럼에 업데이트.

### 4.4 오더분배 (`오더분배` 버튼)
- 분배 수량/중량/부피가 가용 재고 및 잔여량보다 큰지 프론트엔드 검증.
- `POST /om/waiting_orders/distribute` 파라미터로 선택된 `ord_no` 및 분배량 객체 전송.
- 성공 시, 잔여량이 0이 될 경우 `om_orders`의 대기 상태 플래그를 N(또는 확정 상태)으로 업데이트.
- 작업 완료 후 그리드 리프레시.

## 5. 화면 정의 (우리 시스템 맞춤 수정)
- 기존 화면정의서의 2개 그리드(마스터-디테일) 구조를 **하나의 Row 렌더러 또는 마스터-디테일 AG Grid 기능**으로 수용하거나, 화면을 상하 분할하여 구현.
- `app/views/om/waiting_orders/index.html.erb` 템플릿에 `search_form_tag`, `ag_grid_tag`를 배치하여 심플하게 구현.

## 6. 메뉴 및 권한 정의
### 6.1 메뉴 (AdmMenu)
- `menu_cd`: `OM_WAITING_ORD`
- `menu_nm`: `대기오더관리`
- `menu_url`: `/om/waiting_orders`
- `parent_cd`: `OM` (오더 폴더)

### 6.2 사용자 권한 (`adm_user_menu_permissions`)
- `adm_users` 테이블의 활성 사용자(`work_status = 'ACTIVE'`) 전원에게 해당 메뉴 접근 권한(`use_yn = 'Y'`) 부여 마이그레이션 포함.

## 7. 개발 산출물 목록
1. **Controller**: `app/controllers/om/waiting_orders_controller.rb`
2. **View (Page Component)**: `app/components/om/waiting_order/page_component.rb`, `page_component.html.erb`
3. **JS Target**: `app/javascript/controllers/om_waiting_order_grid_controller.js`
4. **Migration**: `db/migrate/..._add_waiting_orders_menu.rb`
5. **Routes**: `config/routes.rb` 내 `namespace :om` -> `resources :waiting_orders, only: [:index] do collection { post :distribute } }`
