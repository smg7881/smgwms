# PRD: 공휴일 관리 (Holiday Management)

## 1. User Flow (사용자 흐름)

사용자가 공휴일 관리 화면에 진입하여 데이터를 조회, 생성, 수정, 저장하는 유기적인 흐름은 다음과 같습니다.

1.  **화면 진입 (Open):**
    *   사용자가 메뉴를 통해 '공휴일관리' 화면에 접속합니다.
    *   시스템은 **조회 조건(년도, 월)을 현재 시스템 일자(Sysdate)로 자동 설정**하고, 그리드 내 콤보박스(여부 값) 데이터를 초기화합니다.
2.  **조회 (Search):**
    *   사용자는 `국가코드`, `년도`, `월`을 입력하거나 수정합니다.
    *   `검색` 버튼을 클릭하면 조건에 해당하는 시스템 공휴일 목록이 그리드(Grid)에 조회됩니다.
3.  **데이터 생성 및 편집 (Edit/Create):**
    *   **토/일 자동 생성:** `토/일생성` 버튼 클릭 시, 해당 월의 토요일과 일요일 데이터가 자동으로 생성되어 목록에 표시됩니다. 이때 공휴일명(TEXT)과 여부 체크박스가 자동으로 설정됩니다.
    *   **수동 추가:** `행추가` 버튼을 클릭하여 새로운 공휴일(빈 행)을 추가하고, 일자 및 공휴일명을 직접 입력합니다.
    *   **수정:** 조회된 목록에서 공휴일명, 각종 여부(토/일/휴무/지정/행사)를 수정하거나 비고를 입력합니다.
    *   **삭제:** 불필요한 행을 선택하고 `행삭제` 버튼을 클릭하여 화면 목록에서 제거합니다.
4.  **저장 (Save):**
    *   작업이 완료되면 `저장` 버튼을 클릭합니다. 신규 등록, 수정, 삭제된 공휴일 정보가 데이터베이스에 반영됩니다.

---

## 2. UI Component List (UI 컴포넌트 리스트)

화면을 구성하는 주요 UI 요소는 다음과 같습니다.

### 2.1 조회 영역 (Search Area)
*   **Label:** 국가코드, 년도, 월
*   **Input Field (Text):**
    *   국가코드 (필수, `CountryCode`)
    *   국가명 (필수, `CountryName`) - *조회 전용(ReadOnly) 혹은 팝업 연동 가능성 있음*
    *   년도 (필수, `Year`) - Format: YYYY-MM-DD
    *   월 (필수, `Month`) - Format: YYYY-MM-DD
*   **Button:**
    *   국가코드 검색 버튼 (Pop-up trigger)
    *   검색 (Search) - 아이콘 포함 버튼

### 2.2 목록 영역 (List Area / Grid)
데이터를 나열하는 테이블(Grid) 형태입니다.
*   **Grid Columns:**
    *   **No:** 순번
    *   **일자 (`Yyyymmdd`):** 필수, 텍스트 입력 또는 달력 컴포넌트
    *   **공휴일명 (`HolidayName`):** 필수, 텍스트 입력
    *   **토요일여부 (`SaturdayYesOrNo`):** 콤보박스 또는 체크박스 (Y/N)
    *   **일요일여부 (`SundayYesOrNo`):** 콤보박스 또는 체크박스 (Y/N)
    *   **휴무일여부 (`ClosedDayYesOrNo`):** 콤보박스 또는 체크박스 (Y/N)
    *   **지정휴일여부 (`AssigmnetHolidayYesOrNo`):** 콤보박스 또는 체크박스 (Y/N)
    *   **행사일여부 (`EventDayYesOrNo`):** 콤보박스 또는 체크박스 (Y/N)
    *   **비고 (`Remark`):** 텍스트 입력

