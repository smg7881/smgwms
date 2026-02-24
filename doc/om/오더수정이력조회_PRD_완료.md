# 오더수정이력조회 PRD

## 1. 개요
선택한 오더(오더번호 기준)에 대한 변경(수정) 이력 리스트업 및 해당 이력 순번별 상세 변경 정보(출도착지, 사전오더, 진행정보, 아이템)를 탭 형식으로 세분화하여 조회하는 기능입니다.

## 2. User Flow (화면 간의 유기적인 흐름)
1. **이력 검색**: 사용자가 상단 조회조건에서 `오더번호`와 `이력순번`을 입력하고 검색 버튼을 클릭합니다.
   * `이력순번`이 비어있으면 해당 오더번호의 전체 이력을 조회합니다.
2. **이력 목록 조회 (Master)**: 검색된 오더의 이력(History) 목록이 상단 메인 그리드(AG Grid)에 표출됩니다.
3. **상세 정보 탭 조회 (Detail)**: 메인 그리드에서 특정 이력 Row를 클릭하면, 하단 영역의 4개 탭(출도착지정보, 사전오더, 오더진행정보, 아이템상세)에 해당 이력 시점의 스냅샷 데이터가 출력됩니다. 각 탭을 클릭하여 상세 정보를 번갈아 확인할 수 있습니다.

## 3. UI Component List (Rails 8 & Stimulus 기반)
* **Page Layout**: `Om::BasePageComponent` 상속 레이아웃.
* **서치폼 영역 (오더수정이력검색)**: `resource_form`을 활용.
    * 조회 필드: 오더번호(필수, 팝업 가능), 이력순번.
    * `search-form` Stimulus Controller 연동.
* **이력 목록 영역 (Master Grid)**: `ag-grid` 활용.
    * 컬럼: 순번, 구분, 오더번호, 고객오더번호, 오더유형, 고객, 계약번호, 상태 등.
    * Row 선택(Click) 이벤트 발생 시 하단 상세 영역 데이터 갱신을 위한 커스텀 이벤트 Dispatch 처리.
* **상세 영역 (Detail Tabs)**: `tabs` 컨트롤러 활용 (STIMULUS 디자인 가이드 준수).
    * **Tab 1: 출도착지정보**: ReadOnly 텍스트 컴포넌트로 구성된 Form Layout.
    * **Tab 2: 사전오더**: ReadOnly 텍스트 컴포넌트로 구성된 Form Layout.
    * **Tab 3: 오더진행정보**: ReadOnly 텍스트 컴포넌트로 구성된 Form Layout.
    * **Tab 4: 아이템상세**: 이력 시점의 아이템 목록을 보여주는 `ag-grid`. (수량 묶음 등 컬럼 그룹 사용)
* **프론트엔드 액션 제어**: `om_order_modification_history_controller.js`
    * Master Grid 제어, Detail Grid(아이템) 제어, Form Binding, 탭 내 정보 Update 로직 중앙 통제.

## 4. Data Mapping (화면 입력 필드와 매칭되는 DB 메타데이터)
> **대상 메인 테이블:** О더 이력(`TB_OM03003H`), 오더 아이템 이력(`TB_OM03004H`). (또는 `OmOrderHistory`, `OmOrderItemHistory` 모델)

### 4.1. 서치폼
| 화면 항목명 | 영문/속성명 | 성격 | 비고 |
|---|---|---|---|
| 오더번호 | ordNo | E, 필수 | `search-popup` 대상 |
| 이력순번 | histSeq | E | 선택사항(전체) |

### 4.2. 오더수정이력목록 (Master Grid)
| 화면 항목명 | 영문/속성명 | 비고 |
|---|---|---|
| 구분 / 순번 | sctn / histSeq | 이력 구분 및 버전 번호 |
| 오더번호 | ordNo | |
| (고객/계약/청구)고객 | custCd, ctrtCustCd | 마스터(`TB_CM04001`) 참조 명칭 변환 |
| 오더유형 / 오더상태 | ordTypeCd, ordStatCd | 공통코드 매핑 |
| 오더담당자/부서 | ordOfcr / ordChrgDeptCd | |
| 긴급 여부 필드들 | custExprYn, clsExprYn | Y/N |

### 4.3. 상세 탭 1~3 (Form Data 매핑)
메인 그리드에서 선택된 `histSeq`에 해당하는 Row의 데이터셋 속성을 재배치합니다.
* **출도착지정보**: dptArCd (출발지), arvArCd (도착지), strtReqDate (시작요청일시), aptdReqDate (납기요청일시) 등.
* **사전오더**: ordTypeCd (오더유형), custOrdRecpDate (접수일시), ordReqCustCd (요청고객) 등.
* **오더진행정보**: creatDate (생성일시), cnclDate (취소일시), ordCnclReasonCd (취소사유), cmptDate (완료일시) 등.

### 4.4. 상세 탭 4 (Detail AG Grid - 아이템상세)
| 화면 항목명 | 영문/속성명 | 비고 |
|---|---|---|
| 구분 / 순번 | sctn / seq | 아이템 순번 |
| 아이템 코드/명 | itemCd / itemNm | `TB_CM03001` 매핑 |
| 기본단위 | basisUnitClsCd | |
| 오더 수량/중량/부피 | qty, wgt, vol | 단위코드(unitCd)와 병기 |

## 5. Logic Definition (비즈니스 로직)
1. **검색 로직 (Master Reload)**: `오더번호`와 `이력순번`(옵션)을 조건으로 `OmOrderHistory` 테이블을 조회하여 Master Grid (오더수정이력목록)에 JSON 반환.
2. **Master Row Click => Detail 렌더링**: 
   * Master Grid 에서 Row를 클릭할 때 해당 Row의 식별자(ord_no, hist_seq)를 기반으로 백엔드 API 단건(상세) 조회를 호출합니다. (또는 최초 검색 시 Master+Detail 구조상 미리 JSON으로 묶어 내려받아 JS 컬렉션 탐색 위임).
   * 받아온 데이터(1건의 상세 내역 객체와 배열인 아이템 이력 리스트)를 탭 1~3 영역(Input 폼)과 탭 4 영역(Item Grid)에 Data Bind 처리합니다.
3. **공통코드 치환**: 명칭(도착지명, 오더상태명 등)은 DB에서 Join 또는 Enum 형식 지원을 통해 Server Side Rendering 또는 JSON 속성 포함으로 일원화.

## 6. 화면 정의 (System Layout)
* **상단 조건바**: 검색조건 배치 (resource_form).
* **중앙 (Master Grid)**: 상하 분할의 위쪽 영역. 페이지네이션 10개 혹은 오토하이트를 갖는 목록 그리드 1.
* **하단 (Detail Tabs)**: 영역 내에 4개의 탭을 가로로 배열하는 구조 (`data-controller="tabs"` 구성).
    * `출도착지정보` 탭: 폼 레이아웃 (Input readonly 구성)
    * `사전오더` 탭: 폼 레이아웃
    * `오더진행정보` 탭: 폼 레이아웃
    * `아이템상세` 탭: 내부에 `ag-grid` 컨테이너 배치 (목록 그리드 2)
