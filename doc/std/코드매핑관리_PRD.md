# PRD: 코드매핑 관리 (Code Mapping Management)

## 1. User Flow
사용자가 코드매핑 그룹을 조회하고, 그룹 정보를 등록/수정하며, 해당 그룹에 속한 상세 코드를 관리하는 전체 흐름입니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 화면에 진입하면 조회 조건(거래처, 코드매핑 그룹 등)이 기본값('전체')으로 설정됩니다.
2.  **조회 (Search)**
    *   사용자가 조회 조건(거래처명, 코드매핑 그룹명 등)을 입력하고 **[조회]** 버튼을 클릭합니다.
    *   좌측 그리드에 '코드매핑 그룹 목록'이 표시됩니다.
3.  **그룹 선택 및 상세 조회 (Select & View Detail)**
    *   좌측 목록에서 특정 '코드매핑 그룹'을 선택(Click)합니다.
    *   우측 상단에 선택한 그룹의 '상세 정보(Group Detail)'가 표시됩니다.
    *   우측 하단에 해당 그룹에 속한 '코드매핑 상세 목록(Detail List)'이 표시됩니다.
4.  **코드매핑 그룹 신규 등록 (Create New Group)**
    *   **[신규(코드매핑그룹신규)]** 버튼을 클릭합니다.
    *   우측 상단 입력 폼이 초기화(Clear)되며, 등록자/일시는 현재 정보로, 사용여부는 'YES'로 자동 설정됩니다.
    *   필수 항목(거래처, 그룹명 등)을 입력하고 **[저장]** 버튼을 클릭하여 그룹을 생성합니다.
5.  **코드매핑 상세 관리 (Manage Code Details)**
    *   그룹 저장 후, 우측 하단 상세 목록에서 **[행추가]** 버튼을 클릭하여 새로운 상세 코드를 입력할 행을 생성합니다.
    *   상세 코드 정보를 입력하고 **[저장]** 버튼을 클릭하여 DB에 반영합니다.
    *   필요 시 **[행삭제]** 버튼을 통해 작성 중인 행을 취소하거나 삭제합니다.

---

## 2. UI Component 리스트
화면을 구성하는 주요 구역별 UI 요소입니다.

### 2.1. 조회 영역 (Search Area)
| Component 명 | Type | 설명/비고 | Source |
| :--- | :--- | :--- | :--- |
| 거래처명 | Text Input + Button | 거래처 코드/명 검색 및 팝업 호출 (공통 팝업) | |
| 코드매핑 그룹 | Text Input | 검색할 코드매핑 그룹 코드 입력 | |
| 코드매핑 그룹명 | Text Input | 검색할 코드매핑 그룹 명칭 입력 | |
| 사용여부 | Dropdown | 전체/사용/미사용 선택 (기본값: 전체) | |
| 조회 버튼 | Button | 검색 실행 트리거 | |

### 2.2. 좌측: 코드매핑 그룹 목록 (Left Grid)
| Component 명 | Type | 설명/비고 | Source |
| :--- | :--- | :--- | :--- |
| 거래처 | Data Column | Read Only | |
| 코드매핑 그룹 | Data Column | Read Only | |
| 코드매핑 그룹명 | Data Column | Read Only | |
| 사용여부 | Data Column | Read Only | |

### 2.3. 우측 상단: 코드매핑 그룹 상세 (Right Top Form)
| Component 명 | Type | 설명/비고 | Source |
| :--- | :--- | :--- | :--- |
| 거래처 | Text Input | **[필수]** Editable | |
| 코드매핑 그룹 | Text Input | **[필수]** Editable (신규 시 자동채번) | |
| 코드매핑 그룹명 | Text Input | **[필수]** Editable | |
| 자사공통코드그룹 | Text Input | Editable (자사 공통코드와 매핑되는 그룹 코드) | |
| 사용여부 | Dropdown | **[필수]** Editable ('YES'/'NO') | |
| 비고 | Text Input | Editable | |
| 등록자/수정자 정보 | Text (Label) | Read Only (시스템 자동 입력) | |
| 신규/저장 버튼 | Button | 그룹 정보 초기화 및 저장 | |

### 2.4. 우측 하단: 코드매핑 상세 (Right Bottom Grid/Form)
| Component 명 | Type | 설명/비고 | Source |
| :--- | :--- | :--- | :--- |
| 공통 코드 | Text Input | **[필수]** Editable (사용자 직접 입력) | |
| 코드매핑 명 | Text Input | **[필수]** Editable | |
| 순서 | Text Input | Editable (정렬 순서) | |
| 비고 | Text Input | Editable | |
| 자사공통코드그룹 | Text Input | Read Only (상위 그룹 정보 자동 표시) | |
| 자사공통코드 | Text Input | Editable (연결될 자사 코드) | |
| 사용여부 | Dropdown | **[필수]** Editable | |
| 행추가/행삭제 버튼 | Button | 그리드 행 제어 | |