### 2.3 액션 버튼 영역 (Bottom Button Area)
*   **Button:** `행추가` (Row Add)
*   **Button:** `행삭제` (Row Delete)
*   **Button:** `토/일생성` (Create Sat/Sun)
*   **Button:** `저장` (Save)

---

## 3. Data Mapping (데이터 매핑)

화면 UI 항목과 데이터 속성(ID/변수명) 간의 매핑 정보입니다.

| 구분 | 항목명(Kor) | 항목명(Eng) | 영문속성명(ID) | 속성 | 필수 | 비고 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **조회조건** | 국가코드 | CountryCode | `ctryCd` | Editable | **Yes** | |
| | 국가명 | CountryName | `ctryNm` | Editable | **Yes** | |
| | 년도 | Year | `yy` | Editable | **Yes** | Format: YYYY-MM-DD |
| | 월 | Month | `mm` | Editable | **Yes** | Format: YYYY-MM-DD |
| **목록(Grid)** | 일자 | Yyyymmdd | `ymd` | Editable | **Yes** | Format: YYYY-MM-DD |
| | 공휴일명 | HolidayName | `holidayNmCd` | Editable | **Yes** | |
| | 토요일여부 | SaturdayYesOrNo | `satYnCd` | Editable | No | |
| | 일요일여부 | SundayYesOrNo | `sundayYnCd` | Editable | No | |
| | 휴무일여부 | ClosedDayYesOrNo | `clsdyYnCd` | Editable | No | |
| | 지정휴일여부 | AssigmnetHolidayYesOrNo | `asmtHoldayYnCd` | Editable | No | |
| | 행사일여부 | EventDayYesOrNo | `eventDayYnCd` | Editable | No | |
| | 비고 | Remark | `rmkCd` | Editable | No | |

---

## 4. Logic Definition (로직 정의)

화면의 주요 기능 동작 방식과 업무 규칙입니다.

### 4.1 초기화 및 화면 제어 (Initialization)
*   **Open Event:** 화면이 열릴 때 조회 조건의 '년도'와 '월' 값은 **시스템 일자(DB Sysdate)**를 기준으로 자동 세팅됩니다.
*   **Combo Setting:** 토/일/휴무일 등의 여부 값을 선택하기 위한 콤보박스 데이터를 로드합니다.
*   **Hidden Data:** 등록/수정 시 `등록일시`, `수정일시`는 DB Sysdate로, `등록자`, `수정자`는 현재 로그인 사용자 ID로 자동 처리됩니다.

### 4.2 조회 및 정렬 (Search & Sort)
*   **SearchHolidayListCmd:** 입력된 국가코드, 년, 월을 조건으로 시스템 공휴일 목록을 조회합니다.
*   **정렬 순서:** 조회된 데이터는 **일자별 순서대로** 정렬되어 표시됩니다.

### 4.3 토/일요일 자동 생성 (Auto-Generation Logic)
*   **CreateSatSundayCmd:** 사용자가 `토/일생성` 버튼 클릭 시 동작합니다.
*   **로직:**
    1.  해당 월의 날짜 중 토요일과 일요일을 계산합니다.
    2.  서버 DB에 해당 정보를 자동으로 저장합니다.
    3.  이때, `공휴일명` 텍스트(예: 토요일, 일요일)가 자동 입력되며, `토요일여부` 또는 `일요일여부` 체크박스가 자동으로 'Y'로 설정됩니다.
    4.  저장 후 목록을 재조회하여 화면에 표시합니다.

### 4.4 저장 및 삭제 (Save & Delete)
*   **SaveHolidayListCmd:** 신규 등록(행추가)되거나 변경된 공휴일 상세 정보를 DB에 저장합니다.
*   **Row Delete:** 선택된 레코드를 삭제 처리합니다.
*   **업무 규칙:** 공휴일명은 수작업으로 등록 가능하지만, 자동 생성된 토/일 데이터는 시스템 규칙에 따라 자동 텍스트 및 체크 처리가 우선됩니다.
