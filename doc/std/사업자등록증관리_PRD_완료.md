# 사업자등록증관리 화면 PRD

## 1. User Flow
사용자가 사업자등록증 정보를 조회, 등록, 수정, 삭제하는 전체적인 흐름은 다음과 같습니다.

1.  **화면 진입 (Open)**
    *   사용자가 화면에 접근하면 초기화 로직이 실행됩니다.
    *   검색 조건의 콤보박스(사용여부, 복수거래처여부, 사업자여부 등)가 자동으로 세팅됩니다.
2.  **조회 (Search)**
    *   사용자가 상단 검색 조건(거래처명)을 입력하고 **[검색]** 버튼을 클릭합니다.
    *   좌측 목록(Grid)에 검색 결과가 표시됩니다.
3.  **상세 정보 확인 (View Detail)**
    *   좌측 목록에서 특정 거래처(행)를 선택(Click)합니다.
    *   우측 상세 영역에 선택된 거래처의 사업자등록증 상세 정보가 바인딩됩니다.
4.  **신규 등록 (Create)**
    *   하단의 **[행추가]** 버튼을 클릭합니다.
    *   우측 상세 영역의 입력 필드가 초기화됩니다.
    *   '사용여부'는 자동으로 'YES'로 설정되며, 등록자/수정자 정보는 현재 사용자 및 시스템 날짜로 세팅됩니다.
    *   사용자가 상세 정보를 입력하고 **[저장]** 버튼을 클릭하면 DB에 저장됩니다.
5.  **수정 (Update)**
    *   상세 조회된 상태에서 정보를 수정하고 **[저장]** 버튼을 클릭합니다.
    *   수정자명과 수정일시는 현재 로그인 정보로 갱신됩니다.
6.  **삭제 (Delete)**
    *   **[행취소/삭제]** 버튼을 클릭합니다.
    *   신규 행추가 데이터인 경우 목록에서 즉시 삭제됩니다.
    *   기존 DB 데이터인 경우 '사용여부'만 '아니오(No)'로 변경되어 저장됩니다 (Soft Delete).

---

## 2. UI Component 리스트
화면은 크게 **검색 영역(Search Area)**, **목록 영역(Left List)**, **상세 영역(Right Detail)**으로 구성됩니다.

### 2.1 검색 영역 (Top)
| 구분 | 라벨(Label) | 컴포넌트 타입 | 비고 |
| :--- | :--- | :--- | :--- |
| **Input** | 거래처명 | Text Input | 검색어 입력 |
| **Button** | 검색 | Button | 조회 실행 트리거 |

### 2.2 목록 영역 (Left Grid)
| 구분 | 헤더(Header) | 데이터 타입 | 비고 |
| :--- | :--- | :--- | :--- |
| **Grid Column** | 거래처코드 | Text (Read-only) | |
| **Grid Column** | 거래처명 | Text (Read-only) | |
| **Grid Column** | 사업자등록증 | Text (Read-only) | |
| **Grid Column** | 사용여부 | Text (Read-only) | |

### 2.3 상세 영역 (Right Detail)
| 구분 | 라벨(Label) | 컴포넌트 타입 | 필수여부 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **Input + Popup** | 거래처코드 | Text Input + Search Icon | **Mandatory** | 거래처선택 팝업 연동 |
| **Input** | 거래처명 | Text Input | Read-only | 팝업 선택 시 자동 입력 |
| **Input** | 사업자등록증 | Text Input | **Mandatory** | Format: ###-###-#### |
| **Combo** | 사업자여부 | Dropdown (Select) | **Mandatory** | 사업/개인 |
| **Input** | 상호명 | Text Input | **Mandatory** | |
| **Input** | 대표자명 | Text Input | **Mandatory** | |
| **Input** | 법인등록번호 | Text Input | **Mandatory** | |
| **Input** | 업태 | Text Input | **Mandatory** | |
| **Input** | 업종 | Text Input | **Mandatory** | |
| **Combo** | 복수거래처여부 | Dropdown (Select) | **Mandatory** | |
| **Input + Popup** | 우편주소 | Text Input + Search Icon | **Mandatory** | 우편번호선택 팝업 연동 |
| **Input** | 상세주소 | Text Input | **Mandatory** | |
| **TextArea** | 비고 | Text Area | Optional | |
| **Combo** | 사용여부 | Dropdown (Select) | **Mandatory** | YES/NO |
| **Input + Calendar**| 폐업일자 | Text Input + Calendar Icon | Optional | 달력 컴포넌트 연동 |
| **Input** | 첨부파일 | File Upload / Text | Optional | |
| **Text** | 등록자 | Text (Read-only) | **Mandatory** | 자동입력 |
| **Text** | 등록일시 | Text (Read-only) | **Mandatory** | 자동입력 |
| **Text** | 수정자 | Text (Read-only) | **Mandatory** | 자동입력 |
| **Text** | 수정일시 | Text (Read-only) | **Mandatory** | 자동입력 |

