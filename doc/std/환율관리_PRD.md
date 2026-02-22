# 환율관리 (Exchange Rate Management) PRD

## 1. User Flow (사용자 흐름)

사용자가 시스템에 접속하여 환율 정보를 조회, 등록, 수정, 삭제하는 전체적인 흐름입니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 환율관리 메뉴에 접근합니다.
    *   시스템은 로그인한 사용자의 국가 코드를 자동으로 설정합니다.
    *   기준일자는 현재 날짜의 전일(D-1)로 자동 설정됩니다.
    *   금융기관 정보, 화폐코드(기타코드 27번), 공시차수(기타코드 26번) 목록을 불러와 콤보박스 등을 초기화합니다.

2.  **환율 조회 (Search)**
    *   사용자는 검색 조건(국가, 금융기관, 기준일자, 공시차수)을 확인하거나 수정합니다.
    *   '검색' 버튼을 클릭합니다.
    *   시스템은 조건에 맞는 환율 목록을 그리드(Grid)에 표시합니다.

3.  **데이터 편집 (Edit Data)**
    *   **신규 등록:**
        *   '행추가' 버튼을 클릭하여 그리드에 빈 행을 생성합니다.
        *   필수 항목(화폐코드, 현찰 살때/팔때, 매매기준율 등)을 입력합니다.
    *   **수정:**
        *   조회된 목록에서 수정할 항목을 직접 클릭하여 값을 변경합니다.
    *   **삭제:**
        *   삭제할 행을 선택하고 '행삭제' 버튼을 클릭합니다.
        *   시스템은 데이터 존재 여부에 따라 완전 삭제 혹은 사용 여부('아니오') 처리를 수행합니다.

4.  **저장 (Save)**
    *   작업(추가/수정/삭제) 완료 후 '저장' 버튼을 클릭합니다.
    *   시스템은 변경된 내용을 DB에 반영하고 결과를 알립니다.

5.  **엑셀 일괄 처리 (Excel Processing)**
    *   사용자는 '양식다운'을 통해 템플릿을 받고 데이터를 작성합니다 (UI상 버튼 존재).
    *   '엑셀업로드(엑셀저장)' 버튼을 통해 작성된 환율 정보를 일괄 등록합니다.

---

## 2. UI Component 리스트

화면을 구성하는 주요 UI 요소들의 명세입니다.

### 2.1 검색 영역 (Search Area)
| UI 요소명 | 타입 | 필수 여부 | 설명 및 기본값 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **국가 (Country)** | Input / Popup | 필수 | 로그인 사용자 국가 자동 셋팅. 돋보기 아이콘 클릭 시 국가선택 팝업 호출. | ReadOnly, 수정 시 팝업 이용 |
| **국가명** | Input | 필수 | 국가 선택 시 연동되어 표시. | ReadOnly |
| **금융기관 (Financial Org)** | Select Box | 필수 | 해당 국가의 금융기관 정보(TB_CM02020) 로드. | |
| **기준일자 (Standard Date)** | Date Picker | 필수 | 기본값: `Sysdate - 1` (현재일-1일). | Format: YYYY-MM-DD |
| **공시차수 (Degree)** | Select Box | 필수 | 기타코드 26번 정보 로드 (최초/최종 등). | |
| **검색 버튼** | Button | - | 환율 목록 조회 실행. | |

### 2.2 목록 영역 (Grid List Area)
| UI 요소명 | 타입 | 필수 여부 | 설명 |
| :--- | :--- | :--- | :--- |
| **No** | Text | - | 행 번호 표시. |
| **국가코드/국가명** | Text | - | |
| **기준일자** | Text | - | |
| **금융기관코드/명** | Text | - | |
| **공시차수** | Text | - | |
| **화폐코드 (Money Code)** | Select/Input | **필수** | 기타코드 27번 참조. |
| **현찰사실때 (Cash Buying)** | Number | **필수** | |
| **현찰파실때 (Cash Selling)** | Number | **필수** | |
| **송금보내실때** | Number | 선택 | |
| **송금받으실때** | Number | 선택 | |
| **T/C사실때** | Number | 선택 | |
| **외화수표파실때** | Number | 선택 | |
| **매매기준율 (Standard Rate)** | Number | **필수** | |
| **환가료율** | Number | 선택 | |
| **미화환산율** | Number | 선택 | |
| **인터페이스여부** | Select (Y/N) | **필수** | |

### 2.3 하단 버튼 영역 (Bottom Action Bar)
| UI 요소명 | 타입 | 설명 |
| :--- | :--- | :--- |
| **양식다운** | Button | 엑셀 업로드용 양식 다운로드 (화면설계서 이미지 참조). |
| **엑셀업로드** | Button | 작성된 엑셀 파일을 서버 DB에 일괄 저장 (소스상 명칭: 엑셀저장). |
| **행추가** | Button | 그리드에 신규 입력 행 추가. |
| **행삭제** | Button | 선택된 행 삭제 처리 (상태값 변경). |
| **저장** | Button | 변경된 데이터(추가/수정/삭제)를 최종 DB 반영. |

