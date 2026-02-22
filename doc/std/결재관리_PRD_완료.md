# PRD: 결재관리 (Payment Management)

## 1. User Flow (화면 흐름)

사용자가 결재 관련 정보를 조회, 등록, 수정하는 전체적인 흐름은 다음과 같습니다.

1.  **화면 진입 (Initial Load):**
    *   사용자가 결재관리 메뉴에 진입하면 화면이 로드됩니다.
    *   초기화 로직(Open Event)이 실행되어 '결재유형' 및 '직책' 콤보박스 데이터가 세팅됩니다.

2.  **검색 (Search):**
    *   사용자는 상단 검색 영역에서 [법인] 또는 [메뉴] 조건을 입력합니다.
    *   [검색] 버튼을 클릭하면 좌측 목록 영역에 조건에 맞는 결재 리스트가 조회됩니다.

3.  **상세 조회 (Detail View):**
    *   좌측 리스트에서 특정 행(Row)을 클릭하면, 우측 상세정보 영역에 해당 항목의 세부 데이터가 바인딩됩니다.

4.  **신규 등록 및 수정 (Create & Update):**
    *   **신규:** 하단 [행추가] 버튼 클릭 시, 우측 상세정보 입력 필드가 초기화됩니다(사용여부는 'YES'로 자동 설정).
    *   **수정:** 상세정보 영역에서 데이터 수정 후 [저장] 버튼을 클릭하여 변경 사항을 반영합니다.
    *   **입력 보조:** 법인, 메뉴, 사용자(담당결재자, 위임자) 입력란 옆의 '찾기(돋보기)' 아이콘을 클릭하면 각각의 팝업창이 호출되어 값을 선택할 수 있습니다.

5.  **삭제 (Delete/Soft Delete):**
    *   [행삭제/취소] 버튼 클릭 시, 신규 행인 경우 목록에서 즉시 삭제됩니다.
    *   기존 DB에 저장된 데이터인 경우, 레코드를 삭제하지 않고 '사용여부' 값을 'No(아니오)'로 변경하여 비활성화 처리합니다.

---

## 2. UI Component List

화면은 크게 **검색 영역(Search)**, **목록 영역(Left)**, **상세정보 영역(Right)**으로 구성됩니다.

### 2.1 검색 영역 (Top)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| InputText | 법인 (Corporation) | Text + Popup | 법인코드/법인명 입력 및 검색 팝업 호출 |
| InputText | 메뉴 (Menu) | Text + Popup | 메뉴코드/메뉴명 입력 및 검색 팝업 호출 |
| Button | 검색 (Search) | Button | 결재목록 조회 실행 |

### 2.2 목록 영역 (Left)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| Grid/Table | 결재목록 | Table | 조회된 결과 리스트 표시 |
| Column | No | Text | 순번 |
| Column | 메뉴코드 | Text | 메뉴의 고유 코드 |
| Column | 메뉴명 | Text | 메뉴의 이름 |
| Column | 사용여부 | Text | 사용 가능 여부 (YES/NO) |

### 2.3 상세정보 영역 (Right)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| InputText | 법인코드 | Text (Read-only) | 법인코드 (필수) |
| InputText | 법인명 | Text (Read-only) | 법인명 |
| InputText | 메뉴 | Text (Read-only) | 메뉴코드/메뉴명 (필수) |
| InputText | 테이블 | Text | 관련 테이블 정보 |
| InputText | 컬럼1~5 | Text | 추가 속성 컬럼 |
| SelectBox | 지정결재자여부 | Dropdown | 지정 결재자 사용 여부 (YES/NO) (필수) |
| InputText | 담당결재자 | Text + Popup | 지정결재자가 YES일 때 사용자 선택 |
| SelectBox | 미지정결재자직책 | Dropdown | 지정결재자가 NO일 때 직책 선택 (예: 팀장) |
| SelectBox | 결재유형 | Dropdown | 결재 유형 선택 (코드승인 등) |
| SelectBox | 결재위임여부 | Dropdown | 위임 여부 선택 (YES/NO) |
| InputText | 결재위임자 | Text + Popup | 위임 시 사용자 선택 |
| TextArea | 비고 | Text | 비고 사항 입력 |
| SelectBox | 사용여부 | Dropdown | 데이터 사용 여부 (YES/NO) |
| Text | 등록자/일시 | Label | 등록자 정보 및 등록 시간 (Read-only) |
| Text | 수정자/일시 | Label | 수정자 정보 및 수정 시간 (Read-only) |

