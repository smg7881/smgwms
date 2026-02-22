# PRD: 매출입항목관리 (Sales & Purchase Item Management)

## 1. User Flow
사용자가 매출입 항목을 조회, 등록, 수정하는 전체적인 흐름입니다.

1.  **화면 진입 (Open)**
    *   사용자가 메뉴를 통해 화면에 접속합니다.
    *   시스템은 초기화 로직(콤보박스 바인딩, 기본 법인 설정)을 수행합니다.
2.  **항목 검색 (Search)**
    *   사용자가 조회 조건(법인, 매출입 구분, 매출입항목명)을 입력합니다.
    *   [검색] 버튼을 클릭하여 매출입항목 목록을 조회합니다.
3.  **상세 정보 조회 (View Detail)**
    *   좌측 '매출입항목 목록' 그리드에서 특정 항목을 선택합니다.
    *   우측 '매출입항목 상세정보' 영역에 해당 항목의 상세 데이터가 바인딩됩니다.
4.  **신규 등록 (Create New)**
    *   [신규] 버튼을 클릭합니다.
    *   상세 정보 입력 폼이 초기화되며, 신규 등록을 위한 기본값(사용여부 YES, 등록자/일시 등)이 설정됩니다.
    *   필요한 상세 정보를 입력합니다.
    *   [저장] 버튼을 클릭하여 DB에 신규 항목을 생성합니다.
5.  **정보 수정 (Update)**
    *   목록에서 항목 선택 후 상세 정보 내용을 변경합니다.
    *   [저장] 버튼을 클릭하여 변경 사항을 DB에 반영합니다.

---

## 2. UI Component 리스트
화면 레이아웃은 크게 조회 영역, 목록 영역(Left), 상세 정보 영역(Right)으로 구분됩니다.

### 2.1 조회 영역 (Header)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| **Input w/ Popup** | 법인 (Corp) | Text + Button | 법인코드/법인명 입력 및 팝업 검색 (공통 팝업 사용) |
| **Dropdown** | 매출입 구분 | Combo Box | 기타코드 128번(거래명세서유형) 바인딩 |
| **Input** | 매출입항목명 | Text | 검색할 항목명 입력 |
| **Button** | 검색 | Button | 조회 이벤트 트리거 |

### 2.2 목록 영역 (Left Block)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| **Grid/Table** | 매출입항목 목록 | Data Grid | 검색 결과 리스트 표시 |
| - Column | 매출입항목코드 | Text (Read-only) | |
| - Column | 매출입항목명 | Text (Read-only) | |
| - Column | 사용여부 | Text (Read-only) | YES/NO 표시 |

### 2.3 상세 정보 영역 (Right Block)
| Component | Label | Type | Mandatory | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Input** | 법인 | Text (Read-only) | - | 선택된 법인명 표시 |
| **Input** | 매출입항목코드 | Text | Y | 신규 시 자동 채번 (Max값) |
| **Input** | 매출입항목명 | Text | Y | |
| **Input** | 단축명 | Text | Y | |
| **Input** | 매출입항목영문명 | Text | Y | |
| **Dropdown** | 매출여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 매입여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 운송여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 국제물류항공여부 | Combo Box | N | 선택 (YES/NO) |
| **Dropdown** | 보관여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 하역여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 국제물류해운여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 할인할증여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 세금대납여부 | Combo Box | Y | 선택 (YES/NO) |
| **Input w/ Popup** | 상위매출입항목코드 | Text + Button | Y | 상위 항목 지정 |
| **Dropdown** | 매출차변계정 | Combo Box | Y | 기타코드 157번 바인딩 |
| **Dropdown** | 매출대변계정 | Combo Box | Y | 기타코드 157번 바인딩 |
| **Dropdown** | 매입차변계정 | Combo Box | Y | 기타코드 157번 바인딩 |
| **Dropdown** | 매입대변계정 | Combo Box | Y | 기타코드 157번 바인딩 |
| **Dropdown** | 시스템구분코드 | Combo Box | Y | 기타코드 25번 바인딩 |
| **Dropdown** | LUMPSUM 여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 미확정매출대변계정 | Combo Box | Y | 기타코드 157번 바인딩 |
| **Dropdown** | 미연계등록허용여부 | Combo Box | Y | 선택 (YES/NO) |
| **Dropdown** | 사용여부 | Combo Box | Y | 기타코드 06번 바인딩 |
| **Dropdown** | 미확정원가차변계정 | Combo Box | Y | 기타코드 157번 바인딩 |
| **Input** | 비고 | Text | Y | |
| **Info Display** | 등록자 / 등록일시 | Text | Y | 시스템 자동 입력 |
| **Info Display** | 수정자 / 수정일시 | Text | Y | 시스템 자동 입력 |
| **Button** | 신규 | Button | - | 입력 폼 초기화 및 신규 모드 전환 |
| **Button** | 저장 | Button | - | 데이터 저장 (Insert/Update) |

