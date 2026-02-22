# 기본작업단계관리 (Standard Work Step Management) PRD

## 1. User Flow
사용자가 시스템에 접속하여 작업단계를 조회, 상세 확인, 신규 등록 및 수정/저장하는 흐름은 다음과 같습니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 화면에 진입하면 로그인 정보와 시스템 일자를 기준으로 초기화된 화면이 로드됩니다.
    *   검색 조건의 '사용여부' 콤보박스는 자동으로 "전체"가 선택됩니다.
    *   기타코드(07번, 08번)를 참조하여 작업단계 Level 1, 2 콤보박스 데이터가 세팅됩니다.

2.  **조회 (Search)**
    *   사용자가 `작업단계코드`, `작업단계명`, `사용여부` 등 검색 조건을 입력합니다.
    *   **[조회]** 버튼을 클릭하면 조건에 맞는 작업단계 목록이 좌측 그리드(List)에 표시됩니다.

3.  **상세 정보 확인 (View Details)**
    *   좌측 작업단계 목록에서 특정 행(Row)을 선택합니다.
    *   선택된 항목의 상세 정보가 우측 **[작업단계상세정보]** 영역에 바인딩되어 표시됩니다.

4.  **신규 등록 (Create New)**
    *   **[신규]** (또는 행추가) 버튼을 클릭합니다.
    *   상세 정보 입력란이 초기화되며, `사용여부`는 자동으로 'YES'로 설정됩니다.
    *   `등록자/일시`, `수정자/일시`는 현재 로그인한 사용자 정보와 시스템 시간으로 자동 세팅됩니다.
    *   사용자가 필수 항목(`작업단계코드`, `명`, `Level1`, `Level2` 등)을 입력합니다.

5.  **저장 (Save)**
    *   정보 입력 또는 수정 후 **[저장]** 버튼을 클릭합니다.
    *   신규 데이터는 DB에 `Insert`, 기존 데이터 수정 시 `Update` 처리됩니다.

6.  **삭제 (Delete)**
    *   목록에서 항목 선택 후 **[삭제]** 버튼 클릭 시, 신규 행은 즉시 삭제되나 기존 DB에 존재하는 데이터는 `사용여부`가 '아니오'로 변경되는 논리적 삭제(Logical Delete)가 수행됩니다.

---

## 2. UI Component 리스트
화면은 크게 **조회 영역(Search)**, **목록 영역(List)**, **상세 정보 영역(Detail)**으로 구성됩니다.

### 2.1 조회 영역 (Search Condition)
| Label (Kor) | Variable Name | Type | Properties/Rules | Source |
| :--- | :--- | :--- | :--- | :--- |
| 작업단계코드 | `workStepCd` | InputBox | Editable | |
| 작업단계명 | `workStepNmCd` | InputBox | Editable | |
| 사용여부 | `useYnCd` | ComboBox | Editable, Default: "전체" | |
| 조회 | (Button) | Button | Trigger Search Event | |

### 2.2 목록 영역 (List Grid)
| Label (Kor) | Variable Name | Type | Properties/Rules | Source |
| :--- | :--- | :--- | :--- | :--- |
| 작업단계코드 | `workStepCd` | Text | ReadOnly | |
| 작업단계명 | `workStepNm` | Text | ReadOnly | |
| 작업단계 Level1 | `workStepLevel1` | Text | ReadOnly | |
| 작업단계 Level2 | `workStepLevel2` | Text | ReadOnly | |
| 비고 | `rmk` | Text | ReadOnly | |
| 사용여부 | `useYn` | Text | ReadOnly | |

### 2.3 상세 정보 영역 (Detail Form)
| Label (Kor) | Variable Name | Type | Properties/Rules | Source |
| :--- | :--- | :--- | :--- | :--- |
| 작업단계코드 | `workStepCd` | InputBox | **Mandatory**, Editable | |
| 작업단계명 | `workStepNmCd` | InputBox | **Mandatory**, Editable | |
| 작업단계 Level1 | `workStepLevel1Cd` | ComboBox | **Mandatory**, Editable, Common Code 07 | |
| 작업단계 Level2 | `workStepLevel2Cd` | ComboBox | **Mandatory**, Editable, Common Code 08 | |
| 사용여부 | `useYnCd` | ComboBox | **Mandatory**, Editable, Default(New): YES | |
| 정렬순서 | `sortSeqCd` | InputBox | Editable | |
| 내용 | `contsCd` | InputBox | Editable | |
| 비고 | `rmkCd` | InputBox | Editable | |
| 등록자명 | `regrNmCd` | InputBox | **Mandatory**, ReadOnly(System Set) | |
| 등록일시 | `regDate` | DatePicker/Text | **Mandatory**, ReadOnly(System Set) | |
| 수정자명 | `mdfrNmCd` | InputBox | **Mandatory**, ReadOnly(System Set) | |
| 수정일시 | `chgdt` | DatePicker/Text | **Mandatory**, ReadOnly(System Set) | |

