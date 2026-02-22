# 제품 요구사항 정의서 (PRD): 시스템설정관리 (System Setup Management)

## 1. User Flow (사용자 흐름)

사용자가 시스템에 로그인한 후, 본인의 환경 설정을 조회하고 수정하는 전체적인 흐름입니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 [시스템설정관리] 메뉴에 접근합니다.
    *   시스템은 로그인한 사용자의 ID를 기반으로 기존 설정 정보를 조회하여 화면에 표시합니다.
    *   *분기:* 만약 기존 설정 정보가 없다면, 사용자 기본 테이블에서 정보를 조회하여 초기값을 표시합니다.

2.  **정보 수정 (Edit Information)**
    *   **팝업 검색:** 법인, 업무담당사원, 담당영업사원, 담당권역, 국가, 기본결재자 항목 옆의 '찾기(...)' 버튼을 클릭합니다.
        *   *팝업 로직:* 팝업이 호출되며, 검색 결과가 1건일 경우 팝업 없이 즉시 입력 필드에 값이 채워지고, 다건일 경우 선택 팝업이 뜹니다.
    *   **자동 완성:** '국가' 코드가 입력/선택되면 시스템은 `TB_CM01016` 테이블을 참조하여 TIME ZONE, 표준시간, 썸머타임 정보를 자동으로 화면에 채웁니다.
    *   **수동 입력:** 썸머타임 적용 여부(체크박스), 비밀번호 변경 주기(드롭다운/입력) 등을 직접 수정합니다.
    *   **비밀번호 변경:** [변경] 버튼을 클릭하여 `비밀번호변경선택 팝업`을 호출하고 비밀번호를 재설정합니다.

3.  **저장 (Save)**
    *   모든 필수 항목(법인, 담당권역, 국가, TIME ZONE 등)이 입력되었는지 확인 후 [저장] 버튼을 클릭합니다.
    *   시스템은 변경된 내용을 DB에 저장(Insert/Update)하고 완료 메시지를 띄웁니다.

---

## 2. UI Component List (Rails 8 기반)

Rails 8의 Hotwire(Turbo, Stimulus) 생태계를 고려하여 필요한 UI 컴포넌트를 정의합니다.

### A. Layout & Container
*   **`SystemSetupForm` (Turbo Frame):** 전체 설정 폼을 감싸는 컨테이너. 저장 후 페이지 전체 리로드 없이 폼 영역만 업데이트하거나 플래시 메시지를 띄우기 위함.
*   **`SectionHeader`:** "시스템설정관리" 타이틀 및 현재 상태 표시.

### B. Input Components
1.  **`ReadOnlyTextField`**: 수정 불가능한 정보 표시용.
    *   *대상:* 사용자코드, 사용자ID, 사용자명 (로그인 세션 정보 기반).
2.  **`SearchInputGroup` (Stimulus Controller 연결)**: 텍스트 입력창과 '찾기' 버튼이 결합된 형태.
    *   *대상:* 법인, 업무담당사원, 담당영업사원, 담당권역, 국가, 기본결재자.
    *   *기능:* 검색 버튼 클릭 시 Modal(Turbo Frame) 호출.
3.  **`RemoteSelect` (Dependent Select)**: 특정 값 변경에 따라 옵션이나 내용이 비동기로 바뀌는 컴포넌트.
    *   *대상:* 국가 선택 시 TimeZone/표준시간 자동 바인딩.
4.  **`EnumSelect`**: 정해진 코드값 중 하나를 선택하는 드롭다운.
    *   *대상:* 적용환율단위, 시스템언어선택, TimeZone.
5.  **`DatePicker` (or DateField)**: 날짜 표시 및 선택.
    *   *대상:* 비밀번호 변경일자 (표시용), 등록일시/수정일시.
6.  **`Checkbox`**: Boolean 값 처리.
    *   *대상:* 썸머타임(적용여부).

### C. Action Components
*   **`ModalTriggerButton`**: 비밀번호 변경 팝업 호출용 버튼 (`PwdChgSlcPopup`).
*   **`SubmitButton`**: 폼 전송(저장) 버튼. disable_with 속성을 사용하여 중복 클릭 방지.

---

## 3. Data Mapping

화면의 UI 필드와 데이터베이스 메타데이터(Logical/Physical) 매핑 정의입니다.

