# PRD: 거래처선택 팝업 (Business Partner Selection Popup)

## 1. 개요
*   **화면명:** 거래처선택팝업
*   **화면 패턴:** 팝업
*   **목적:** 사용자가 검색 조건을 입력하여 거래처를 조회하고, 목록에서 특정 거래처를 선택하여 부모 창으로 정보를 전달하기 위함.

---

## 2. User Flow (화면 간의 유기적인 흐름)

1.  **진입 (Entry):**
    *   호출 프로그램(부모 창)에서 거래처 선택 이벤트를 발생시키면 팝업이 오픈된다.
    *   **Open Event:** 팝업 로드 시 기본 조회 조건(법인코드, 콤보박스 등)이 초기화된다.

2.  **조회 조건 입력 (Search Condition):**
    *   사용자는 거래처 코드, 거래처명, 사업자등록번호 등의 검색 조건을 입력한다.
    *   법인(Corporation) 변경이 필요한 경우, 돋보기 아이콘을 클릭하여 '법인선택 팝업'을 호출하고 법인 정보를 선택하여 가져온다.

3.  **조회 실행 (Execute Search):**
    *   [검색] 버튼을 클릭하거나 조회 이벤트를 실행한다.
    *   시스템은 입력된 조건을 바탕으로 거래처 정보를 조회한다 (`RetrieveBzacCmd`).

4.  **결과 확인 및 선택 (Select Result):**
    *   하단 그리드(List)에 조회된 거래처 목록이 표시된다.
    *   사용자는 목록에서 원하는 거래처 행(Row)을 선택한다.

5.  **확정 및 종료 (Confirm & Exit):**
    *   **선택:** 선택 후 [선택] 버튼(또는 더블클릭 등의 트리거)을 통해 선택된 거래처 정보(코드, 명칭 등)를 부모 창으로 반환하고 팝업을 닫는다.
    *   **닫기:** [닫기] 버튼 클릭 시, 선택 없이 팝업을 닫는다.

---

## 3. UI Component List

화면은 크게 **상단 조회 조건 영역**과 **하단 결과 목록(그리드) 영역**으로 구성됩니다.

### 3.1 조회 조건 영역 (Search Area)
| Label (한글) | Component Type | 설명 및 속성 |
| :--- | :--- | :--- |
| **거래처코드** | Text Input | `Editable`. 거래처 코드 입력. |
| **거래처명** | Text Input | `Editable`. 거래처 명칭 입력. |
| **법인** | Text Input + Button | `Editable`. 법인 코드/명 입력 및 검색 팝업 버튼 포함. |
| **거래처구분그룹** | Select Box (Combo) | `Editable`. `Choice`. 공통코드 그룹 03번 사용. |
| **거래처구분** | Select Box (Combo) | `Editable`. `Choice`. 공통코드 그룹 04번 사용. |
| **청구거래처여부** | Select Box (Combo) | |
| **사용여부** | Select Box (Combo) | `Editable`. `Choice`. 전체/Y/N 선택 (기본값 Y). |
| **사업자등록번호** | Text Input | `Editable`. Format: `###-###-####`. |
| **검색** | Button | 조회 실행 버튼. |

### 3.2 결과 목록 영역 (List/Grid Area)
| Header (한글) | Component Type | 설명 및 속성 |
| :--- | :--- | :--- |
| **거래처코드** | Data Column | `ReadOnly`. |
| **거래처명** | Data Column | `ReadOnly`. |
| **사업자등록번호** | Data Column | `ReadOnly`. |
| **거래처구분** | Data Column | `ReadOnly`. |
| **담당자명** | Data Column | `ReadOnly`. |
| **전화번호** | Data Column | `ReadOnly`. |
| **청구거래처코드** | Data Column | `ReadOnly`. |
| **닫기** | Button | 팝업 닫기 버튼. |

---

## 4. Data Mapping

### 4.1 Input Data (Search Conditions)
| Logical Name | Physical Name (ID) | Type/Length | Source/Note |
| :--- | :--- | :--- | :--- |
| 거래처코드 | `bzacCd` | String (8) | 무의미 8자리 |
| 거래처명 | `bzacNm` | String | |
| 법인 | `corp` | String (5) | 무의미 5자리 |
| 거래처구분그룹 | `bzacSctnGrpCd` | String | 공통코드(03) |
| 거래처구분 | `bzacSctnCd` | String | 공통코드(04) |
| 사용여부 | `useYn` | String (1) | Y/N |
| 사업자등록번호 | `bizNo` | String | Format: ###-###-#### |

### 4.2 Output Data (Grid List & Return Values)
검색 결과 리스트이며, 선택 시 부모 창으로 반환되는 데이터입니다.

| Logical Name | Physical Name (ID) | Source/Note |
| :--- | :--- | :--- |
| 거래처코드 | `bzacCd` | |
| 거래처명 | `bzacNm` | |
| 사업자등록번호 | `bizNo` | |
| 거래처구분 | `bzacSctn` | |
| 담당자명 | `ofcrNm` | |
| 전화번호 | `telNo` | |
| 청구거래처코드 | `bilgBzacCd` | |

---

## 5. Logic Definition

### 5.1 초기화 로직 (Initialization)
*   **Open Event:** 화면이 열릴 때 실행된다.
    *   **콤보박스 설정:**
        *   `거래처구분그룹`: 공통코드 그룹 03번 조회 및 바인딩.
        *   `거래처구분`: 공통코드 그룹 04번 조회 및 바인딩.
    *   **기본값 설정:**
        *   `법인`: 호출 프로그램에서 넘겨받은 값을 우선하되, 없을 경우 현재 사용자의 법인 코드를 기본으로 설정.
        *   `사용여부`: 'Y' (사용 중인 코드)를 기본으로 설정.

### 5.2 조회 로직 (Search Logic)
*   **이벤트:** `RetrieveBzacCmd`.
*   **입력값:** 화면의 조회 조건 항목 전체.
*   **처리:** 입력된 조건에 해당하는 거래처 정보를 데이터베이스에서 조회하여 그리드에 출력한다.

### 5.3 법인 선택 로직 (Corporation Selection)
*   **이벤트:** `CorpSlc`.
*   **처리:** `CorpPopup.jsp` (공통 법인 팝업)를 호출한다.
*   **결과:** 팝업에서 선택된 `법인코드`, `법인명`을 받아와 해당 필드에 입력한다.

### 5.4 선택 및 반환 로직 (Select & Return)
*   **이벤트:** 그리드 내 항목 선택 후 확정.
*   **처리:** 사용자가 선택한 행(Row)의 상세 정보를 부모 창(Opener)으로 전달한다.
*   **반환 데이터:** 거래처코드, 거래처명, 사업자등록번호, 거래처구분, 담당자명, 전화번호, 청구거래처코드.
*   **후처리:** 데이터 전달 완료 후 현재 팝업 창을 닫는다.