---

## 3. Data Mapping
화면 UI 요소와 내부 데이터 처리 간의 매핑 정보입니다.

*   **초기 데이터 로드 (Open Event)**
    *   **Input:** `LoginId`, `DB sysdate`.
    *   **Common Code Mapping:**
        *   기타코드 07번 → `작업단계 Level1` 콤보박스.
        *   기타코드 08번 → `작업단계 Level2` 콤보박스.

*   **목록 조회 (SearchWorkStepListCmd)**
    *   **Input (Request):** `작업단계관리찾기조건` (`workStepCd`, `workStepNmCd`, `useYnCd`).
    *   **Output (Response):** `작업단계코드`, `작업단계명`, `작업단계Level1`, `작업단계Level2`, `비고`, `사용여부` 리스트.

*   **상세 조회 (Select Event)**
    *   **Input:** `작업단계코드` (Selected Row).
    *   **Output:** 상세 정보 전체 (`workStepCd` ~ `chgdt` 포함).

*   **저장 (SaveWorkStepDtlInfoCmd)**
    *   **Input (Request):** 상세 정보 영역의 모든 필드 값 (`workStepCd`, `workStepNmCd`, `workStepLevel1Cd`, ... `chgdt`).
    *   **System Input:**
        *   신규 등록 시: `등록자/일시`, `수정자/일시` = 현재 로그인 ID / 시스템 일시.
        *   수정 시: `수정자/일시` = 현재 로그인 ID / 시스템 일시.

---

## 4. Logic Definition
화면에서 수행되는 주요 비즈니스 로직 및 제어 규칙입니다.

### 4.1 초기화 및 화면 제어 로직
*   **Default Values:**
    *   등록일시/수정일시 기본값은 `DB sysdate`를 사용합니다.
    *   등록자/수정자 기본값은 `현재 로그인 사용자`를 사용합니다.
*   **Combo Box Setting:**
    *   화면 오픈 시 `사용여부` 값을 찾기 위한 콤보를 세팅하며 자동으로 "전체"를 선택합니다.

### 4.2 작업단계 Level 연동 로직
*   `작업단계 Level2` 콤보박스는 독립적으로 동작하지 않고, 상위 코드인 `작업단계 Level1` 선택 값에 종속됩니다.
*   **Rule:** `작업단계 Level1` 코드에 해당하는 `작업단계 Level2` 목록만 필터링하여 보여주어야 합니다.
*   **Reference:**
    *   Level 1: 운송, 하역, 보관, 포장 등으로 구분.
    *   Level 2 (예시):
        *   운송 → 육송, 거점운송, 내륙운송, 철송, 해송, 항공.
        *   하역 → 선내, 선측, 상차, 하차.

### 4.3 신규 및 수정 로직
*   **신규 버튼 클릭 시:**
    *   모든 입력 필드를 Clear 합니다.
    *   단, `사용여부`는 자동으로 **'YES'**로 세팅합니다.
    *   등록/수정 정보(사람, 시간)를 현재 기준으로 표시합니다.
*   **저장 버튼 클릭 시:**
    *   신규 등록과 수정을 구분하여 DB에 반영합니다.

### 4.4 삭제 로직 (업무 규칙)
*   **삭제 버튼 클릭 시:**
    *   선택된 데이터가 화면에서 **신규 행추가**로 생성된 데이터인 경우: 즉시 Row를 삭제합니다.
    *   기존 **DB에 저장된 데이터**인 경우: 레코드 자체를 삭제하지 않고 `사용여부` 값만 **'아니오'**로 업데이트하여 저장합니다 (Soft Delete).
    *   사용자에게 수정(사용중지) 처리에 대한 메시지를 표시해야 합니다.