### 2.4 하단 버튼 (Bottom)
| 구분 | 라벨(Label) | 컴포넌트 타입 | 비고 |
| :--- | :--- | :--- | :--- |
| **Button** | 행추가 | Button | 신규 등록 모드 전환 |
| **Button** | 행취소(삭제) | Button | 삭제 로직 실행 |
| **Button** | 저장 | Button | DB 저장 실행 |

---

## 3. Data Mapping
화면의 UI 항목과 내부 데이터 속성(ID)의 매핑 정보입니다.

| 화면 항목 (Kor) | 영문 속성명 (ID) | 속성 (Attribute) | 데이터 타입/길이 | Validation / Rule |
| :--- | :--- | :--- | :--- | :--- |
| **[검색]** 거래처명 | `bzacNmCd` | Editable, Mandatory | String | 검색 조건 |
| **[목록]** 거래처코드 | `bzacCd` | ReadOnly | String | |
| **[목록]** 거래처명 | `bzacNm` | ReadOnly | String | |
| **[목록]** 사업자등록증 | `compregSlip` | Editable | String | Format: ###-###-#### |
| **[목록]** 사용여부 | `useYn` | ReadOnly | String | |
| **[상세]** 거래처코드 | `bzacCd` | Editable, Mandatory | String | 팝업 선택 또는 입력 |
| **[상세]** 사업자등록증 | `compregSlip` | Editable, Mandatory | String | Format: ###-###-#### |
| **[상세]** 사업자여부 | `bizmanYnCd` | Editable, Mandatory | Code | 공통코드 (사업/개인) |
| **[상세]** 상호명 | `storeNmCd` | Editable, Mandatory | String | |
| **[상세]** 대표자명 | `rptrNmCd` | Editable, Mandatory | String | |
| **[상세]** 법인등록번호 | `corpRegNoCd` | Editable, Mandatory | String | |
| **[상세]** 업태 | `bizcondCd` | Editable, Mandatory | String | |
| **[상세]** 업종 | `indstypeCd` | Editable, Mandatory | String | |
| **[상세]** 복수거래처여부 | `dupBzacYnCd` | Editable, Mandatory | Code | YES/NO |
| **[상세]** 우편주소 | `zipaddrCd` | Editable, Mandatory | String | 팝업 선택 |
| **[상세]** 상세주소 | `dtlAddrCd` | Editable, Mandatory | String | |
| **[상세]** 비고 | `rmk` | Editable | String | |
| **[상세]** 사용여부 | `useYnCd` | Editable, Mandatory | Code | YES/NO (Default: YES) |
| **[상세]** 폐업일자 | `clbizYmdCd` | Editable | Date | YYYY-MM-DD |
| **[상세]** 등록자명 | `regrNmCd` | Editable, Mandatory | String | System Session ID |
| **[상세]** 등록일시 | `regDate` | Editable, Mandatory | Date | System Date |
| **[상세]** 수정자명 | `mdfrNmCd` | Editable, Mandatory | String | System Session ID |
| **[상세]** 수정일시 | `chgdt` | Editable, Mandatory | Date | System Date |

---

## 4. Logic Definition
화면에서 발생하는 주요 이벤트 및 비즈니스 로직에 대한 정의입니다.

