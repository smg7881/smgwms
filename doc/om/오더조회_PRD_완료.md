# 오더조회 PRD

## 1. 개요
고객에게 접수된 오더의 메인 정보 및 해당 오더에 속한 아이템 상세 내역을 1대의 화면에서 Master-Detail 다중 그리드 형태로 조회하는 기능입니다.

## 2. User Flow (화면 간의 유기적인 흐름)
1. **오더 검색 조건 구성**: 상단 서치폼에 고객코드, 일자(시작/종료), 오더종류, 완료구분 등의 조회조건을 설정합니다. (고객코드는 검색 팝업 활용 가능)
2. **오더 목록(Master) 검색**: [검색] 버튼을 클릭하면, 조건을 충족하는 오더 리스트가 메인 그리드(상단)에 출력됩니다.
3. **오더 아이템(Detail) 조회**: 메인 그리드에서 특정 오더 Row를 클릭하게 되면, 하단 아이템 그리드(하단)에 해당 오더에 속한 아이템 목록 및 관련된 오더 내역(수량/중량/부피 단위)이 조회 및 출력됩니다.

## 3. UI Component List (Rails 8 & Stimulus 기반)
* **Page Layout**: `Om::BasePageComponent` 상속 레이아웃.
* **서치폼 영역 (오더목록검색)**: `resource_form` (기본 폼 컨테이너 활용).
    * 조회 필드 1: 고객(필수) - `search-popup` 컴포넌트 연동.
    * 조회 필드 2: 날짜(필수) - `date-picker` 연동. 시작일/종료일. 달력 컴포넌트.
    * 조회 필드 3: 오더종류, 완료구분, 오더구분 - `select` 콤보박스 연동 (공통코드).
    * `search-form` Stimulus Controller에서 submit 이벤트 트리거.
* **마스터 영역 (오더목록 Grid)**: `ag-grid` 활용 (상단 리스트).
    * `rowClicked` 이벤트 연결을 통한 하단 Detail 그리드 데이터 갱신 처리.
* **디테일 영역 (오더아이템 Grid)**: `ag-grid` 활용 (하단 리스트).
* **프론트엔드 액션 제어**: `om_order_inquiry_controller.js`
    * Master 그리드와 Detail 그리드의 Data 연동 및 JSON 데이터 콜백 처리 역할 수행.

## 4. Data Mapping (화면 입력 필드와 매칭되는 DB 메타데이터)
> **대상 메인 테이블:** 오더 마스터(`TB_OM03001`), 오더 아이템(`TB_OM03002`) (추정 모델: `OmOrder`, `OmOrderItem`)

### 4.1. 서치폼
| 화면 항목명 | 영문/속성명 | 성격 | 비고 |
|---|---|---|---|
| 고객코드/명 | custCd, custNm | 필, E | `TB_CM04006` 조건, Search 팝업 |
| 시작/종료일자 | strtYmd, endYmd | 필, E | 생성일자 및 납기요청일 중 택 1하여 필터 |
| 오더종류 | ordKindCd | E | 공통코드 Group 79 |
| 완료구분 | cmptSctnCd | E | 공통코드 Group 86 |
| 오더구분 | ordSctnCd | E | 공통코드 Group 162 |

### 4.2. 오더목록 (Master Grid)
| 화면 항목명 | 영문/속성명 | 비고 |
|---|---|---|
| 오더상태 | ordStatCd | 공통코드 매핑 |
| 오더번호 | ordNo | |
| 생성일자 | creatYmd | |
| 오더유형 | ordTypeCd | `TB_CM02019` |
| 고객거래처명 | custBzacNm | `TB_CM04006` |
| 출도착지명 | dptArNm, arvArNm | `TB_CM02004` |

### 4.3. 오더아이템목록 (Detail AG Grid)
| 화면 항목명 | 영문/속성명 | 비고 |
|---|---|---|
| 순번 | seq | |
| 아이템 코드/명 | itemCd, itemNm | `TB_CM03001` |
| 오더 수량/중량/부피 | ordQty, ordWgt, ordVol | |
| 단위코드들 | qtyUnitCd, wgtUnitCd, volUnitCd | |

## 5. Logic Definition (비즈니스 로직)
1. **화면 폼 기본 세팅**
   * 접속 시 일자는 현재 날짜 세팅, 오더 종류/완료/구분 콤보는 전체 항목으로 로딩 (서버 사이드 폼 옵션 적용 권장).
2. **마스터 조회 비즈니스 규칙**
   * 정산오더(30), 대기오더 처리건(대기여부 Y)은 조회 리스트에서 걸러야 함.
   * 서치 폼의 옵션 조합에 따른 DB(또는 ActiveRecord) `.where` Search 로직 API. JSON 형태로 마스터 목록 반환.
3. **디테일(아이템) 조회**
   * 마스터 그리드의 클릭(선택) 액션 발생 시, 해당 오더의 `ordNo` (오더번호)를 파라미터로 하여 상세 아이템 API(`GET /om/order_inquiries/:id/items` 등)를 호출하여 반환된 JSON 배열로 아래쪽 그리드 Data Update 수행.

## 6. 화면 정의 (System Layout)
* **상단 조건바**: resource_form을 비롯한 다수의 조건 검색 박스 필드 배열.
* **중앙 마스터 그리드**: 페이지 상단에 위치한 넓은 ag-grid. 오토 하이트 또는 고정 450px 내외. (오더목록 표시 공간)
* **하단 디테일 그리드**: 마스터 Grid 바로 아래 배치되는 세로 분할 형태의 ag-grid 구조. 마스터 클릭 시 연동 데이터 노출. (오더아이템 표시 공간)
