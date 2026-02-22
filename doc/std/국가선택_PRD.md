# PRD: 국가선택 팝업 (Country Selection Popup)

| 항목 | 내용 |
| :--- | :--- |
| **화면명** | 국가선택 팝업 |
| **목적** | 사용자가 국가를 검색하고 선택하여 부모 창(Calling Program)에 정보를 전달하기 위함 |

## 1. User Flow
사용자가 팝업에 진입하여 국가 정보를 검색하고 선택하여 완료하기까지의 흐름입니다.

1.  **팝업 진입 (Open)**
    *   부모 창에서 국가 조회 조건을 넘겨받아 팝업이 호출됩니다.
    *   기본 조건(사용여부 등)에 따라 초기 국가 목록이 조회됩니다.
2.  **조건 입력 및 검색**
    *   사용자는 `국가코드`, `국가명`, `사용여부` 등 조회 조건을 변경하거나 입력합니다.
    *   [검색] 버튼을 클릭합니다.
3.  **목록 확인**
    *   조회 조건에 일치하는 국가 정보 목록(그리드)을 확인합니다.
4.  **국가 선택**
    *   원하는 국가 행(Row)을 선택(클릭/더블클릭)합니다.
5.  **정보 전달 및 종료**
    *   선택된 국가의 정보(코드, 명칭 등)가 부모 창으로 전달됩니다.
    *   팝업 창이 닫힙니다.

## 2. UI Component 리스트
화면 레이아웃에 배치되는 주요 UI 요소와 속성 정의입니다.

### 2.1 조회 영역 (Search Condition)
| Label (Kor) | Component Type | Field Name (Eng) | 속성 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **국가코드** | Input Text | `ctryCd` | Editable | UN CODE 2자리 기준 |
| **국가명** | Input Text | `ctryNm` | Editable | |
| **사용여부** | Select Box (Combo) | `useYn` | Editable | 기본값: 'Y' (사용중) |
| **검색** | Button | - | - | 조회 이벤트 트리거 |

### 2.2 목록 영역 (Grid List)
| Header (Kor) | Component Type | Field Name (Eng) | 속성 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **국가코드** | Text / Column | `ctryCd` | ReadOnly | |
| **국가명** | Text / Column | `ctryNm` | ReadOnly | |
| **국가 영문명** | Text / Column | `ctryEngNm` | ReadOnly | |
| **국가지역코드** | Text / Column | `ctryArCd` | ReadOnly | |

### 2.3 하단 버튼 영역 (Footer)
| Label (Kor) | Component Type | Action | 비고 |
| :--- | :--- | :--- | :--- |
| **닫기** | Button | `Close` | 팝업 종료 |

*(참고: 부모 창으로 전달하기 위한 '선택' 동작은 그리드 더블클릭 또는 별도 선택 버튼을 통해 수행됩니다.)*

## 3. Data Mapping
화면에서 처리되는 데이터 항목과 속성 매핑 정보입니다.

| 한글명 | 영문명 (ID) | Data Type | I/O | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| **국가코드** | `ctryCd` | String (2) | In/Out | UN Code 2자리 표준 사용 |
| **국가명** | `ctryNm` | String | In/Out | 국가의 명칭 |
| **사용여부** | `useYn` | Char (1) | In | 'Y'(예), 'N'(아니오), 또는 전체 |
| **국가 영문명** | `ctryEngNm` | String | Out | 국가의 영문 명칭 |
| **국가지역코드** | `ctryArCd` | String | Out | 국가 지역 분류 코드 |

## 4. Logic Definition
각 이벤트 및 기능에 대한 상세 업무 규칙과 로직입니다.

### 4.1 초기화 및 조회 로직 (Open & Display)
*   **Default Setting**:
    *   호출 프로그램(부모 창)에서 넘겨받은 파라미터를 조회 조건에 기본 세팅합니다.
    *   `사용여부` 파라미터 값이 없을 경우, 기본값은 **'Y' (사용)** 로 설정하여 사용 중인 코드만 조회되도록 합니다.
    *   `사용여부`는 수정 가능하여 'N' 또는 전체 조회가 가능해야 합니다.
*   **Auto Search**:
    *   화면 오픈 시 넘겨받은 조회 조건에 해당하는 국가 정보를 즉시 그리드에 Display 합니다.

### 4.2 조회 이벤트 (Search)
*   **Trigger**: [검색] 버튼 클릭
*   **Process**:
    *   입력된 `국가코드`, `국가명`, `사용여부`를 조건으로 데이터베이스에서 국가 정보를 조회합니다.
    *   종합물류에서 사용하는 통합 관리 국가 코드(UN CODE 2자리)를 기준으로 합니다.

### 4.3 선택 및 종료 로직 (Select & Close)
*   **Trigger**: 그리드 내 국가 항목 선택 (또는 선택 버튼 클릭)
*   **Process**:
    *   사용자가 선택한 행(Row)의 `국가코드`, `국가명`, `국가 영문명`, `국가지역코드` 데이터를 추출합니다.
    *   추출된 데이터를 부모 창(Calling Program)으로 전달(Return)합니다.
    *   데이터 전달 후 현재 팝업 창을 닫습니다.

### 4.4 닫기 로직 (Close)
*   **Trigger**: [닫기] 버튼 클릭
*   **Process**:
    *   별도의 데이터 전달 없이 팝업 화면을 닫습니다.
