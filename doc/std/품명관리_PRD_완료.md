# 품명관리 (Goods Management) PRD

## 1. User Flow

사용자는 품명 정보를 조회하고, 상세 정보를 확인하며, 신규 등록하거나 수정하는 워크플로우를 가집니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 화면에 진입하면 시스템은 검색 조건(사용여부) 및 상세 정보 입력에 필요한 콤보박스(하태, 품목군, 품목, 화종, 화종군) 데이터를 초기화합니다.
    *   '사용여부' 검색 조건은 기본값으로 "전체"가 선택됩니다.

2.  **품명 목록 조회 (Search)**
    *   사용자가 '품명명' 조건을 입력하고 [검색/조회] 버튼을 클릭합니다.
    *   시스템은 조건에 맞는 품명 목록을 좌측 그리드에 표시합니다.

3.  **품명 상세 확인 (Select)**
    *   사용자가 좌측 목록에서 특정 품명을 클릭합니다.
    *   우측 상세 정보 영역에 해당 품명의 상세 데이터(코드, 명칭, 분류 정보 등)가 바인딩됩니다.

4.  **신규 등록 (New)**
    *   사용자가 [신규] 버튼을 클릭합니다.
    *   상세 정보 영역의 모든 입력 필드가 초기화(Clear)됩니다.
    *   '사용여부'는 자동으로 'YES'로 설정되며, 등록자/수정자 정보는 현재 로그인한 사용자 및 현재 시간으로 세팅됩니다.
    *   사용자가 필수 항목(품명코드, 품명명, 하태, 품목군, 품목 등)을 입력합니다.

5.  **저장 (Save)**
    *   사용자가 [저장] 버튼을 클릭합니다.
    *   시스템은 입력된 정보를 검증하고 DB에 저장(신규 Insert 또는 수정 Update)합니다.

---

## 2. UI Component 리스트

화면은 크게 **검색 영역(Search)**, **목록 영역(List - Left Block)**, **상세 정보 영역(Detail - Right Block)**으로 구분됩니다.

### 2.1 검색 영역 (Search Area)
| Component | Label | Type | Properties |
| :--- | :--- | :--- | :--- |
| Label | 품명명 | Text | Static Label |
| Input | - | Text Field | Editable (조건 입력) |
| Label | 사용여부 | Text | Static Label |
| Combo | - | Dropdown | Choice (전체/YES/NO 등) |
| Button | 검색/조회 | Button | Trigger Search Event |

### 2.2 목록 영역 (List Area)
| Component | Column Name | Type | Properties |
| :--- | :--- | :--- | :--- |
| Grid/Table | 품명 목록 | Grid | Read-only selection view |
| Column | 품명코드 | Text | ReadOnly (R) |
| Column | 품명명 | Text | ReadOnly (R) |
| Column | 사용여부 | Text | ReadOnly (R) |

### 2.3 상세 정보 영역 (Detail Area)
| Component | Label | Type | Properties |
| :--- | :--- | :--- | :--- |
| Button | 신규 | Button | Trigger New Event |
| Button | 저장 | Button | Trigger Save Event |
| Input | 품명코드 | Text Field | Editable (E), Mandatory (M) |
| Input | 품명명 | Text Field | Editable (E), Mandatory (M) |
| Combo | 하태 | Dropdown | Editable (E), Mandatory (M) |
| Combo | 품목군 | Dropdown | Editable (E), Mandatory (M) |
| Combo | 품목 | Dropdown | Editable (E), Mandatory (M) |
| Combo | 화종 | Dropdown | Editable (E) |
| Combo | 화종군 | Dropdown | Editable (E) |
| Input | 비고 | Text Field | Editable (E) |
| Combo | 사용여부 | Dropdown | Editable (E), Mandatory (M), Default: YES |
| Input | 등록자명 | Text Field | Read-only (System set), Mandatory |
| Input | 등록일시 | Text Field | Read-only (System set), Mandatory |
| Input | 수정자명 | Text Field | Read-only (System set), Mandatory |
| Input | 수정일시 | Text Field | Read-only (System set), Mandatory |

---

## 3. Data Mapping

화면의 UI 요소와 실제 데이터 속성(ID) 간의 매핑 정보입니다.

### 3.1 Search Condition
*   **품명명:** `goodsnmNmCd`
*   **사용여부:** `useYnCd`

### 3.2 List Data
*   **품명코드:** `goodsnmCdCd`
*   **품명명:** `goodsnmNm`
*   **사용여부:** `useYn`

