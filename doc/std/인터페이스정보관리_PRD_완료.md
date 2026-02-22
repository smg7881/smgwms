# PRD: 인터페이스 정보 관리 (Interface Information Management)

## 1. User Flow (사용자 흐름)

사용자가 시스템에 접속하여 인터페이스 정보를 조회, 등록, 수정하는 전체적인 흐름은 다음과 같습니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 화면에 진입하면 로그인한 사용자의 소속 법인이 기본값으로 설정되고, 초기 콤보박스 데이터(인터페이스 구분, 방식, 시스템 구분 등)가 로드됩니다.
2.  **정보 검색 (Search)**
    *   사용자는 검색 조건(법인, 인터페이스구분, 인터페이스명)을 입력하고 [**검색**] 버튼을 클릭합니다.
    *   좌측 '인터페이스목록' 그리드에 검색 결과가 표시됩니다.
3.  **상세 정보 조회 (View Details)**
    *   목록에서 특정 인터페이스 항목을 선택(클릭)합니다.
    *   우측 '인터페이스상세정보' 영역에 해당 항목의 상세 데이터가 바인딩됩니다.
4.  **신규 등록 (Create New)**
    *   사용자가 우측 하단의 [**신규**] 버튼을 클릭합니다.
    *   상세 정보 입력 필드가 초기화(Clear)되며, 등록자/수정자 정보가 현재 사용자 기준으로, 사용여부는 'YES'로 자동 설정됩니다.
    *   필수 및 선택 정보를 입력합니다 (필요시 돋보기 아이콘을 통해 거래처 팝업 호출).
5.  **정보 저장 (Save)**
    *   [**저장**] 버튼을 클릭합니다.
    *   유효성 검사(필수값 및 업무 규칙)를 거친 후, 데이터가 DB에 저장(Insert 또는 Update)됩니다.

---

## 2. UI Component 리스트

화면은 크게 **검색 영역(Search)**, **목록 영역(List)**, **상세 정보 영역(Detail)**으로 구분됩니다.

### 2.1 검색 영역 (Top)
| UI 요소 | 타입 | 설명/기본값 | 비고 |
| :--- | :--- | :--- | :--- |
| 법인 (Corporation) | Input/Label | 로그인한 사용자의 소속 법인 디폴트 | ReadOnly 또는 팝업 선택 가능 |
| 인터페이스구분 | Select Box | 전체/내부/외부 등 (공통코드 03번 참조) | |
| 인터페이스명 | Text Input | 검색할 인터페이스 명칭 입력 | |
| 검색 버튼 | Button | `SearchIfListCmd` 이벤트 트리거 | |

### 2.2 인터페이스 목록 영역 (Left)
| UI 요소 | 타입 | 설명 | 비고 |
| :--- | :--- | :--- | :--- |
| Grid/Table | Table | 조회된 인터페이스 목록 표시 | |
| (Column) 인터페이스코드 | Text | `ifCd` | ReadOnly |
| (Column) 인터페이스명 | Text | `ifNm` | ReadOnly |
| (Column) 사용여부 | Text | `useYn` (YES/NO) | ReadOnly |

### 2.3 인터페이스 상세 정보 영역 (Right)
| UI 요소 | 타입 | 설명 | 필수여부 |
| :--- | :--- | :--- | :--- |
| 법인코드 | Input | `corpCd` | **Mandatory** |
| 인터페이스코드 | Input | `ifCd` (신규 저장 시 자동 채번) | **Mandatory** |
| 인터페이스방식 | Select Box | `ifMethCd` (공통코드 148번) | **Mandatory** |
| 인터페이스구분 | Select Box | `ifSctnCd` (내부/외부 등) | **Mandatory** |
| 인터페이스명 | Input | `ifNmCd` | **Mandatory** |
| 송신시스템 | Select Box | `sendSysCd` (공통코드 25번) | Conditional (내부일 때 필수) |
| 수신시스템 | Select Box | `rcvSysCd` (공통코드 25번) | Conditional (내부일 때 필수) |
| 송수신구분 | Select Box | `RcvSctnCd` (공통코드 163번) | Optional |
| 사용여부 | Select Box | `useYnCd` (기본값: 예) | Optional |
| 인터페이스거래처코드 | Input + SearchBtn | `ifBzacCd` (거래처 팝업 연동) | Conditional (내부 아닐 때 필수) |
| 거래처명 | Input | `bzacNm` | Optional |
| 거래처시스템명 | Input | `bzacSysNmCd` | Conditional (내부 아닐 때 필수) |
| 인터페이스설명 | Text Area/Input | `ifDescCd` | Optional |
| 등록자/수정자 정보 | Label | 등록자명, 등록일시, 수정자명, 수정일시 | ReadOnly (시스템 자동 할당) |
| 신규/저장 버튼 | Button | `신규`, `저장` 액션 트리거 | 우측 하단 배치 |

---

## 3. Data Mapping

화면 UI 항목과 내부 데이터 속성(변수명) 간의 매핑 정의입니다.

