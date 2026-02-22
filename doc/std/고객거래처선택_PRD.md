# PRD: 고객거래처선택 팝업 (Customer Account Selection Popup)

## 1. User Flow (사용자 흐름)

사용자가 상위 화면(부모 창)에서 고객 거래처를 검색하거나 선택해야 할 때 발생하는 흐름입니다.

1.  **팝업 호출 (Open):**
    *   사용자가 부모 창에서 검색 버튼(돋보기 아이콘 등)을 클릭하여 팝업을 호출합니다.
    *   시스템은 팝업을 열고 기본 조회 조건을 설정합니다(법인코드, 거래처구분그룹, 사용여부 등).
2.  **조건 입력 및 조회 (Search):**
    *   사용자는 거래처코드, 거래처명, 사업자등록번호 등의 검색 조건을 입력하거나 콤보박스(구분 그룹, 구분, 사용여부)를 변경합니다.
    *   '검색' 버튼을 클릭합니다.
    *   시스템은 조건에 맞는 고객거래처 목록을 그리드(Grid)에 표시합니다.
3.  **거래처 선택 (Select):**
    *   사용자는 조회된 목록 중 원하는 거래처 행(Row)을 선택합니다.
    *   선택(또는 확인) 이벤트를 발생시키면, 선택된 법인 정보가 부모 창으로 전달되고 팝업이 닫힙니다.
4.  **취소/닫기 (Close):**
    *   사용자가 '닫기' 버튼을 클릭하면 아무런 동작 없이 팝업이 종료됩니다.

## 2. UI Component List (UI 컴포넌트 리스트)

화면은 크게 **조회 조건 영역(Header)**과 **결과 목록 영역(Body)**, 그리고 **기능 버튼(Footer/Header)**으로 구성됩니다.

### 2.1 조회 조건 영역 (Input Widgets)

| 항목명 (Label) | 영문명 (ID) | 컴포넌트 타입 | 속성/비고 |
| :--- | :--- | :--- | :--- |
| **거래처코드** | `bzacCd` | Text Input | Editable |
| **거래처명** | `bzacNm` | Text Input | Editable |
| **거래처구분그룹** | `bzacSctnGrpCd` | ComboBox | Choice, 공통코드(03) |
| **거래처구분** | `bzacSctnCd` | ComboBox | Choice, 공통코드(04) |
| **사용여부** | `useYn` | ComboBox | Choice (Y/N) |
| **사업자등록번호** | `bizNo` | Text Input | Editable, Format: ###-###-#### |

### 2.2 결과 목록 영역 (Data Grid)

| 항목명 (Column Header) | 영문명 (ID) | 컴포넌트 타입 | 속성/비고 |
| :--- | :--- | :--- | :--- |
| **고객거래처코드** | `custBzacCd` | Text (Label) | ReadOnly |
| **고객거래처명** | `custBzacNm` | Text (Label) | ReadOnly |
| **사업자등록번호** | `bizNo` | Text (Label) | ReadOnly |
| **고객거래처구분** | `custBzacSctn` | Text (Label) | ReadOnly |
| **담당자명** | `ofcrNm` | Text (Label) | ReadOnly |
| **대표자명** | `rptrNm` | Text (Label) | ReadOnly |
| **전화번호** | `telNo` | Text (Label) | ReadOnly |

### 2.3 버튼 (Action Buttons)

| 버튼명 | 기능 설명 | 위치 |
| :--- | :--- | :--- |
| **검색** | 입력된 조건으로 데이터 조회 (`RetrieveBzacCmd`) | 우측 상단 |
| **닫기** | 팝업 종료 | 우측 하단 |
| **선택** | 그리드에서 선택한 데이터를 부모창에 전달 (그리드 더블클릭 또는 별도 버튼) | - |

## 3. Data Mapping (데이터 매핑)

서버 통신 및 내부 로직 처리를 위한 데이터 입출력 정의입니다.

### 3.1 Input Data (Request)
조회 시 서버로 전송되는 파라미터입니다.

*   `bzacCd` (거래처코드)
*   `bzacNm` (거래처명)
*   `bzacSctnGrpCd` (거래처구분그룹)
*   `bzacSctnCd` (거래처구분)
*   `useYn` (사용여부)
*   `bizNo` (사업자등록번호)
*   *Note: 법인코드는 호출 프로그램에서 넘겨받거나 현재 사용자 법인코드를 기본으로 설정.*

### 3.2 Output Data (Response & Return)
조회 결과로 그리드에 바인딩되거나, 선택 시 부모 창으로 반환되는 데이터입니다.

*   `custBzacCd` (고객거래처코드): 종합물류에서 사용하는 매출고객과 협력사를 통합 관리하는 단위 (무의미 8자리)
*   `custBzacNm` (고객거래처명)
*   `bizNo` (사업자등록번호)
*   `custBzacSctn` (고객거래처구분)
*   `ofcrNm` (담당자명)
*   `rptrNm` (대표자명)
*   `telNo` (전화번호) / 유선전화번호

## 4. Logic Definition (로직 정의)

### 4.1 초기화 로직 (Initialize / Open Event)
화면이 열릴 때(Open) 실행되어야 하는 기본 설정입니다.
1.  **법인코드 설정:** 호출 프로그램에서 전달받은 파라미터를 우선으로 하되, 없을 경우 현재 사용자의 법인코드를 기본값으로 설정합니다.
2.  **콤보박스 초기화:**
    *   **거래처구분그룹 (`bzacSctnGrpCd`):** 공통코드 그룹 **03**번을 바인딩하며, 기본값은 '10번(고객/화주)'로 설정합니다.
    *   **거래처구분 (`bzacSctnCd`):** 공통코드 그룹 **04**번을 바인딩합니다.
    *   **사용여부 (`useYn`):** 기본값을 **'Y'**로 설정하여 사용 중인 코드만 조회되도록 합니다 (전체 조회 기능 포함).

### 4.2 조회 로직 (Search Logic)
1.  **Validation:** 사업자등록번호 입력 시 `###-###-####` 포맷을 준수해야 합니다.
2.  **Service Call:** 사용자가 입력한 조회 조건을 바탕으로 `RetrieveBzacCmd`를 호출하여 데이터를 조회합니다.
3.  **Display:** 조회된 데이터를 그리드에 매핑하여 표시합니다.

### 4.3 선택 및 종료 로직 (Select & Close Logic)
1.  **선택(Select):** 사용자가 목록에서 특정 행을 선택(클릭)하면 다음 데이터를 부모 창으로 전달하고 팝업을 닫습니다.
    *   Return Data: `고객거래처코드`, `고객거래처명`, `사업자등록번호`, `고객거래처구분`, `담당자명`, `대표자명`, `전화번호`.
2.  **닫기(Close):** 별도의 데이터 전달 없이 팝업 화면을 닫습니다.
