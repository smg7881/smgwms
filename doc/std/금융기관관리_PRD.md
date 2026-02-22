# 금융기관관리 (Financial Institution Management) PRD

## 1. User Flow (사용자 흐름)

사용자가 금융기관 정보를 조회, 등록, 수정, 삭제하는 전체적인 흐름은 다음과 같습니다.

1.  **화면 진입 (Entry):**
    *   사용자가 메뉴를 통해 '금융기관관리' 화면에 접속합니다.
    *   시스템은 초기화 이벤트(`Open`)를 실행하여 기본값을 설정합니다 (등록자/수정자 정보, 현재 날짜 등).

2.  **조회 (Search):**
    *   사용자가 상단 검색 조건인 '금융기관명'을 입력합니다.
    *   '검색' 버튼을 클릭합니다.
    *   좌측 그리드(목록)에 조건에 맞는 금융기관 정보(코드, 명칭, 국가, 사용여부)가 표시됩니다.

3.  **상세 정보 확인 (View Detail):**
    *   사용자가 좌측 목록에서 특정 금융기관 행(Row)을 선택합니다.
    *   우측 상세 정보 영역에 해당 금융기관의 상세 데이터(영문명, 국가코드, 등록/수정 정보 등)가 조회(`RetrieveFncOrDtlInfoCmd`)되어 바인딩됩니다.

4.  **신규 등록 (Create):**
    *   사용자가 목록 하단의 '행추가' 버튼을 클릭합니다.
    *   상세 정보 영역의 입력 필드가 초기화됩니다.
    *   **자동 설정:** 금융기관코드는 직접 입력 대기 상태가 되며, '사용여부'는 자동으로 'YES'로 설정됩니다. 등록자/수정자는 현재 로그인 ID, 일시는 현재 시스템 날짜로 세팅됩니다.
    *   사용자가 필수 정보를 입력하고 '저장' 버튼을 클릭하여 DB에 신규 데이터를 생성합니다.

5.  **수정 (Update):**
    *   상세 정보 조회 후, 사용자가 정보를 변경합니다 (예: 영문명 수정, 국가 변경 등).
    *   수정 시 수정자명과 수정일시는 현재 로그인 정보와 시스템 시간으로 갱신됩니다.
    *   '저장' 버튼을 클릭하여 변경 사항을 반영합니다.

6.  **국가 선택 (Select Country):**
    *   상세 정보 입력 중 '국가' 항목의 검색 버튼(돋보기 아이콘)을 클릭합니다.
    *   국가선택 팝업이 호출되며, 조회된 국가가 1건일 경우 팝업 없이 즉시 입력되고, 다건일 경우 팝업에서 선택합니다.

7.  **삭제/사용 중지 (Delete/Deactivate):**
    *   사용자가 목록에서 행을 선택하고 '행취소(삭제)' 버튼을 클릭합니다.
    *   **Logic:** 신규 행인 경우 데이터가 삭제되지만, 기존 DB에 데이터가 있는 경우 '사용여부'만 'No(아니오)'로 변경되어 저장됩니다 (Logical Delete).

---

## 2. UI Component 리스트

화면 레이아웃은 크게 **검색 영역(Top)**, **목록 영역(Left)**, **상세 정보 영역(Right)**으로 구분됩니다.

### 2.1 검색 영역 (Top Search Bar)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| **Input Text** | 금융기관명 | Text Field | 검색할 금융기관 이름 입력 |
| **Button** | 검색 | Button | 조회 이벤트(`SearchFncOrListCmd`) 트리거 |

### 2.2 목록 영역 (Left Panel - List)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| **Grid/Table** | 금융기관목록 | Data Grid | 조회된 결과 목록 표시 (No, 금융기관코드, 금융기관명, 국가, 사용여부) |
| **Button** | 행추가 | Button | 신규 등록 모드 전환 및 입력 폼 초기화 |
| **Button** | 행취소 | Button | 선택된 행 삭제 또는 사용여부 'No' 처리 |

### 2.3 상세 정보 영역 (Right Panel - Detail)
| Component | Label | Type | Mandatory | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Input Text** | 금융기관코드 | Text Field | **Yes** | 신규 시 입력, 수정 시 Read-only 가능성 있음 (설계서상 Editable) |
| **Input Text** | 금융기관명 | Text Field | **Yes** | 금융기관 국문 명칭 |
| **Input Text** | 금융기관영문명 | Text Field | **Yes** | 금융기관 영문 명칭 |
| **Input Group** | 국가/국가코드 | Text + Button | No | 국가 코드 및 명칭 표시, 팝업 검색 버튼 포함 |
| **Dropdown** | 사용여부 | Combo Box | **Yes** | 사용 여부 (YES/NO), 신규 시 'YES' 기본값 |
| **Input Text** | 등록자 | Text Field | **Yes** | Read-only, 시스템 자동 할당 (로그인 ID) |
| **Input Text** | 등록일시 | Text Field | **Yes** | Read-only, 포맷: YYYY-MM-DD |
| **Input Text** | 수정자 | Text Field | **Yes** | Read-only, 시스템 자동 할당 (로그인 ID) |
| **Input Text** | 수정일시 | Text Field | **Yes** | Read-only, 포맷: YYYY-MM-DD |
| **Button** | 저장 | Button | - | 데이터 저장(Insert/Update) 이벤트(`SaveFncOrDtlCmd`) 트리거 |

