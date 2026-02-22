# PRD: 배치이력조회 (Batch History Inquiry)

## 1. User Flow
사용자가 시스템의 배치 작업 수행 이력(로그)을 조회하고 결과를 확인 및 다운로드하는 흐름입니다.

1.  **화면 진입 (Init)**
    *   사용자가 '배치이력조회' 메뉴에 접근합니다.
    *   시스템은 기본 조회 조건(오늘 날짜, 로그인 사용자 정보 등)을 자동으로 세팅합니다.
2.  **조회 조건 설정**
    *   **시스템 구분**을 선택합니다.
    *   **시스템 일자(기간)**를 달력 컴포넌트를 이용해 설정합니다.
    *   필요 시 **예약작업명**을 입력하거나 팝업을 통해 검색하여 선택합니다.
3.  **목록 조회 (Search)**
    *   [검색] 버튼을 클릭합니다.
    *   하단 그리드에 조건에 맞는 배치 이력 목록이 출력됩니다.
4.  **결과 확인 및 다운로드**
    *   조회된 배치 작업의 성공 여부, 데이터 건수, 결과 내용 등을 확인합니다.
    *   필요 시 [Excel] 버튼을 클릭하여 조회된 목록을 엑셀 파일로 다운로드합니다.

---

## 2. UI Component 리스트
화면은 크게 상단의 **조회 영역(Search Condition)**과 하단의 **목록 영역(Result List)**, 그리고 **기능 버튼**으로 구성됩니다.

### 2.1 조회 영역 (Search Condition)
| Label | UI Type | Variable Name | Description | Mandatory |
| :--- | :--- | :--- | :--- | :---: |
| **시스템구분** | ComboBox | `sysSctnCd` | 공통코드(기타코드 25번) 로딩 | Y |
| **시스템일자** | DatePicker (From) | `sysYmd` | 조회 시작일 (Format: YYYY-MM-DD) | Y |
| **~** | DatePicker (To) | `sysYmd2` | 조회 종료일 (Format: YYYY-MM-DD) | Y |
| **예약작업명** | TextInput + Popup Icon | `rsvWorkNmCd` | 작업명 직접 입력 또는 팝업 선택 | N |
| **검색** | Button | `SearchBtn` | 조회 이벤트 실행 | - |

### 2.2 목록 영역 (Result List - Grid)
| Header Name | Variable Name | Data Type | Description |
| :--- | :--- | :--- | :--- |
| **No** | - | Integer | Row Number (Index) |
| **예약작업번호** | `rsvWorkNo` | String | 예약된 작업의 고유 번호 |
| **예약작업명** | `rsvWorkNm` | String | 배치 작업의 명칭 |
| **NO** | `nO` | String | 배치 순번 (로그 ID 등) |
| **시작일시** | `strtDate` | DateTime | 배치 시작 시간 |
| **종료일시** | `endDate` | DateTime | 배치 종료 시간 |
| **성공여부** | `succYn` | String | YES / NO |
| **데이터건수** | `cnt` | Number | 처리된 데이터 건수 |
| **배치결과내용** | `batResultConts` | String | 결과 메시지 (예: 운송실행오더 생성) |
| **배치설명** | `batDesc` | String | 배치에 대한 상세 설명 |
| **오류코드** | `errCd` | String | 실패 시 발생한 오류 코드 |
| **오류설명** | `errDesc` | String | 오류에 대한 상세 내용 |

### 2.3 하단 버튼
| Label | UI Type | Event | Description |
| :--- | :--- | :--- | :--- |
| **Excel** | Button | `ExcelDownBtn` | 그리드 내용을 엑셀로 저장 |

---

## 3. Data Mapping
화면 UI 항목과 내부 데이터 속성 간의 매핑 정의입니다.

### 3.1 Input Parameter (조회 조건)
*   **sysSctnCd**: 시스템 구분 코드 (Editable, Mandatory)
*   **sysYmd**: 검색 시작일자 (Editable, Mandatory, Default: Today)
*   **sysYmd2**: 검색 종료일자 (Editable, Mandatory, Default: Today)
*   **rsvWorkNmCd**: 예약 작업명 (Editable)

### 3.2 Output Data (배치 이력 목록)
*   주요 매핑 필드:
    *   `rsvWorkNo` (ReservationWorkNumber)
    *   `rsvWorkNm` (ReservationWorkName)
    *   `nO` (NO)
    *   `user` (User)
    *   `strtDate` (StartDate)
    *   `endDate` (EndDate)
    *   `succYn` (SuccessYesOrNo)
    *   `cnt` (Count)
    *   `batResultConts` (BatchResultContents)
    *   `batDesc` (BatchDescription)
    *   `errCd` (ErrorCode)
    *   `errDesc` (ErrorDescription)

---

## 4. Logic Definition
화면의 초기화, 이벤트 처리, 유효성 검사 등에 대한 로직 정의입니다.

### 4.1 초기화 로직 (OnLoad)
1.  **날짜 세팅**: 조회 조건의 시작일(`sysYmd`)과 종료일(`sysYmd2`)을 시스템 일자(오늘 날짜)로 자동 세팅한다.
2.  **콤보박스 바인딩**:
    *   **시스템구분**: 기타코드 25번 정보를 조회하여 콤보박스에 바인딩한다.
    *   **성공여부**: 성공 여부 표기(YES/NO 등)를 위한 콤보 또는 코드 값을 세팅한다.
3.  **기본값**: 등록자/수정자는 현재 로그인한 사용자로, 등록일시/수정일시는 DB sysdate로 처리한다 (데이터 저장 시).

### 4.2 조회 로직 (Search)
1.  사용자가 [검색] 버튼 클릭 시 `SearchBatHistListCmd`를 호출한다.
2.  **Input**: 시스템구분, 시스템일자(From~To), 예약작업명을 파라미터로 전송한다.
3.  **Process**: DB에서 해당 조건에 맞는 배치 이력 접속 로그를 조회한다.
4.  **Output**: 조회된 결과를 그리드(배치이력목록)에 Display한다.

### 4.3 팝업 로직 (Popup)
1.  **달력 선택**: 날짜 입력 필드 옆의 달력 아이콘 클릭 시 달력 컴포넌트를 호출하여 날짜를 선택하게 한다.
2.  **프로그램 선택**:
    *   예약작업명 검색 시 `공통.프로그램선택` 팝업을 호출한다.
    *   **In**: 프로그램코드, 프로그램명
    *   **Out**: 프로그램코드, 프로그램명, 프로그램구분코드
    *   *예외 처리*: 조회된 값이 1개일 경우 팝업 없이 즉시 해당 값을 필드에 세팅한다.
    *   *자동 설정*: 프로그램구분코드 명은 관련 프로그램 선택 시 자동 설정되게 처리한다.

### 4.4 엑셀 다운로드 (Excel Download)
1.  [Excel] 버튼 클릭 시 현재 그리드에 조회된 `배치이력목록` 데이터를 엑셀 파일(.xls/.xlsx) 형식으로 클라이언트 PC에 저장한다.
