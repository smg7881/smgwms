# 서비스오더관리 PRD

## 1. 개요
고객에게서 접수된 오더 내역을 서비스오더로 생성하고 이를 등록, 수정, 취소할 수 있는 기능을 제공합니다.

## 2. User Flow (화면 간의 유기적인 흐름)
1. **서비스오더 검색**: 사용자가 `고객코드` 또는 `오더번호`를 입력하여 기등록된 서비스 오더를 검색합니다.
2. **서비스오더 신규 등록**: 
    - `신규` 버튼을 클릭하여 입력 폼을 초기화 및 활성화합니다.
    - `계약번호` 선택 팝업을 통해 계약 정보를 가져옵니다. 이때 계약에 엮인 `고객코드`, `청구고객`, `계약고객`, `오더요청고객` 정보가 자동으로 연동됩니다.
    - `오더유형`, `운송구분` 및 출도착지 상세정보(출발지/도착지)를 입력/선택합니다.
    - 하단의 아이템 상세 내역(AG Grid) 부분에 오더 품목 스펙(수량, 중량, 부피)을 기입합니다.
    - `저장` 버튼을 클릭하여 서비스 오더를 최종 생성합니다.
3. **서비스오더 수정**:
    - 검색된 오더 내역에서 수정사항을 반영합니다. (단, 이미 생성된 실행오더가 있고 가용재고가 부족한 경우 수정 불가)
    - 오더 수정시엔 `오더수정/취소사유`를 필수로 기입해야 합니다.
    - `계약번호`, `오더유형`, `출발지유형코드`, `도착지유형코드`는 수정 비활성화(Disable) 됩니다.
    - `저장`을 클릭하여 수정을 완료합니다.
4. **서비스오더 취소**:
    - 검색된 오더 내역에서 `오더취소사유`를 입력한 후 `오더취소` 버튼을 클릭하여 취소 상태로 변경합니다. (자동/수동 취소 단계 판별)

## 3. UI Component List (Rails 8 & Stimulus 기반)
* **Page Layout**: `Om::BasePageComponent` 또는 `ApplicationComponent` 상속
* **서치폼 영역 (서비스오더검색)**: `resource_form` (컴포넌트 가이드라인 준수)을 활용한 상단 검색.
    * 조회 필드: 고객(팝업 지원), 오더번호(Text)
    * `search-form` Stimulus Controller 연동(`data-controller="search-form"`).
* **입력 폼 영역 (서비스오더 등록/수정/헤더상세)**: `form_with` 문법을 활용한 마스터 데이터 영역.
    * 공통 팝업 버튼(`계약번호선택`, `고객담당자선택`, `출발지선택`, `도착지선택` 등)은 별도의 Stimulus Controller(`search-popup`)으로 제어합니다.
    * Select 박스는 `AdmCodeDetail.select_options_for`를 통해 공통 코드값을 바인딩합니다. (예: 오더유형, 출도착지유형).
* **그리드 영역 (아이템 상세내역)**: `ag_grid_tag`
    * 아이템 추가, 삭제, 수정이 가능한 편집형 AG Grid (`editType: "fullRow"` 또는 column별 `editable: true` 방식).
    * 수량 입력시 중량/부피 동기화를 처리하는 컬럼별 `valueSetter` 또는 Stimulus Controller 로직 구현.
* **Toolbar 컴포넌트**: `Ui::GridToolbarComponent`
    * 버튼: `신규`, `저장`, `오더취소`.

## 4. Data Mapping (화면 입력 필드와 매칭되는 DB 메타데이터)
> **대상 테이블:** `om_orders` (헤더), `om_order_items` (상세 - 아이템)
*(참고: smgWms의 실제 컬럼명 규칙에 맞추어 매핑)*

