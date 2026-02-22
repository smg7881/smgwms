# 거래처관리 시스템 PRD

## 1. User Flow (화면 간 유기적 흐름)

사용자는 거래처 정보를 조회, 등록, 수정, 삭제하는 일련의 과정을 수행하며, 메인 화면은 **검색 영역(Search)**, **목록 영역(List)**, **상세 정보 탭(Tab Detail)**으로 구성됩니다.

1.  **초기 진입 (Initialization)**
    *   화면 로드 시 공통 코드(거래처구분, 그룹구분, 종류 등)를 조회하여 드롭다운(Select Box)을 초기화합니다.
    *   기본값 설정: 등록/수정일시는 현재 시스템 시간(Sysdate), 등록/수정자는 로그인한 사용자로 설정됩니다.

2.  **거래처 검색 (Search & View)**
    *   사용자가 검색 조건(거래처코드, 명, 관리법인 등)을 입력하고 `조회` 버튼을 클릭합니다.
    *   **결과 목록 표시:** 조건에 맞는 거래처 목록이 그리드(Grid)에 출력됩니다.
    *   **상세 조회:** 목록에서 특정 거래처 행(Row)을 클릭하면, 하단 탭 영역(기본정보, 추가정보, 담당자, 작업장, 변경이력)에 해당 거래처의 상세 데이터가 바인딩됩니다.

3.  **신규 등록 및 수정 (Create & Update)**
    *   **신규:** 목록 영역의 `행추가` 버튼 클릭 시 입력 폼이 초기화되며 신규 데이터를 입력할 수 있습니다.
    *   **수정:** 상세 탭의 필드 값을 수정한 후 `저장` 버튼을 클릭합니다.
    *   **팝업 활용:** 법인, 국가, 상위거래처, 담당자 등의 필드 옆 `찾기(돋보기)` 버튼 클릭 시 모달(Modal) 팝업이 호출되며, 선택한 값이 부모 창의 필드에 자동 입력됩니다.

4.  **저장 프로세스 (Save Logic)**
    *   `저장` 버튼 클릭 시 유효성 검사(필수 값, 사업자번호 포맷 등)를 수행합니다.
    *   기존 데이터 수정 시, 변경 전 데이터는 '거래처변경이력' 테이블에 자동으로 백업됩니다.

5.  **삭제 프로세스 (Delete/Soft Delete)**
    *   `삭제` 버튼 클릭 시 물리적 데이터 삭제가 아닌, `사용여부` 컬럼을 'No'로 업데이트하여 비활성화 처리합니다 (Soft Delete).

---

## 2. UI Component List (Rails 8 기반)

Rails 8의 Hotwire(Turbo, Stimulus) 생태계를 활용하여 SPA(Single Page Application)와 유사한 사용자 경험을 제공하도록 컴포넌트를 구성합니다.

### A. Layout & Structure
*   **`MainLayoutComponent`**: 전체 페이지 레이아웃 (좌측 메뉴, 헤더, 컨텐츠 영역).
*   **`SplitViewComponent`**: 상단(검색+목록)과 하단(탭 상세)을 나누는 컨테이너.

### B. Input Components (Forms)
*   **`SearchFormComponent`**: 검색 조건 입력을 위한 폼. `form_with` 헬퍼와 Turbo Stream을 사용하여 검색 결과만 부분 갱신.
    *   *Includes:* `SelectBox` (공통코드용), `TextInput`, `SearchButton`.