---

## 3. Data Mapping

UI 항목과 백엔드 데이터 모델(또는 변수명) 간의 매핑 정보입니다.

| 한글 항목명 | 영문 항목명 (Eng Name) | 영문 속성명 (Variable ID) | 속성 | 필수 |
| :--- | :--- | :--- | :--- | :--- |
| 국가 | Country | `ctryCd` | Editable | **M** |
| 국가명 | CountryName | `ctryNm` | Editable | **M** |
| 금융기관 | FinancialOrganization | `fncOrCd` | Editable | **M** |
| 기준일자 | StandardYyyymmdd | `stdYmd` | Editable | **M** |
| 공시차수 | AnnouncementDegreeCount | `annoDgrcnt` | Editable | **M** |
| 화폐코드 | MoneyCode | `monCd` | Editable | **M** |
| 현찰사실때 | CashBuying | `cashBuy` | Editable | **M** |
| 현찰파실때 | CashSelling | `cashSell` | Editable | **M** |
| 송금보내실때 | SendMoneySending | `sendmoneySndg` | Editable | - |
| 송금받으실때 | SendMoneyReceiveing | `sendmoneyRcvng` | Editable | - |
| T/C사실때 | T/CBuying | `t/CBuy` | Editable | - |
| 외화수표파실때 | ForeignCurrencyCheckSelling | `fcurCheckSell` | Editable | - |
| 매매기준율 | TradingStandardRate | `tradgStdRt` | Editable | **M** |
| 환가료율 | ConversionMoneyRate | `convmoneyRt` | Editable | - |
| 미화환산율 | UsdConversionRate | `usdConvRt` | Editable | - |
| 인터페이스여부 | InterfaceYesOrNo | `ifYnCd` | Editable | **M** |

---

## 4. Logic Definition

화면의 주요 기능 동작에 대한 로직 상세 정의입니다.

### 4.1 초기화 로직 (Initialization)
*   **이벤트명:** Open
*   **국가 설정:** 로그인한 사용자의 국가 코드를 `ctryCd`에 자동 할당합니다.
*   **날짜 설정:** 기준일자(`stdYmd`)는 DB 상의 시스템 날짜(sysdate) 기준 **전일(1일 전)**로 자동 셋팅합니다.
*   **데이터 로드:**
    *   해당 국가에 속한 금융기관 목록(TB_CM02020)을 조회합니다.
    *   화폐코드(기타코드 27번)와 공시차수(기타코드 26번) 공통코드를 조회하여 콤보박스에 바인딩합니다.

### 4.2 조회 로직 (Search Logic)
*   **이벤트명:** 환율목록검색 (Click)
*   **Input:** 환율관리 찾기 조건 (국가, 금융기관, 기준일자, 공시차수)
*   **Process:** 입력된 조건을 바탕으로 시스템에서 관리하는 환율 정보를 검색합니다.
*   **Output:** 환율코드, 환율명, 사용여부 등 목록 데이터 반환.

### 4.3 삭제 로직 (Delete Logic)
*   **이벤트명:** 환율행삭제 (Click)
*   **Process:**
    1.  선택된 환율 목록 데이터를 확인합니다.
    2.  **데이터 완전 삭제:** 해당 데이터가 환율 정보를 가지고 있지 않다면(참조 무결성 제약이 없다면) 레코드를 삭제합니다.
    3.  **논리적 삭제:** 만약 화주코드(또는 타 데이터)와 연관되어 있다면, 데이터를 삭제하지 않고 **사용여부(Use Y/N) 값만 '아니오(N)'**로 업데이트합니다.
    *   *비고:* 기준정보 데이터이므로 레코드 자체의 무분별한 삭제는 제한됩니다.

### 4.4 저장 로직 (Save Logic)
*   **이벤트명:** 환율목록정보저장 (Click)
*   **Input:** 그리드 내의 모든 변경 데이터 (화폐코드, 각 환율 수치, 등록/수정자 정보 등).
*   **Process:**
    *   **신규 등록 시:**
        *   등록자명/등록일시, 수정자명/수정일시를 '현재 로그인 ID'와 '현재 시스템 일시'로 저장합니다.
    *   **수정 시:**
        *   수정자명/수정일시를 '현재 로그인 ID'와 '현재 시스템 일시'로 업데이트합니다.
*   **Output:** DB 저장 결과 반환 (SaveExchrtListInfoCmd).

### 4.5 엑셀 업로드 로직 (Excel Upload Logic)
*   **이벤트명:** 환율목록엑셀저장 (Click)
*   **Process:** 금융기관에서 제공되는 환율정보 포맷으로 작성된 엑셀 파일을 읽어, 서버 DB에 일괄 등록(Insert)합니다.
