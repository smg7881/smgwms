# PRD: 결재요청승인 팝업 (Approval Request/Approval Popup)

## 1. User Flow (화면 흐름)
본 화면은 시스템 내 결재 프로세스를 처리하기 위한 팝업으로, 사용자의 역할(요청자 vs 승인자)에 따라 분기 처리됩니다.

1.  **진입 (Entry)**
    *   부모 화면(결재 목록 등)에서 결재 요청 또는 승인 버튼 클릭 시 팝업 오픈.
2.  **초기화 및 분기 (Initialization)**
    *   **Open Event**: 로그인 ID를 체크하여 화면 모드 결정.
        *   **Case A (요청자):** 결재 요청 모드로 진입.
        *   **Case B (승인자):** 결재 승인 모드로 진입.
    *   기초 데이터 로딩: 법인, 메뉴명, 결재 정보, 공통코드(28: 결재유형, 99: 결재상태) 로딩.
3.  **사용자 상호작용 (Interaction)**
    *   **결재자 변경**: '결재자변경' 필드 옆 [찾기] 버튼 클릭 → `공통.사용자선택 팝업` 오픈 → 사용자 선택 후 복귀.
    *   **정보 입력**: 결재요청내용(요청자) 또는 결재의견(승인자) 입력.
    *   **상태 변경**: 결재상태코드 드롭다운 선택.
4.  **종료 (Exit)**
    *   **요청(저장)**: [요청] 버튼 클릭 → 데이터 저장 → 부모 창 값 전달 → 팝업 닫기.
    *   **승인(저장)**: [승인] 버튼 클릭 → 데이터 저장 → 부모 창 값 전달 → 팝업 닫기.
    *   **취소**: [닫기] 버튼 클릭 → 빈 값 전달 → 팝업 닫기.

## 2. UI Component List
화면은 크게 **기본 정보 영역**, **결재 처리 영역**, **Action 버튼 영역**으로 구성됩니다.

### 2.1 기본 정보 영역 (Read-only 위주)
| UI 요소명 | 속성 | 비고 |
| :--- | :--- | :--- |
| **법인코드** | Input (Read-only) | 법인명 병기 (예: 0001 엘지이지로지스) |
| **메뉴명** | Input (Read-only) | 예: 매출계약관리 |
| **결재요청번호** | Input (Read-only) | Unique ID |
| **결재요청자** | Input (Read-only) | 요청자명 표시 |
| **지정결재자** | Input (Read-only) | 현재 지정된 결재자 |
| **등록일시/수정일시** | Text Display | DB sysdate 표시 |

### 2.2 결재 처리 영역 (Input/Action)
| UI 요소명 | 컴포넌트 타입 | 설명 |
| :--- | :--- | :--- |
| **결재자변경** | Input + Button | 결재선을 변경할 때 사용. 우측에 [찾기(돋보기)] 버튼 포함 |
| **결재요청내용** | TextArea | 결재 요청 사유 등 내용 입력 (필수) |
| **결재요청일자** | Input (Read-only) | 요청 시점의 날짜/시간 등장 |
| **결재의견** | TextArea | 승인/반려 시 의견 입력 |
| **결재승인일자** | Input (Read-only) | 승인 시점의 날짜/시간 |
| **결재상태코드** | Select Box (Combo) | 공통코드(99) 바인딩 (예: 결재요청) |
| **결재유형코드** | Input (Read-only) | 공통코드(28) 바인딩 (예: 코드승인) |

### 2.3 Action 버튼 영역
| 버튼명 | 설명 |
| :--- | :--- |
| **요청** | 결재 요청 처리 및 저장 |
| **승인** | 결재 승인 처리 및 저장 |
| **닫기** | 작업 취소 및 팝업 종료 |

## 3. Data Mapping

| 한글명 | 영문명(ID) | 속성 | 필수여부 | 매핑/소스 |
| :--- | :--- | :--- | :--- | :--- |
| 법인코드 | `corpCd` | Editable(E) | **M (Mandatory)** | 부모창 전달 데이터 |
| 메뉴명 | `menuNm` | Editable(E) | **M** | 부모창 전달 데이터 |
| 결재요청번호 | `apvReqNo` | Editable(E) | **M** | Key Value |
| 결재요청자 | `apvReqr` | Editable(E) | **M** | 로그인 사용자 정보 |
| 지정결재자 | `asmtApver` | Editable(E) | **M** | - |
| 결재자변경 | `apverChg` | Editable(E) | - | 사용자 선택 팝업 결과값 |
| 사용자코드 | `userCd` | Editable(E) | - | - |
| 결재요청내용 | `apvReqConts` | Editable(E) | **M** | 사용자 입력 |
| 결재요청일자 | `apvReqYmd` | Editable(E) | - | System Date |
| 결재의견 | `apvOpi` | Editable(E) | - | 사용자 입력 |
| 결재승인일자 | `apvApvYmd` | Editable(E) | - | System Date |
| 결재상태코드 | `apvStatCd` | Editable(E) | **M** | 공통코드(99) |
| 결재유형코드 | `apvTypeCd` | Editable(E) | - | 공통코드(28) |

## 4. Logic Definition
각 이벤트 및 기능에 대한 상세 로직 정의입니다.

### 4.1 초기화 로직 (On Load)
*   **권한 체크**: 로그인한 `UserID`가 요청자인지 승인자인지 판별하여 UI 상태를 제어함.
*   **데이터 바인딩**:
    *   기타코드 28번(결재유형), 99번(결재상태) 정보를 가져와 콤보박스 등에 매핑.
    *   등록자/수정자는 현재 로그인 사용자, 등록일시/수정일시는 `DB sysdate`를 기본값으로 설정.

### 4.2 사용자 검색 로직 (User Selection)
*   **Trigger**: [결재자변경] 옆 찾기 버튼 클릭.
*   **Process**:
    *   `공통.사용자선택 팝업` 호출 (`open`).
    *   파라미터: 사용자코드, 사용자명.
    *   **예외 처리**: 조회된 사용자 결과가 1건일 경우, 팝업을 띄우지 않고 즉시 해당 값을 화면에 세팅함.
*   **Output**: 선택된 `사용자코드`, `사용자명`, `사용자ID`를 화면에 표시.

### 4.3 결재 요청 로직 (Request Action)
*   **Trigger**: [요청] 버튼 클릭.
*   **Validation**: 필수 항목(`apvReqConts` 등) 입력 여부 확인.
*   **Save Process**:
    *   테이블에 `승인자변경(apverChg)`, `요청내용(apvReqConts)`, `결재상태코드(apvStatCd)`, `결재유형코드(apvTypeCd)`를 저장.
*   **Post-Process**: 부모 창으로 결재요청정보 전달 후 팝업 종료(Self Close).

### 4.4 결재 승인 로직 (Approve Action)
*   **Trigger**: [승인] 버튼 클릭.
*   **Save Process**:
    *   테이블에 `승인자변경(apverChg)`, `결재의견(apvOpi)`, `결재상태코드(apvStatCd)`, `결재유형코드(apvTypeCd)`를 저장.
*   **Post-Process**: 부모 창으로 결재승인정보 전달 후 팝업 종료(Self Close).

### 4.5 닫기 로직 (Close Action)
*   **Trigger**: [닫기] 버튼 클릭.
*   **Process**: 저장 로직 없이 부모 창으로 빈 값(null)을 전달하고 팝업을 닫음.