| 한글 항목명 | 영문 항목명 (Variable) | 속성 (Type) | 매핑 소스/설명 |
| :--- | :--- | :--- | :--- |
| **[Search]** | | | |
| 법인코드 | `corpCd` | String | 사용자 세션 또는 입력값 |
| 인터페이스구분 | `ifSctnCd` | String | 검색 조건 |
| 인터페이스명 | `ifNmCd` | String | 검색 조건 |
| **[List]** | | | |
| 인터페이스코드 | `ifCd` | String | 목록 출력용 |
| 인터페이스명 | `ifNm` | String | 목록 출력용 |
| 사용여부 | `useYn` | String | 목록 출력용 |
| **[Detail]** | | | |
| 법인코드 | `corpCd` | String | 상세 정보 (Editable) |
| 인터페이스코드 | `ifCd` | String | V10자리, Max+1 채번 |
| 인터페이스방식 | `ifMethCd` | String | 상세 정보 |
| 인터페이스구분 | `ifSctnCd` | String | 상세 정보 |
| 인터페이스명 | `ifNmCd` | String | 상세 정보 |
| 송신시스템 | `sendSysCd` | String | 상세 정보 |
| 수신시스템 | `rcvSysCd` | String | 상세 정보 |
| 송수신구분 | `RcvSctnCd` | String | 상세 정보 |
| 사용여부 | `useYnCd` | String | 상세 정보 |
| 인터페이스거래처코드 | `ifBzacCd` | String | 상세 정보 |
| 거래처명 | `bzacNm` | String | 팝업 리턴값 |
| 거래처시스템명 | `bzacSysNmCd` | String | 상세 정보 |
| 인터페이스설명 | `ifDescCd` | String | 상세 정보 |
| 등록자명 | `regrNmCd` | String | 현재 로그인 ID |
| 등록일시 | `regDate` | Date/String | DB sysdate |
| 수정자명 | `mdfrNmCd` | String | 현재 로그인 ID |
| 수정일시 | `chgdt` | Date/String | DB sysdate |

---

## 4. Logic Definition

화면의 주요 기능 동작 방식과 업무 규칙에 대한 정의입니다.

### 4.1 초기화 및 공통 로직 (Initialization)
*   **공통코드 로딩:** 화면 오픈 시 다음 공통코드를 로드하여 콤보박스를 구성합니다.
    *   인터페이스구분 (기타코드 03번 거래처구분 그룹코드)
    *   인터페이스방식 (기타코드 148번)
    *   시스템구분 (기타코드 25번 - 송신/수신시스템)
    *   송수신구분 (기타코드 163번)
*   **기본값 설정:**
    *   법인코드: 로그인한 사용자의 소속 법인.
    *   등록/수정일시: DB Sysdate.
    *   등록/수정자: 현재 로그인 사용자.

### 4.2 조회 로직 (Search Logic)
*   **이벤트:** `인터페이스목록검색` (SearchIfListCmd).
*   **Input:** 인터페이스관리 검색조건 (법인, 구분, 명칭).
*   **Output:** 조건에 맞는 인터페이스 목록을 그리드에 바인딩 (인터페이스코드, 명, 사용여부).

### 4.3 신규 및 상세 조회 (New & Detail View)
*   **상세 조회:** 목록에서 행을 선택(Click)하면 `인터페이스상세정보조회`가 실행되어 우측 폼에 데이터를 채웁니다.
*   **신규 버튼:** 클릭 시 우측 폼을 Clear(초기화)합니다.
    *   단, 등록자/수정자는 현재 로그인 정보로, 사용여부는 'YES'로, 법인코드는 소속 법인으로 자동 세팅됩니다.

### 4.4 저장 및 유효성 검사 (Save & Validation)
*   **이벤트:** `인터페이스상세정보저장` (SaveIfDtlInfoCmd).
*   **ID 채번 규칙:** 인터페이스 코드는 'V' + 10자리 형식을 따르며, 조회된 MAX 코드 값에 +1 하여 생성합니다.
*   **필수값 검증 규칙 (Validation):**
    1.  **IF `인터페이스구분` == '내부' (Internal):**
        *   `송신시스템`, `수신시스템`이 **필수(Mandatory)** 항목입니다.
    2.  **IF `인터페이스구분` != '내부' (Others):**
        *   `인터페이스거래처코드`, `거래처시스템명`이 **필수(Mandatory)** 항목입니다.
*   **저장 처리:**
    *   신규 등록 시: 입력된 정보와 현재 로그인 정보(등록자/일시)를 포함하여 INSERT.
    *   수정 시: 변경된 정보와 현재 로그인 정보(수정자/일시)를 포함하여 UPDATE.

### 4.5 팝업 로직 (Popup Logic)
*   **거래처 선택:** 돋보기 아이콘 클릭 시 `공통.거래처선택 팝업`을 호출합니다.
    *   **Input:** 거래처코드, 거래처명.
    *   **Output:** 선택된 거래처코드와 이름을 화면에 매핑.
    *   **특이사항:** 조회 값이 1개일 경우 팝업 없이 즉시 매핑합니다.