---

## 3. Data Mapping
화면의 필드와 데이터 속성 간의 매핑 정의입니다.

### 3.1 조회 조건 (Condition)
*   `corpCd`: 법인코드
*   `corpNm`: 법인명
*   `sellbuySctnCd`: 매출입 구분
*   `sellbuyAttrNmCd`: 매출입항목명

### 3.2 상세 정보 (Detail Info)
*   **기본 정보**
    *   `sellbuyAttrCd`: 매출입항목코드
    *   `sellbuyAttrNmCd`: 매출입항목명 (상세용)
    *   `rdtnNmCd`: 단축명
    *   `sellbuyAttrEngNmCd`: 매출입항목영문명
    *   `upperSellbuyAttrCd`: 상위매출입항목코드
    *   `sysSctnCd`: 시스템구분코드
    *   `rmkCd`: 비고
    *   `useYnCd`: 사용여부
*   **속성 플래그 (Flags)**
    *   `sellYnCd`: 매출여부
    *   `purYnCd`: 매입여부
    *   `tranYnCd`: 운송여부
    *   `fisAirYnCd`: 국제물류항공여부
    *   `strgYnCd`: 보관여부
    *   `cgwrkYnCd`: 하역여부
    *   `fisShpngYnCd`: 국제물류해운여부
    *   `dcExtrYnCd`: 할인할증여부
    *   `taxPayforYnCd`: 세금대납여부
    *   `lUMPSUMYnCd`: LUMPSUM 여부
    *   `dcnctRegPmsYnCd`: 미연계등록허용여부
*   **회계 계정 (Accounts)**
    *   `sellDrAcctCd`: 매출차변계정
    *   `sellCrAcctCd`: 매출대변계정
    *   `purDrAcctCd`: 매입차변계정
    *   `purCrAcctCd`: 매입대변계정
    *   `ndcsnSellCrAcctCd`: 미확정매출대변계정
    *   `ndcsnCostDrAcctCd`: 미확정원가차변계정
*   **Audit Info**
    *   `regrCd` (등록자), `regDate` (등록일시)
    *   `mdfrCd` (수정자), `chgdt` (수정일시)

---

## 4. Logic Definition
화면 동작 및 데이터 처리를 위한 상세 로직입니다.

### 4.1 초기화 로직 (Initialize)
*   **공통 코드 바인딩:**
    *   사용여부: 기타코드 **06번** (기본값 '전체')
    *   계정과목(매출/매입 차대변 등): 기타코드 **157번**
    *   시스템구분코드: 기타코드 **25번**
    *   매출입구분(조회조건): 기타코드 **128번** (거래명세서유형)
*   **기본값 설정:**
    *   로그인 사용자의 법인 정보로 조회 조건을 셋팅한다.

### 4.2 조회 로직 (Search)
*   입력된 조건(`corpCd`, `sellbuySctnCd`, `sellbuyAttrNmCd`)을 기준으로 시스템 관리 매출입항목을 검색한다.
*   조회된 목록을 Grid에 바인딩한다.

### 4.3 상세 조회 로직 (Detail Retrieve)
*   목록에서 선택된 `sellbuyAttrCd`를 Key로 사용하여 상세 정보를 조회한다.
*   조회된 데이터를 우측 상세 폼에 매핑한다.

### 4.4 신규 로직 (New)
*   **Form Clear:** 모든 입력 필드를 초기화한다.
*   **기본값 설정:**
    *   `사용여부`: **YES** 로 자동 설정
    *   `등록자/수정자`: 현재 로그인 사용자 ID
    *   `등록일시/수정일시`: 현재 시스템 시간 (DB sysdate)
    *   각종 여부 플래그(매출/매입/운송 등): "선택" 상태로 표시
*   **상위항목 설정:** 신규 버튼 클릭 시점의 목록에서 선택되어 있던 항목의 코드를 `상위매출입항목코드`로 자동 등록한다.

### 4.5 저장 로직 (Save)
*   **Validation:** 필수 입력 항목(M) 확인.
*   **채번 규칙:** 신규 등록 시 `매출입항목코드`는 **MAX 값**으로 자동 채번한다.
*   **Mode 구분:**
    *   **신규(Insert):** 등록자/등록일시/수정자/수정일시를 현재 정보로 저장.
    *   **수정(Update):** 수정자/수정일시를 현재 정보로 갱신하여 저장.
*   **코드 속성:** V4 무의미 코드를 사용한다.

### 4.6 팝업 연동 로직
*   **법인선택:** `CorpSlcPopup.jsp` 호출. 결과가 1건일 경우 팝업 없이 즉시 셋팅.
*   **매출입항목선택:** `SellbuyAttrSlcPopup.jsp` 호출 (상위항목 등 선택 시). 결과가 1건일 경우 즉시 셋팅.
