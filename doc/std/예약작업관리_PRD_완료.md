# Product Requirements Document (PRD): 예약작업관리

## 1. User Flow

사용자는 예약작업(배치 프로그램) 정보를 조회, 등록, 수정하기 위해 다음과 같은 흐름으로 시스템을 이용합니다.

1.  **화면 진입 (Open)**
    *   사용자가 '예약작업관리' 메뉴에 접근하면 화면이 로드됩니다.
    *   '사용여부' 등의 검색 조건 콤보박스는 기본값(전체)으로 자동 설정됩니다.
    *   예약작업주기 등의 기초 데이터(공통코드)가 로드됩니다.

2.  **목록 조회 (Search)**
    *   사용자는 상단 검색 조건(시스템구분, 예약작업명, 사용여부)을 입력하거나 선택합니다.
    *   `검색` 버튼을 클릭하면 조건에 맞는 예약작업 목록이 좌측 그리드에 표시됩니다.

3.  **상세 정보 확인 (View Detail)**
    *   좌측 목록에서 특정 예약작업을 클릭합니다.
    *   우측 상세 정보 영역에 해당 예약작업의 상세 데이터(관련 메뉴, 프로그램, 주기 등)가 바인딩됩니다.

4.  **신규 등록 (Create)**
    *   `행추가` 버튼을 클릭합니다.
    *   상세 정보 입력 필드가 초기화되며, 등록자/수정자는 현재 로그인한 사용자, 등록일시/수정일시는 현재 시스템 시간으로 자동 설정됩니다.
    *   사용여부는 자동으로 'YES'로 설정됩니다.
    *   필수 항목(시스템구분, 예약작업명 등)을 입력하고 팝업을 통해 관련 메뉴 및 프로그램을 선택합니다.
    *   `저장` 버튼을 클릭하여 DB에 저장합니다.

5.  **정보 수정 (Update)**
    *   목록에서 항목을 선택하여 상세 정보를 불러옵니다.
    *   필요한 정보를 수정한 후 `저장` 버튼을 클릭하여 변경사항을 반영합니다.
    *   수정 시 수정자명과 수정일시는 현재 로그인 정보와 시간으로 갱신됩니다.

6.  **삭제/취소 (Delete)**
    *   `행취소`(또는 행삭제) 버튼을 이용하여 신규 행을 삭제하거나, 기존 데이터의 경우 사용여부를 'No'로 변경하는 처리를 수행합니다.

---

## 2. UI Component 리스트

화면은 크게 **검색 영역(Search)**, **목록 영역(List)**, **상세 정보 영역(Detail)**으로 구성됩니다.

### 2.1 검색 영역 (Search Area)
| Component | Type | Label (Kor) | Default/Note | Source |
| :--- | :--- | :--- | :--- | :--- |
| Combo Box | Select | 시스템구분 | 전체 | |
| Text Input | Text | 예약작업명 | | |
| Combo Box | Select | 사용여부 | 전체 (초기 로딩 시 자동 선택) | |
| Button | Button | 검색 | | |

### 2.2 목록 영역 (List Area)
| Component | Type | Columns (Kor) | Note | Source |
| :--- | :--- | :--- | :--- | :--- |
| Grid/Table | ReadOnly | No, 시스템구분, 예약작업번호, 예약작업명, 사용여부 | 좌측 배치 | |
| Button | Button | 행추가 | 신규 등록 모드 전환 | |
| Button | Button | 행취소 | | |

### 2.3 상세 정보 영역 (Detail Area)
*우측에 배치되며, 필수 입력 항목(Mandatory)이 포함되어 있습니다.*

| Component | Type | Label (Kor) | Mandatory | Note | Source |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Combo Box | Select | 시스템구분 | **Yes** | | |
| Text Input | Text | 예약작업번호 | **Yes** | | |
| Text Input | Text | 관련메뉴 | | 팝업 버튼 포함 | |
| Text Input | Text | 예약작업명 | **Yes** | | |
| Text Input | Text | 예약작업 설명 | **Yes** | | |
| Text Input | Text | 관련프로그램 | | 팝업 버튼 포함 | |
| Combo Box | Select | 프로그램구분 | | 프로그램 선택 시 자동 설정 | |
| Combo Box | Select | 예약작업주기 | **Yes** | 공통코드(149번) 사용 | |
| Text Input | Text | 시간단위(분) | | | |
| Text Area | Text | 비고 | | | |
| Combo Box | Select | 사용여부 | **Yes** | 신규 시 'YES' 기본값 | |
| Text Input | ReadOnly | 등록자 | **Yes** | 로그인 사용자 자동 세팅 | |
| Text Input | ReadOnly | 등록일시 | **Yes** | DB Sysdate 자동 세팅 | |
| Text Input | ReadOnly | 수정자 | **Yes** | 로그인 사용자 자동 세팅 | |
| Text Input | ReadOnly | 수정일시 | **Yes** | DB Sysdate 자동 세팅 | |
| Button | Button | 저장 | | 데이터 Commit | |