| UI 항목명 (Label) | 변수명 (English) | 컬럼명 (Attribute) | 속성 | 필수 | 비고 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **사용자코드** | UserCode | `userCd` | ReadOnly | M | 로그인 세션 정보 |
| **사용자명** | UserName | `userNm` | ReadOnly | M | |
| **사용자ID** | UserID | `userID` | ReadOnly | M | |
| **법인코드** | Corporation Code | `corpCd` | Editable | M | 팝업: `CorpSlcPopup` |
| **법인명** | Corporation Name | `corpNm` | Editable | M | |
| **비밀번호변경주기** | PasswordChangeCycle | `pwdChgCycle` | Editable | M | |
| **비밀번호변경일자** | PasswordChangeYyyymmdd | `pwdChgYmd` | Editable | | |
| **업무담당사원** | BusinessChargeEmployee | `bizChrgEmp` | Editable | | 팝업: `EmpSlcPopup` |
| **담당영업사원** | ChargeSalesEmployee | `chrgSalesEmp` | Editable | | 팝업: `EmpSlcPopup` |
| **담당권역** | ChargeRegion | `chrgRegnCd` | Editable | M | 팝업: `RegnSlcPopup` |
| **국가** | Country | `ctryCd` | Editable | M | 팝업: `CtrySlcPopup` |
| **TIME ZONE** | TIMEZONE | `tIMEZONECd` | Editable | M | 국가 선택 시 자동세팅 참조 |
| **표준시간** | StandardTime | `stdtime` | Editable | | 국가 선택 시 자동세팅 참조 |
| **썸머타임** | SummerTime | - | Editable | | 사용자 직접 체크 |
| **적용환율단위** | ApplyExchangeRateUnit | `aplyExchrtUnitCd` | Editable | M | 공통코드 참조 |
| **시스템언어선택** | SystemLanguageSelect | `sysLangSlcCd` | Editable | M | 공통코드 참조 |
| **기본결재자** | BasisApprover | `basisApver` | Editable | | 팝업: `EmpSlcPopup` |
| **등록자** | Registrar | `regr` | Editable | | Default: 로그인 사용자 |
| **수정자** | Modifier | `mdfr` | Editable | | Default: 로그인 사용자 |

---

## 4. Logic Definition (상세 비즈니스 로직)

버튼 클릭 및 주요 이벤트 발생 시 실행되어야 할 상세 로직입니다.

### A. 화면 초기화 (On Load)
1.  **데이터 조회:** 로그인한 `userCd`를 키로 시스템 설정 테이블을 조회한다.
2.  **데이터 부재 시 처리:** 조회 결과가 `NULL`인 경우, 사용자 기본 정보 테이블(`TB_CM01001` 등)에서 기초 데이터를 가져와 화면에 매핑한다.
3.  **메타데이터 세팅:** 등록일시/수정일시는 `DB sysdate`, 등록자/수정자는 `로그인 사용자`로 기본값을 설정한다.

### B. 팝업 호출 및 데이터 바인딩 (Search Logic)
*   **공통 로직:** 법인, 사원, 권역, 국가 찾기 버튼 클릭 시.
    1.  각 항목에 해당하는 검색 팝업(`CorpSlcPopup`, `EmpSlcPopup`, `RegnSlcPopup`, `CtrySlcPopup`)을 호출한다.
    2.  **단건 조회 최적화:** 입력된 코드나 명칭으로 조회 시 결과가 1건이면, 팝업을 띄우지 않고 즉시 필드(`Code`, `Name`)에 값을 바인딩한다.
    3.  결과가 없거나 다건인 경우 팝업을 띄워 사용자가 선택하게 한다.

### C. 국가 코드 변경 이벤트 (Change Event)
*   **Trigger:** 국가 코드(`ctryCd`) 값이 변경되거나 팝업에서 선택되었을 때.
*   **Action:** `TB_CM01016` 테이블을 조회한다.
*   **Result:** 조회된 데이터 중 `TIME ZONE`, `표준시간`, `썸머타임` 정보를 가져와 해당 화면 필드에 자동으로 Display 한다.

### D. 비밀번호 변경 (Change Password)
*   **Trigger:** 비밀번호 변경 영역의 [변경] 버튼 클릭.
*   **Action:** `PwdChgSlcPopup`을 호출한다.
*   **Validation:** 팝업 내에서 변경 주기와 변경 일자를 확인하고, `TB_CM01001` (사용자 정보) 테이블의 비밀번호를 업데이트한다.

### E. 저장 (Save Process)
*   **Trigger:** 하단 [저장] 버튼 클릭.
*   **Validation:** 필수 항목(`M` 속성: 법인, 담당권역, 국가, 언어 등) 누락 여부 확인.
*   **Transaction:**
    1.  시스템 설정 정보를 대상 테이블에 `Insert` 또는 `Update` 한다.
    2.  `승인자변경`, `요청내용`, `환경설정상태코드`, `환경설정유형코드` 등의 로그성 데이터도 함께 저장한다.
*   **Feedback:** 저장 완료 후 성공 메시지를 출력하고 화면을 갱신한다.