### 3.3 Detail Data
*   **품명코드:** `goodsnmCdCd`
*   **품명명:** `goodsnmNmCd`
*   **하태:** `hataeCd` (기타코드 12번 참조)
*   **품목군:** `itemGrpCd` (기타코드 13번 참조)
*   **품목:** `itemCd` (기타코드 14번 참조)
*   **화종:** `hwajongCd` (기타코드 15번 참조)
*   **화종군:** `hwajongGrpCd` (기타코드 16번 참조)
*   **비고:** `rmkCd`
*   **사용여부:** `useYnCd`
*   **등록자명:** `regrNmCd`
*   **등록일시:** `regDate`
*   **수정자명:** `mdfrNmCd`
*   **수정일시:** `chgdt`

---

## 4. Logic Definition

### 4.1 초기화 로직 (Open Event)
*   **기능:** 화면 로드 시 콤보박스 데이터를 세팅합니다.
*   **세부 로직:**
    *   기타코드 12번(하태), 13번(품목군), 14번(품목), 15번(화종), 16번(화종군) 정보를 가져와 각각의 콤보박스에 바인딩합니다.
    *   검색 조건의 '사용여부' 콤보는 자동으로 "전체"를 선택합니다.
    *   등록일시/수정일시 기본값은 DB `sysdate`, 등록자/수정자 기본값은 현재 로그인 ID로 설정할 준비를 합니다.

### 4.2 조회 로직 (SearchGoodsnmListCmd)
*   **Trigger:** 검색 버튼 Click.
*   **Input:** 품명관리찾기조건 (`goodsnmNmCd`, `useYnCd`).
*   **Process:** 시스템 관리 품명정보를 검색.
*   **Output:** 품명코드, 품명명, 사용여부 리스트 (`goodsnmCdCd`, `goodsnmNm`, `useYn`).

### 4.3 상세 조회 로직 (RetrieveGoodsnmDtlInfoCmd)
*   **Trigger:** 목록 Grid에서 Row 선택.
*   **Input:** 선택된 행의 품명코드 (`goodsnmCdCd`).
*   **Process:** 마스터 코드로 관리하는 상세 품명코드 정보를 조회.
*   **Output:** 품명코드, 품명명, 하태, 품목군, 품목, 화종, 화종군, 비고, 사용여부, 등록자/일시, 수정자/일시 전체 상세 정보.

### 4.4 신규 로직 (New Event)
*   **Trigger:** 신규 버튼 Click.
*   **Process:**
    *   상세 정보의 모든 필드를 초기화(Clear)합니다.
    *   **사용여부:** 자동으로 'YES'로 설정합니다.
    *   **등록자/수정자 정보:** 현재 로그인 ID와 현재 시스템 일시로 화면에 표시합니다.
    *   **품명코드:** 신규 추가 시 선택한 품명목록의 품명코드를 상위품명코드로 등록한다는 규칙이 있으나, 화면설계서상 품명코드는 신규 입력 대상입니다. (설계서에 품명코드는 Editable로 명시됨).

### 4.5 저장 로직 (SaveGoodsnmDtlInfoCmd)
*   **Trigger:** 저장 버튼 Click.
*   **Input:** 상세 화면의 모든 입력 필드 데이터.
*   **Process:**
    *   **신규 등록 시:** 등록자/일시, 수정자/일시를 모두 현재 로그인 ID 및 시스템 일시로 저장합니다.
    *   **수정 시:** 수정자명, 수정일시를 현재 로그인 ID 및 시스템 일시로 갱신하여 저장합니다.
    *   필수 입력값(Mandatory)인 품명코드, 품명명, 하태, 품목군, 품목, 사용여부 등이 누락되지 않았는지 검증합니다.
    *   **Business Rule:** 품명코드는 시스템에서 자동 채번되는 일련번호(V5 무의미 코드)를 사용하거나 입력받습니다.

### 4.6 업무 규칙 (Business Rules)
*   **하태:** 화물 취급형태에 따른 대구분 (V2 무의미 코드).
*   **품목군:** 품명을 유형별로 묶은 관리 단위 (V3 무의미 코드).
*   **품목:** 노임 TARIFF 적용 기준으로 취급 형태에 따른 분류 (V4 무의미 코드).
*   **품명:** 제품 구분에 사용되는 이름, 계약요율 등록 시 사용 (V5 무의미 코드).
*   **화종:** 화종을 유형별로 묶은 단위 (V4 무의미 코드).
*   **화종군:** 품명을 화물 성질에 따라 묶은 단위 (V3 무의미 코드).
