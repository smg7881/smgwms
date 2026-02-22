# PRD: 기본작업경로선택 팝업 (Basic Work Route Selection Popup)

## 1. User Flow

사용자가 메인 화면에서 작업을 수행하던 중 기본작업경로를 선택해야 할 때 진입하는 팝업 화면의 흐름입니다.

1.  **진입 (Start)**
    *   사용자가 메인 업무 화면에서 '기본작업경로' 검색 버튼을 클릭하거나 특정 이벤트를 발생시킵니다.
    *   시스템은 **기본작업경로선택 팝업**을 호출합니다.
2.  **초기화 (Initialization)**
    *   메인 화면에서 전달된 파라미터(기본작업경로, 화종, 작업유형1, 작업유형2)가 있는지 확인합니다.
    *   **파라미터가 있는 경우**: 검색 조건 필드에 값을 자동 세팅하고, 공통 모듈을 호출하여 각 코드에 해당하는 명칭(Name)을 찾아 표시합니다. 이후 자동으로 조회 로직을 수행하여 그리드에 결과를 표시합니다.
    *   **파라미터가 없는 경우**: 검색 조건이 빈 상태로 팝업이 열립니다.
3.  **검색 (Search)**
    *   사용자는 검색 조건(기본작업경로코드, 화종, 작업유형1, 2 등)을 입력 또는 수정합니다.
    *   [검색] 버튼을 클릭합니다.
    *   시스템은 조건에 맞는 '사용 중'인 기본작업경로 리스트를 조회하여 하단 그리드에 표시합니다.
4.  **선택 및 반환 (Selection & Return)**
    *   사용자는 조회된 리스트 중 하나를 선택합니다.
    *   선택된 데이터(기준작업경로, 화종, 작업유형1, 2 등)가 메인 화면으로 반환됩니다.
5.  **종료 (Close)**
    *   [닫기] 버튼을 클릭하거나 데이터를 선택하여 팝업을 종료합니다.

---

## 2. UI Component 리스트

화면설계서의 Layout 및 항목 설명을 기반으로 정의한 UI 컴포넌트입니다.

### 2.1 검색 영역 (Header)
| UI ID | 항목명(Label) | 타입 (Type) | 속성 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| `basisWorkRouteCd` | 기본작업경로코드 | InputBox | Editable | |
| `basisWorkRouteNm` | 기본작업경로명 | InputBox | Editable | |
| `hwajong` | 화종 | InputBox | Editable | 검색 아이콘 포함 |
| `hwajongNm` | 화종명 | InputBox | Editable | |
| `wrktype1` | 작업유형1 | InputBox | Editable | 검색 아이콘 포함 |
| `wrktype1Nm` | 작업유형1명 | InputBox | Editable | |
| `wrktype2` | 작업유형2 | InputBox | Editable | 검색 아이콘 포함 |
| `wrktype2Nm` | 작업유형2명 | InputBox | Editable | |
| `btn_search` | 검색 | Button | Clickable | |

### 2.2 리스트 영역 (Body - Grid)
| UI ID | 컬럼명(Header) | 타입 (Type) | 속성 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| `stdWorkRouteCd` | 기준작업경로코드 | Text | ReadOnly | |
| `stdWorkRouteNm` | 기준작업경로명 | Text | ReadOnly | |
| `hwajongCd` | 화종코드 | Text | ReadOnly | |
| `hwajongNm` | 화종명 | Text | ReadOnly | |
| `wrktype1Cd` | 작업유형1코드 | Text | ReadOnly | |
| `wrktype1Nm` | 작업유형1명 | Text | ReadOnly | |
| `wrktype2Cd` | 작업유형2코드 | Text | ReadOnly | |
| `wrktype2Nm` | 작업유형2명 | Text | ReadOnly | |

### 2.3 하단 영역 (Footer)
| UI ID | 항목명 | 타입 | 속성 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| `btn_close` | 닫기 | Button | Clickable | |

---

## 3. Data Mapping

화면의 UI 필드와 내부 데이터 속성 간의 매핑 정보입니다.

### 3.1 Input Parameter (In)
메인 화면에서 팝업 호출 시 전달받는 데이터입니다.
*   **기본작업경로코드**: `basisWorkRouteCd`
*   **화종**: `hwajong`
*   **작업유형1**: `wrktype1`
*   **작업유형2**: `wrktype2`

### 3.2 Search Conditions (Query)
조회 시 사용되는 데이터 매핑입니다.
*   **기본작업경로코드**: `basisWorkRouteCd`
*   **기본작업경로명**: `basisWorkRouteNm`
*   **화종**: `hwajong`
*   **작업유형1**: `wrktype1`
*   **작업유형2**: `wrktype2`

### 3.3 Output Data (Out)
리스트 조회 결과 및 선택 시 반환되는 데이터 구조입니다.
*   **기준작업경로코드**: `stdWorkRouteCd`
*   **기준작업경로명**: `stdWorkRouteNm`
*   **화종코드**: `hwajongCd`
*   **화종명**: `hwajongNm`
*   **작업유형1코드**: `wrktype1Cd`
*   **작업유형1명**: `wrktype1Nm`
*   **작업유형2코드**: `wrktype2Cd`
*   **작업유형2명**: `wrktype2Nm`

---

## 4. Logic Definition

화면의 주요 기능 동작 및 이벤트 처리에 대한 로직 정의입니다.

### 4.1 초기화 로직 (On Open Event)
*   **이벤트 명**: `Open`
*   **동작 내용**:
    1.  호출 화면(메인)으로부터 인자(`In-Parameter`)를 수신합니다.
    2.  수신된 `기준작업경로코드`를 검색 조건 필드(`basisWorkRouteCd`)에 세팅합니다.
    3.  수신된 `화종` 코드를 필드에 세팅하고, **공통모듈을 호출**하여 `화종명`을 조회한 뒤 화면(`hwajongNm`)에 표시합니다.
    4.  수신된 `작업유형1` 코드를 필드에 세팅하고, **공통모듈을 호출**하여 `작업유형1명`을 조회한 뒤 화면(`wrktype1Nm`)에 표시합니다.
    5.  수신된 `작업유형2` 코드를 필드에 세팅하고, **공통모듈을 호출**하여 `작업유형2명`을 조회한 뒤 화면(`wrktype2Nm`)에 표시합니다.
    6.  인자로 넘겨받은 데이터가 있을 경우, 해당 데이터를 조건으로 하여 **자동으로 조회를 수행**하고 결과를 리스트에 표시합니다.

### 4.2 조회 로직 (Search Logic)
*   **이벤트 명**: `기본작업경로조회` (Trigger: Click Search Button)
*   **입력 값**: 검색 조건 영역에 입력된 `기본작업경로조회조건`.
*   **처리 내용**:
    *   `RetrieveBasisWorkRouteCmd` 또는 `RetrieveCmd`를 실행하여 DB에서 데이터를 조회합니다.
    *   **업무 규칙**: 조회 시 기본적으로 '사용여부'가 '사용(Used)'인 데이터만 조회합니다.
*   **출력 값**: 조회된 `기본작업경로리스트`를 Grid 영역에 바인딩합니다.

### 4.3 닫기 및 반환 로직 (Close & Return Logic)
*   **이벤트 명**: `닫기`
*   **처리 내용**:
    *   단순 닫기 버튼 클릭 시 팝업을 종료합니다.
    *   리스트에서 특정 행을 선택(더블 클릭 등)했을 경우, 해당 행의 상세 데이터(Out-Parameter 참조)를 호출한 메인 화면으로 반환하고 팝업을 종료합니다.