*   **`DetailFormComponent`**: 탭 내부의 상세 정보 입력 폼.
    *   **`AutoCompleteInput` / `ModalTriggerInput`**: 법인, 국가 등 팝업 호출이 필요한 필드. Stimulus Controller(`popup-controller`)를 연결하여 모달 제어.
    *   **`DatePickerComponent`**: 적용시작일, 종료일 등을 위한 달력 위젯.
    *   **`MaskedTextInput`**: 사업자등록번호(###-###-####) 등 포맷이 정해진 입력 필드.

### C. Data Display Components
*   **`DataGridComponent`**: 거래처 목록 표시. 정렬, 페이징 기능 포함. 행 클릭 시 하단 Turbo Frame을 타겟으로 상세 정보를 로드하도록 설정.
*   **`TabContainerComponent`**: 5개의 상세 탭(기본/추가/담당자/작업장/이력)을 관리. 클릭 시 탭 컨텐츠만 Lazy Loading(Turbo Frame) 하거나 CSS로 전환.

### D. Modal Components (Popups)
*   **`SelectionModalComponent`**: 공통 팝업(법인선택, 국가선택, 사원선택 등)을 재사용 가능한 Turbo Frame 모달로 구현.

---

## 3. Data Mapping (입력 필드 vs DB 메타데이터)

화면설계서의 영문 속성명(Variable Name)을 기준으로 DB 컬럼을 정의합니다.

### Tab 1: 거래처기본정보 (Basic Info)
| UI Label | Variable Name (DB Column) | Type | Mandatory | Description/Rule |
| :--- | :--- | :--- | :--- | :--- |
| 거래처코드 | `bzacCd` | String | **Y** | PK, 무의미 숫자 8자리 |
| 거래처명 | `bzacNmCd` | String | **Y** | |
| 관리법인 | `mngtCorpCd` | String | **Y** | 팝업 선택 |
| 사업자번호 | `bizmanNo` | String | **Y** | Format: ###-###-#### |
| 거래처구분 | `bzacSctnCd` | String | **Y** | 공통코드 |
| 거래처종류 | `bzacKindCd` | String | **Y** | 공통코드 |
| 국가 | `ctryCd` | String | **Y** | 팝업 선택 |
| 3자물류여부 | `tplLogisYnCd` | Boolean | **Y** | Default: Yes |
| 1회성여부 | `onetmBzacYnCd` | Boolean | **Y** | |
| 대표영업사원| `rptSalesEmpCd` | String | **Y** | 팝업 선택 |
| 적용시작일 | `aplyStrtDayCd` | Date | **Y** | 달력 선택 |
| 사용여부 | `useYnCd` | Boolean | **Y** | Default: Yes |

### Tab 2: 거래처추가정보 (Additional Info)
| UI Label | Variable Name (DB Column) | Type | Mandatory | Description/Rule |
| :--- | :--- | :--- | :--- | :--- |
| 인터페이스여부| `ifYnCd` | Boolean | **Y** | |
| 계열사여부 | `branchYnCd` | Boolean | **Y** | |
| 매출거래처여부| `sellBzacYnCd` | Boolean | **Y** | |
| 매입거래처여부| `purBzacYnCd` | Boolean | **Y** | |
| 부가세구분 | `vatSctnCd` | String | N | 공통코드 (기타코드 131) |
| 금융기관 | `fncOrCd` | String | N | 팝업 선택 |
| 계좌번호 | `acntNoCd` | String | N | |

### Tab 3: 거래처담당자 (Contacts) - 1:N Relation
| UI Label | Variable Name (DB Column) | Type | Mandatory | Description/Rule |
| :--- | :--- | :--- | :--- | :--- |
| 일련번호 | `seqCd` | Integer| **Y** | |
| 담당자 | `ofcrCd` | String | N | 사원 팝업 선택 |
| 이름 | `nmCd` | String | N | |
| 휴대폰번호 | `mbpNoCd` | String | N | |
| 대표여부 | `rptYnCd` | Boolean | N | 담당자 중 1명만 선택 가능 |

---

## 4. Logic Definition (비즈니스 로직)

버튼 클릭 및 이벤트 발생 시 수행해야 할 상세 로직입니다.

### A. 초기화 및 검색 로직
1.  **Open Event**:
    *   화면 진입 시 `기타코드 03(그룹구분)`, `04(거래처구분)`, `05(거래처종류)`를 로드하여 콤보박스에 바인딩합니다.
    *   `거래처 그룹 구분` 선택 시, 하위 `거래처 구분` 콤보박스는 해당 그룹에 속한 코드만 필터링되어야 합니다.
2.  **Search Trigger**:
    *   조회 버튼 클릭 시 입력된 조건을 쿼리 파라미터로 전송합니다.
    *   결과 데이터 바인딩 시 `bzacCd`(거래처코드)는 ReadOnly 상태로 표시됩니다.

### B. 상세 정보 조회 및 탭 제어
1.  **Row Selection**:
    *   목록에서 행 선택 시 `거래처상세정보조회` 트리거가 발동됩니다. `bzacCd`를 키(Key)로 하여 기본정보, 추가정보, 담당자, 작업장, 변경이력 데이터를 비동기로 조회(Fetch)합니다.

### C. 데이터 저장 (Save) 및 유효성 검사
1.  **Validation Rule**:
    *   **사업자등록번호**: 중복을 체크하되, `대표거래처` 코드가 등록된 경우에는 중복을 허용합니다.
    *   **대표담당자**: 거래처 담당자 탭 목록 중 `대표여부`가 'Yes'인 사람은 반드시 1명이어야 합니다.
2.  **Save Logic**:
    *   **INSERT (신규)**: 새로운 `bzacCd`와 함께 데이터를 생성합니다.
    *   **UPDATE (수정)**:
        *   기존 데이터가 수정되는 경우, `TB_CM04004(거래처변경이력)` 테이블에 **변경 전(Before)** 데이터를 `INSERT` 합니다. 이때 순번을 증가시켜 이력을 관리합니다.
        *   메인 테이블(기본/추가정보 등)은 **변경 후(After)** 값으로 `UPDATE` 합니다.

### D. 삭제 (Delete) 로직
1.  **Soft Delete**:
    *   사용자가 삭제를 요청하면 실제 레코드를 `DELETE` 하지 않습니다.
    *   시스템은 메시지 박스를 띄워 "사용여부 변경에 대한 정보 공유 확인"을 거친 후, 해당 레코드의 `useYnCd` 값을 'No'로 업데이트합니다.

### E. 팝업(Helper) 로직
1.  **Single/Multi Result**:
    *   법인, 국가, 사원 찾기 시 검색 결과가 1건일 경우, 팝업을 띄우지 않고 즉시 부모 창의 필드에 값을 입력합니다 (Auto-fill).
    *   검색 결과가 없거나 2건 이상일 때만 팝업 목록을 표시합니다.