---

## 3. Data Mapping

화면 UI 항목과 내부 데이터 속성(English ID) 간의 매핑 정보입니다.

### 3.1 Search Condition
*   **시스템구분:** `sysSctnCd`
*   **예약작업명:** `rsvWorkNmCd`
*   **사용여부:** `useYnCd`

### 3.2 List Grid
*   **시스템구분:** `sysSctn`
*   **예약작업번호:** `rsvWorkNo`
*   **예약작업명:** `rsvWorkNm`
*   **사용여부:** `useYn`

### 3.3 Detail Information
*   **시스템구분:** `sysSctnCd`
*   **예약작업번호:** `rsvWorkNoCd`
*   **관련메뉴:** `relMenuCd` (Code), `relMenuCd1` (Name/Address)
*   **예약작업명:** `rsvWorkNmCd`
*   **예약작업 설명:** `rsvWorkDescCd`
*   **관련프로그램:** `relPgmCd` (Code), `relPgmCd1` (Name)
*   **프로그램구분:** `pgmSctnCd`
*   **예약작업주기:** `rsvWorkCycleCd`
*   **시간단위(분):** `hmsUnit(분)Cd`
*   **비고:** `rmkCd`
*   **사용여부:** `useYnCd`
*   **등록자명:** `regrNmCd`
*   **등록일시:** `regDate`
*   **수정자명:** `mdfrNmCd`
*   **수정일시:** `chgdt`

---

## 4. Logic Definition

### 4.1 초기화 및 공통 로직 (Initialization)
*   **Event:** `Open`
*   **Logic:**
    *   화면 로딩 시 '사용여부' 콤보박스는 자동으로 "전체"를 선택합니다.
    *   **공통코드 연동:** 기타코드 149번(작업주기 구분)을 호출하여 '예약작업주기' 콤보박스 아이템을 구성합니다.
    *   등록일시/수정일시 기본값은 DB `sysdate`를 사용합니다.
    *   등록자/수정자 기본값은 현재 로그인한 사용자 ID를 사용합니다.

### 4.2 조회 로직 (Retrieve)
*   **목록 조회 (`예약작업목록검색`)**
    *   **Input:** 시스템구분, 예약작업명, 사용여부.
    *   **Output:** 예약작업 목록(Grid).
    *   **Logic:** 입력된 검색 조건을 기반으로 시스템에 등록된 예약작업 정보를 조회합니다.
*   **상세 조회 (`예약작업상세정보조회`)**
    *   **Trigger:** 목록 그리드에서 특정 행(Row) 클릭 시 발생.
    *   **Input:** 예약작업코드.
    *   **Output:** 상세 정보 전체 필드.
    *   **Logic:** 마스터 코드로 관리되는 상세 예약작업 정보를 조회하여 우측 영역에 바인딩합니다.

### 4.3 입력 및 수정 로직 (C/U/D)
*   **행추가 (`예약작업목록행추가`)**
    *   상세 정보의 모든 입력 필드를 초기화(Clear)합니다.
    *   **Default Setting:**
        *   사용여부: 'YES'.
        *   등록자/수정자: 로그인 ID.
        *   등록일시/수정일시: 현재 시스템 일시.
*   **저장 (`예약작업상세정보저장`)**
    *   **Logic:** 신규 등록 또는 변경된 내용을 DB에 저장합니다 (`SaveRsvWorkDtlInfoCmd`).
    *   신규 등록 시와 수정 시 모두 현재 로그인 ID와 시스템 일시로 감사(Audit) 정보를 업데이트합니다.
*   **삭제 (`예약작업목록행삭제`)**
    *   신규 행추가 데이터인 경우: 화면에서 즉시 삭제합니다.
    *   기존 DB 데이터인 경우: 데이터를 삭제하지 않고 **사용여부만 '아니오(No)'로 변경**하도록 메시지 처리 및 값을 세팅합니다.

### 4.4 팝업 연동 로직 (Popup Integration)
*   **프로그램 선택 (`프로그램선택`)**
    *   **Action:** `PgmSlcPopup.jsp` 호출.
    *   **Input:** 프로그램코드, 프로그램명.
    *   **Logic:**
        *   조회된 값이 1개일 경우 팝업 없이 즉시 세팅합니다.
        *   프로그램 선택 시 **'프로그램구분코드'**는 자동으로 설정됩니다 (기타코드 150번 참조).
*   **메뉴 선택 (`메뉴선택`)**
    *   **Action:** `MenuSlcPopup.jsp` 호출.
    *   **Input:** 메뉴코드, 주소명.
    *   **Logic:** 조회 값이 1개일 경우 팝업 없이 주소명을 화면에 표시합니다.