### 4.1 초기화 및 공통 로직 (Initialization)
*   **콤보박스 세팅:** 화면 Open 시 사용여부, 복수거래처여부, 사업자여부(사업, 개인)에 대한 콤보박스 데이터를 로드하고, 기본값을 '전체'로 설정합니다.
*   **기본값 설정:** 등록자, 수정자는 현재 로그인한 사용자 ID로, 등록일시, 수정일시는 DB 시스템 날짜(Sysdate)로 기본 설정합니다.

### 4.2 조회 로직 (Retrieve)
*   **이벤트명:** `사업자등록증목록검색` / `SearchCompregSlipListCmd`
*   **Input:** 거래처명 (`bzacNmCd`)
*   **Output:** 거래처코드, 거래처명, 사업자등록증번호, 사용여부 리스트
*   **Process:** 입력된 거래처명을 조건으로 시스템에서 관리하는 사업자등록증 정보를 조회하여 목록(Grid)에 바인딩합니다.

### 4.3 상세 조회 및 선택 로직 (Select Detail)
*   **이벤트명:** `사업자등록증상세정보조회` / `RetrieveCompregSlipDtlInfoCmd`
*   **Trigger:** 목록에서 행 클릭 시 (`사업자등록증목록선택`)
*   **Input:** 사업자등록증코드 (또는 거래처코드)
*   **Output:** 상세 데이터 전체 (Data Mapping 참조)
*   **Process:** 선택된 키 값을 기준으로 마스터 코드 정보를 조회하여 우측 상세 영역에 표시합니다.

### 4.4 신규 등록 로직 (Add Row)
*   **이벤트명:** `사업자등록증목록행추가`
*   **Process:**
    1.  상세 입력 필드를 모두 초기화(Clear) 합니다.
    2.  '사용여부'는 강제로 'YES'로 세팅합니다.
    3.  등록자/수정자/일시 정보를 현재 시스템 기준으로 화면에 표시합니다.
    4.  거래처코드 선택 등록 시, 해당 거래처의 기본 정보를 가져와 상세 정보에 자동 셋팅하는 처리가 필요합니다.

### 4.5 저장 로직 (Save)
*   **이벤트명:** `사업자등록증상세정보저장` / `SaveCompregSlipDtlInfoCmd`
*   **Input:** 상세 영역의 모든 데이터
*   **Process:**
    1.  Mandatory 필드(필수값) 유효성을 체크합니다.
    2.  신규 등록인 경우: `INSERT` 처리하며, 등록자/수정자 정보를 현재 세션 정보로 저장합니다.
    3.  수정인 경우: `UPDATE` 처리하며, 수정자/수정일시 정보를 갱신합니다.

### 4.6 삭제 로직 (Delete)
*   **이벤트명:** `사업자등록증목록행삭제`
*   **Process:**
    1.  신규 행추가 상태인 데이터: 화면 목록에서 행을 삭제합니다.
    2.  기존 DB 저장 데이터: 데이터를 물리적으로 삭제하지 않고, **'사용여부' 값을 '아니오(No)'로 변경**하여 업데이트합니다 (논리적 삭제).
    3.  사용자에게 수정 모드로 전환됨을 알리는 메시지를 처리합니다.

### 4.7 팝업 로직 (Popup)
*   **거래처 선택:**
    *   `[url]공통.거래처선택 팝업` 호출 (`BzacSlcPopup.jsp`).
    *   Input: 거래처코드, 거래처명.
    *   Output: 선택된 거래처코드, 거래처명.
    *   *특이사항:* 조회된 값이 1개일 경우 팝업 없이 즉시 화면에 세팅합니다.
*   **우편번호 선택:**
    *   `[url]공통.우편번호선택 팝업` 호출 (`ZipcdSlcPopup.jsp`).
    *   Input: 우편번호코드, 주소명.
    *   Output: 선택된 우편번호, 주소.
    *   *특이사항:* 조회된 값이 1개일 경우 팝업 없이 즉시 주소명을 화면에 표시합니다.