---

## 3. Data Mapping
화면 항목과 데이터 속성 간의 매핑 정의입니다. (Source 2의 영문 속성명 및 Validation 기준)

### 3.1. 코드매핑 그룹 (Group)
| 한글명 | 영문 ID (Variable) | 속성 (Validation) | 설명 | Source |
| :--- | :--- | :--- | :--- | :--- |
| 거래처코드 | `bzacCd` | Mandatory | 거래처 식별 코드 | |
| 거래처명 | `bzacNm` | Mandatory | 거래처 명칭 | |
| 코드매핑그룹 | `cdMpngGrp` | Mandatory | 시스템 자동 채번 (일련번호) | |
| 코드매핑그룹명 | `cdMpngGrpNmCd` | Mandatory | 그룹 명칭 | |
| 사용여부 | `useYnCd` | Mandatory | 'YES' or 'NO' (Default: YES) | |
| 자사공통코드그룹 | `chdSaComnCdGrpCd` | Optional | 자사 내부 공통코드 그룹 매핑 | |
| 비고 | `rmkCd` | Optional | | |
| 등록자명 | `regrNmCd` | Mandatory | 로그인 사용자 이름 | |
| 등록일시 | `regDate` | Mandatory | YYYY-MM-DD 포맷 | |

### 3.2. 코드매핑 상세 (Detail)
| 한글명 | 영문 ID (Variable) | 속성 (Validation) | 설명 | Source |
| :--- | :--- | :--- | :--- | :--- |
| 공통 코드 | `comnCd` | Mandatory | 매핑할 외부 코드 (직접 입력) | |
| 코드매핑 명 | `cdMpngNmCd` | Mandatory | 상세 코드 명칭 | |
| 순서 | `seqCd` | Optional | 정렬 순서 | |
| 자사공통코드그룹 | `chdSaComnCdGrp` | Read Only | 그룹 상세의 값을 상속받아 표시 | |
| 자사공통코드 | `chdSaComnCd` | Optional | 공통코드 미관리 항목일 수 있으므로 필수 아님 | |
| 사용여부 | `useYnCd` | Mandatory | | |

---

## 4. Logic Definition
화면 동작 및 데이터 처리에 대한 로직 정의입니다.

### 4.1. 초기화 및 조회 로직 (Init & Search)
*   **Open Event:** 화면 로드 시 거래처, 코드매핑 그룹, 그룹명, 사용여부 등 모든 조회 조건을 "전체"로 설정하고, 등록/수정일시는 DB 시간(sysdate), 등록/수정자는 로그인 사용자로 초기화합니다.
*   **조회 실행:** 사용자가 입력한 조건에 일치하는 '코드매핑 그룹' 목록을 조회합니다.
*   **거래처 선택 팝업:** 거래처 검색 시 결과가 1건이면 자동 선택되고, 다건이면 '거래처선택 팝업(BzacSlcPopup.jsp)'을 호출합니다.

### 4.2. 상세 정보 연동 로직 (Master-Detail Interaction)
*   **그룹 선택 시:** 목록에서 특정 그룹을 클릭하면 `[trigger] 코드매핑그룹조회`가 실행되어, 해당 그룹의 상세 정보(우측 상단)와 하위 매핑 코드 목록(우측 하단)을 동시에 조회하여 바인딩합니다.
*   **자사공통코드그룹 연동:** '코드매핑 그룹 상세'에 등록된 `자사공통코드그룹` 값은 하위 '코드매핑 상세' 그리드의 해당 컬럼에 자동으로 Display 됩니다.

### 4.3. 신규 및 저장 로직 (CRUD Rules)
*   **그룹 신규 버튼 클릭:**
    *   입력 폼(거래처, 그룹코드, 그룹명 등)을 모두 Clear 합니다.
    *   등록자/수정자는 현재 로그인 ID, 일시는 현재 시스템 일시로 세팅합니다.
    *   `사용여부`는 자동으로 **'YES'**로 설정합니다.
*   **행추가 (상세):** 상세 목록 그리드에 입력 가능한 빈 행을 추가합니다.
*   **저장 (Save):**
    *   **그룹 정보:** 신규 생성 시 `코드매핑그룹코드`는 시스템 일련번호로 **자동 채번**됩니다.
    *   **상세 정보:** `코드매핑코드(공통코드)`는 사용자가 무의미 코드 또는 의미 코드를 **직접 입력**해야 합니다.
    *   **자사공통코드:** 공통코드에서 관리되지 않는 항목도 매핑 관리할 수 있으므로, `자사공통코드` 컬럼은 필수 입력값이 아닙니다.
    *   저장 시점에는 등록/수정자 정보와 시간을 갱신하여 DB에 반영합니다.