### 2.4 하단 버튼 (Bottom)
| Component | Label | Type | Description |
| :--- | :--- | :--- | :--- |
| Button | 행추가 | Button | 신규 입력 모드 전환 및 폼 초기화 |
| Button | 행취소(삭제) | Button | 선택된 행 삭제 또는 사용여부 'No' 처리 |
| Button | 저장 | Button | 입력/수정된 정보 DB 저장 |

---

## 3. Data Mapping

화면 UI 항목과 설계서상 정의된 영문 속성명(변수명) 매핑입니다.

| 한글명 | 영문명 (English Name) | 속성명 (Variable Name) | 필수여부 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **법인코드** | Corporation Code | `corpCd` | Mandatory | |
| **법인명** | Corporation Name | `corpNm` | Mandatory | |
| **메뉴코드** | Menu Code | `menuCd` | - | |
| **메뉴명** | Menu Name | `menuNm` | - | |
| **메뉴명코드** | MenuNameCode | `menuNmCd` | Mandatory | 상세정보 |
| **지정결재자여부** | AssignmentApproverYesOrNo | `asmtApverYn` | Mandatory | |
| **담당결재자** | ChargeApprover | `chrgApver` | - | 사용자코드 (`userCd`) 매핑 |
| **미지정결재자직책** | NotAssignmentApproverResponsibility | `notAsmtApverResp` | - | |
| **결재유형** | ApprovalTypeCode | `apvTypeCd` | - | |
| **결재위임여부** | ApprovalDelegationYesOrNo | `apvDelegtYn` | - | |
| **결재위임자** | ApprovalDelegate | `apvDelegate` | - | 사용자코드 (`userCd`) 매핑 |
| **비고** | Remark | `rmk` | - | |
| **사용여부** | UseYesOrNo | `useYn` | - | |
| **등록자명** | RegistrarName | `regrNm` | - | |
| **등록일시** | RegistrationDate | `regDate` | - | |
| **수정자명** | ModifierName | `mdfrNm` | - | |
| **수정일시** | ChangePersonDate | `chgdt` | - | |

---

## 4. Logic Definition

### 4.1 초기화 및 공통 로직 (Open Event)
*   **콤보박스 세팅:**
    *   사용여부 콤보는 자동으로 "전체"를 선택합니다.
    *   **결재유형:** 기타코드 28번 정보를 조회하여 바인딩합니다.
    *   **직책:** 기타코드 97번 정보 중 상위코드가 '10'인 데이터만 조회하여 바인딩합니다.
*   **등록/수정 정보:** 등록자, 수정자는 현재 로그인 사용자 ID로, 일시는 DB sysdate로 기본 설정합니다.

### 4.2 지정결재자 로직 (Business Rule)
*   **지정결재자여부 = YES:** 시스템 환경 설정의 결재자를 기본값으로 세팅하며, 필요시 '담당결재자(사용자 정보 팝업)'를 통해 수정할 수 있어야 합니다.
*   **지정결재자여부 = NO:** '미지정결재자직책' 콤보박스(예: 팀장)를 활성화하여 직책을 선택하도록 제어합니다.

### 4.3 팝업 로직 (Popup Logic)
*   **법인선택:** `공통.법인선택 팝업` 호출. 조회 결과가 1건일 경우 팝업 없이 즉시 값을 세팅합니다.
*   **메뉴선택:** `공통.메뉴선택 팝업` 호출. 조회 결과가 1건일 경우 팝업 없이 즉시 값을 세팅합니다.
*   **사용자선택:** `공통.사용자선택 팝업` 호출. 담당결재자 및 결재위임자 선택 시 사용되며, 조회 결과가 1건일 경우 즉시 세팅합니다.

### 4.4 데이터 조작 (CRUD Logic)
*   **신규 (행추가):**
    *   모든 입력 필드를 Clear 합니다.
    *   `사용여부`는 자동으로 **'YES'**로 세팅합니다.
    *   등록/수정 정보에 현재 사용자와 시스템 일시를 표시합니다.
*   **삭제 (행삭제):**
    *   신규 행은 목록에서 제거합니다.
    *   기존 DB 데이터는 레코드 자체를 삭제하지 않고, `사용여부` 값을 **'아니오(No)'**로 변경하여 저장 가능한 상태(메시지 처리)로 만듭니다.
*   **저장:**
    *   신규 등록 시: 입력된 정보를 Insert.
    *   수정 시: 변경된 정보를 Update (수정자/수정일시 갱신).