### 4.1 서비스오더 헤더 (om_orders)
| 화면 항목명 | 영문/속성명 | DB 컬럼/필드 | 속성 | 비고 |
|---|---|---|---|---|
| 계약번호 | ctrtNoCd | `ctrt_no` | E, M | 팝업 선택 |
| 오더유형 | ordTypeCd | `ord_type_cd` | E, M | 매출계약에 매핑된 tb_cm05004 기반 (Select) |
| 고객코드 / 고객명 | custCd / custNm | `cust_cd` / `cust_nm`(가상) | E, M | 계약 팝업 연동 |
| 청구고객 / 명 | bilgCustCd | `bilg_cust_cd` | E, M | 계약 팝업 연동 |
| 오더요청고객 / 명 | ordReqCustCd | `req_cust_cd` | E, M | 계약 팝업 연동 |
| 계약고객 / 명 | ctrtCustCd | `ctrt_cust_cd` | E, M | 계약 팝업 연동 |
| 고객담당자 / 전화번호 | custOfcr / custOfcrTelNo | `cust_ofcr_nm`, `cust_ofcr_tel` | E, M | 담당자선택 팝업 연동 |
| 운송구분 | tranSctnCd | `tran_div_cd` | E, M | Select 박스 |
| 특이사항 | prcl | `remark` | E | |
| 출발지/도착지 유형 | dptArTypeCd / arvArTypeCd | `dpt_type_cd`, `arv_type_cd` | E, M | Select 박스 (75 그룹코드) |
| 출발지/도착지 코드 | dptArCd / arvArCd | `dpt_cd`, `arv_cd` | E, M | 작업장, 거래처 등 팝업 선택 |
| 출발지/도착지 주소 | dptArAddr / arvArAddr | `dpt_addr`, `arv_addr` | R | 팝업 연동시 자동 기입 (우편번호 포함) |
| 시작요청일 / 납기요청일시 | strtReqDay / aptdReqDate | `req_start_dt`, `aptd_req_ymd` | E, M | Date/Time Picker |
| 오더번호 | ordNo | `ord_no` | R | 등록버튼 클릭 완료시 채번 표시 |
| 오더상태 | ordStatCd | `ord_stat_cd` | R | 시스템 처리 결과 |

### 4.2 오더 수정/취소 & 아이템 상세 (om_order_items)
| 화면 항목명 | 영문/속성명 | DB 컬럼/필드 | 속성 | 비고 |
|---|---|---|---|---|
| 오더수정/취소사유 | ordMdfReason | `change_reason`, `cancel_reason` | E, M | 수정/취소 이벤트 발생시 입력 |
| 아이템코드 | itemCd | `item_cd` | E, M | 아이템 팝업 연동 (AG Grid Cell) |
| 수량 | qty | `ord_qty` | E | |
| 중량 | wgt | `ord_wgt` | E | 수량 입력시 DB기본값(TB_CM03001) 연동 환산 |
| 부피 | vol | `ord_vol` | E | 수량 입력시 DB기본값(TB_CM03001) 연동 환산 |

## 5. Logic Definition (비즈니스 로직)
1. **화면 제어 로직**
    * `고객코드`: 기본값 없음(고객 등록된 거래처 한정 팝업).
    * `계약번호`: 선택시 관련된 모든 고객유형(고객, 청구, 오더요청, 계약고객) 셋업.
    * `시작요청일자` & `납기요청일자`: 각각 `Sysdate`, `Sysdate 23:59`를 Default 값으로 표시합니다.
    * `오더수정/취소 사유`: 신규 작성 시에는 화면에 노출되지 않고(Hidden) 상태 변경 시에만 노출/요구 받도록 처리.
2. **환산 로직 (Item 수량 -> 중량/부피)**
    * 아이템 마스터(`TB_CM03001` 매핑 로직)의 총중량(`TOT_WGT`), 부피(`CBM`) 필드값을 참조합니다.
    * 화면에서 `수량` Grid 컬럼을 수정/입력 시: `중량` = 수량 * 총중량, `부피` = 수량 * 부피 로 환산 후 사사오입(반올림) 합니다. (이 로직은 JavaScript Controller에서 수행 후 서버에 전달)
3. **가용재고 및 오더상태 분기**
    * 오더 신규 생성시, 출발지 유형이 `작업장`일 경우 보관시스템(WMS)의 가용재고를 내부적으로 체크하여 `대기오더` 여부와 `상태`를 결정합니다. 영업소코드는 권역별 우편번호 맵핑을 통해 부서를 자동 조회하여 생성시에 백엔드에서 입력합니다.
    * 실행오더가 이미 진행중인 상태에서 오더 수정 요청 시 가용재고 체크 후 부족하면 오류 반환(`재고가 부족합니다`). 

## 6. 화면 정의 (System Layout)
* **Toolbar**: 우측 상단 `조회`, `신규`, `저장`, `오더취소` 버튼 일렬 배치.
* **검색 조건 구역**: 상단 Box 처리, 고객(팝업), 오더번호(Text).
* **Master Header 구역**: 그리드 형태가 아닌, 입력 Form 형식(Label - Input/Select 짝)으로 구성. 여러 탭이나 섹션 분할로 출도착지 상세를 명시합니다.
* **Detail Grid 구역**: Master 하단에 아이템 목록을 AG Grid로 제공하여 인라인 추가/편집이 용이하게 레이아웃을 분리 설계합니다.