---

## 3. Data Mapping

### 3.1 Search Condition
| UI Item (Korean) | Variable Name | Type | Note |
| :--- | :--- | :--- | :--- |
| 금융기관명 | `fncOrNmCd` | String | 검색 조건 |

### 3.2 List Grid (금융기관목록)
| UI Item (Korean) | Variable Name | Read Only | Note |
| :--- | :--- | :--- | :--- |
| 금융기관코드 | `fncOrCdCd` | Yes | |
| 금융기관명 | `fncOrNm` | Yes | |
| 국가 | `ctry` | Yes | |
| 사용여부 | `useYn` | Yes | |

### 3.3 Detail Info (금융기관상세정보)
| UI Item (Korean) | Variable Name | Mandatory | Logic/Default |
| :--- | :--- | :--- | :--- |
| 금융기관코드 | `fncOrCdCd` | **M** | Master Code 관리 |
| 금융기관명 | `fncOrNmCd` | **M** | |
| 금융기관영문명 | `fncOrEngNmCd` | **M** | |
| 국가코드 | `ctryCd` | No | 팝업 리턴값 |
| 국가명 | `ctryNm` | No | 팝업 리턴값 |
| 사용여부 | `useYnCd` | **M** | 신규: 'YES' 자동 세팅 |
| 등록자명 | `regrNmCd` | **M** | Login ID |
| 등록일시 | `regDate` | **M** | DB sysdate |
| 수정자명 | `mdfrNmCd` | **M** | Login ID |
| 수정일시 | `chgdt` | **M** | DB sysdate |

---

## 4. Logic Definition

### 4.1 초기화 로직 (Initialization)
*   **Open Event:** 화면이 열릴 때, 사용여부 콤보박스 등의 기초 데이터를 세팅합니다.
*   등록자, 수정자는 현재 로그인한 사용자 ID로, 등록일시와 수정일시는 DB의 `sysdate`를 기준으로 화면에 표시합니다.

### 4.2 조회 로직 (Search Logic)
*   **목록 조회:** 입력된 '금융기관명'(`fncOrNmCd`)을 조건으로 시스템에서 관리하는 금융기관 정보를 검색하여 그리드에 바인딩합니다.
*   **상세 조회:** 목록에서 행 선택 시, 해당 행의 `금융기관코드`를 키(Key)로 상세 정보를 재조회(`RetrieveFncOrDtlInfoCmd`)하여 우측 폼에 표시합니다.

### 4.3 신규 및 수정 로직 (Create & Update Logic)
*   **행추가(신규):**
    *   상세 정보의 모든 입력 필드를 Clear 합니다.
    *   `사용여부`는 강제로 'YES'로 설정합니다.
    *   등록/수정 정보(이름, 일시)를 현재 시점 기준으로 갱신하여 보여줍니다.
*   **저장:**
    *   필수 입력값(코드, 명칭, 영문명, 사용여부 등)을 검증합니다.
    *   금융기관 코드는 국내 공통코드로 관리되며 수작업으로 입력됩니다.
    *   신규 등록 또는 수정된 정보를 DB에 반영(`SaveFncOrDtlCmd`)합니다.
    *   저장 시 등록/수정 정보는 현재 로그인 ID와 시스템 일시로 저장됩니다.

### 4.4 삭제 로직 (Delete Logic)
*   **행삭제(취소):**
    *   UI에서 선택된 행에 대해 삭제를 시도합니다.
    *   **신규 데이터:** DB에 저장되지 않은 상태라면 그리드에서 행을 삭제합니다.
    *   **기존 데이터:** DB에 이미 존재하는 데이터라면 레코드 자체를 삭제하지 않고, `사용여부` 값을 '아니오(NO)'로 업데이트하여 비활성화 처리합니다 (Logical Delete).

### 4.5 팝업 로직 (Popup Logic)
*   **국가 선택:**
    *   국가코드 검색 시 `공통.국가선택 팝업`을 호출합니다.
    *   조회된 결과가 1건일 경우: 팝업을 띄우지 않고 즉시 국가코드와 국가명을 화면에 매핑합니다.
    *   조회된 결과가 N건일 경우: 팝업 리스트에서 사용자가 선택하도록 합니다.
