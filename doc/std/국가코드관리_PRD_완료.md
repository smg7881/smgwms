# PRD: 국가코드관리 (Country Code Management) 

## 1. User Flow
사용자의 주요 업무 흐름은 조회, 상세 확인, 신규 등록, 수정, 저장으로 구성됩니다.

1.  **국가 목록 조회**
    *   사용자는 검색 조건(국가명)을 입력하고 `Search` 버튼을 클릭합니다.
    *   시스템은 조건에 맞는 국가 코드 목록(국가코드, 국가명, 사용여부)을 좌측 그리드에 표시합니다.

2.  **상세 정보 확인**
    *   사용자가 좌측 목록에서 특정 국가를 클릭합니다.
    *   우측 상세 영역에 선택된 국가의 상세 정보(영문명, 지역코드, 전화번호, 등록/수정 정보 등)가 출력됩니다.

3.  **신규 국가 등록**
    *   사용자가 `신규` 버튼을 클릭합니다.
    *   우측 상세 입력 필드가 초기화되며, `사용여부`는 자동으로 'YES'로 설정되고 `국가지역코드`는 기타코드(139번) 정보로 셋팅됩니다.
    *   사용자는 국가코드(국제 공인 코드 기준), 국가명, 영문명 등을 입력합니다.
    *   법인 정보 입력 시 `법인명 찾기` 버튼을 통해 팝업에서 법인을 검색하고 선택합니다.

4.  **정보 저장 (등록/수정)**
    *   필수 입력값 확인 후 `저장` 버튼을 클릭합니다.
    *   신규 등록 또는 수정된 정보가 DB에 저장되며, 등록자/수정자 정보 및 일시가 시스템 값으로 자동 업데이트됩니다.

---

## 2. UI Component 리스트
화면은 크게 검색 영역(Header), 목록 영역(Left), 상세 정보 영역(Right)으로 구분됩니다.

### 2.1 검색 영역 (Top Header)
| Label | Type | UI Control | Description |
| :--- | :--- | :--- | :--- |
| **국가명** | Input | Text Box | 검색할 국가명 입력 (`ctryNmCd`) |
| **Search** | Button | Button | 국가 목록 조회 트리거 |

### 2.2 목록 영역 (Left Block)
| Header | Type | Data Binding | Description |
| :--- | :--- | :--- | :--- |
| **국가코드** | Text | `ctryCdCd` | ReadOnly |
| **국가명** | Text | `ctryNm` | ReadOnly |
| **사용여부** | Text | `useYn` | ReadOnly |

### 2.3 상세 정보 영역 (Right Block)
| Label | Type | Mandatory | UI Control | Description |
| :--- | :--- | :--- | :--- | :--- |
| **신규** | Action | N/A | Button | 입력 폼 초기화 |
| **저장** | Action | N/A | Button | 데이터 저장 (Insert/Update) |
| **국가코드** | Input | **Y** | Text Box | `ctryCdCd`. 국제 공인 코드 기준 직접 입력 |
| **국가명** | Input | **Y** | Text Box | `ctryNmCd` |
| **국가영문명** | Input | **Y** | Text Box | `ctryEngNmCd` |
| **국가지역코드** | Input | **Y** | Text Box | `ctryArCdCd`. 기타코드 139번 정보 로드 |
| **국가전화번호** | Input | N | Text Box | `ctryTelno` |
| **법인코드** | Input | N | Text Box | `corpCd`. 팝업을 통해 입력 |
| **법인명** | Input | N | Text Box | `corpNm` |
| **법인명 찾기** | Action | N/A | Button | 법인선택 팝업 호출 |
| **사용여부** | Select | **Y** | Dropdown | `useYnCd`. (YES/NO) |
| **등록자명** | Text | **Y** | Text (ReadOnly) | `regrNmCd`. 시스템 로그인 사용자 자동 입력 |
| **등록일시** | Text | **Y** | Text (ReadOnly) | `regDate`. YYYY-MM-DD 포맷 |
| **수정자명** | Text | **Y** | Text (ReadOnly) | `mdfrNmCd` |
| **수정일시** | Text | **Y** | Text (ReadOnly) | `chgdt`. YYYY-MM-DD 포맷 |

---

## 3. Data Mapping
화면의 필드와 데이터 속성 간의 매핑 정보입니다.

*   **Primary Key:** 국가코드 (`ctryCdCd`)
*   **Data Source:**
    *   **국가 목록:** 마스터 코드 관리 테이블
    *   **국가지역코드:** 기타코드 139번 참조
    *   **법인 정보:** 법인선택 팝업(`CorpSlcPopup.jsp`) 결과값 매핑

| 한글명 | 영문명 (Screen ID) | 속성 | 비고 |
| :--- | :--- | :--- | :--- |
| 국가코드 | `ctryCdCd` | Editable (PK) | 세관신고용, UN코드 등 표준 코드 사용 |
| 국가명 | `ctryNmCd` / `ctryNm` | Editable | 검색 조건 및 상세 정보 |
| 국가영문명 | `ctryEngNmCd` | Editable | |
| 국가지역코드 | `ctryArCdCd` | Editable | Default: 기타코드 139번 |
| 국가전화번호 | `ctryTelno` | Editable | |
| 법인코드 | `corpCd` | Editable | 팝업 리턴값 |
| 법인명 | `corpNm` | Editable | 팝업 리턴값 |
| 사용여부 | `useYnCd` / `useYn` | Editable | 신규 시 Default: YES |
| 등록자/수정자 | `regrNmCd` / `mdfrNmCd` | ReadOnly | Current Login ID |
| 등록/수정일시 | `regDate` / `chgdt` | ReadOnly | DB Sysdate |

---

## 4. Logic Definition
화면 동작 및 데이터 처리를 위한 상세 로직 정의입니다.

### 4.1 초기화 로직 (Open)
*   화면 로딩 시 `국가명` 검색 조건은 전체 조회 상태로 설정합니다.
*   `국가지역코드` 데이터 구성을 위해 기타코드 139번 정보를 사전에 조회하여 가져옵니다.

### 4.2 조회 로직 (Search)
*   사용자가 입력한 `국가명`을 조건으로 시스템의 마스터 국가코드 정보를 조회합니다.
*   조회된 데이터는 좌측 목록 그리드에 바인딩됩니다.

### 4.3 상세 조회 로직 (List Click)
*   목록에서 행을 클릭하면 해당 `국가코드`를 키(Key)로 상세 정보를 조회합니다.
*   조회된 데이터(국가명, 영문명, 지역코드, 전화번호, 법인정보, 등록/수정정보 등)를 우측 상세 영역 컴포넌트에 매핑합니다.

### 4.4 신규 로직 (New Button)
*   우측 상세 정보의 모든 입력 필드를 Clear 합니다.
*   **Default Value 설정:**
    *   `사용여부`: 'YES'로 자동 설정.
    *   `등록자명/수정자명`: 현재 로그인한 사용자 ID/Name.
    *   `등록일시/수정일시`: 현재 시스템 일시.
    *   `국가지역코드`: 기타코드 139번 정보.

### 4.5 법인 선택 팝업 로직 (Popup)
*   `법인선택` 버튼 클릭 시 공통 팝업(`CorpSlcPopup.jsp`)을 호출합니다.
*   **조회 결과 처리:**
    *   조회된 값이 1개일 경우: 팝업 없이 즉시 해당 법인코드와 법인명을 화면에 맵핑합니다.
    *   조회된 값이 없거나 다수일 경우: 팝업창을 띄워 사용자가 선택하게 하며, 선택된 값을 화면에 반환합니다.

### 4.6 저장 로직 (Save Button)
*   필수 입력값(`국가코드`, `국가명`, `국가영문명`, `국가지역코드`, `사용여부` 등)을 검증합니다.
*   **신규 등록 시:** 입력된 정보를 Insert 하며, 등록자/수정자 정보를 현재 로그인 ID로, 일시를 Sysdate로 저장합니다.
*   **수정 시:** 변경된 정보를 Update 하며, 수정자 정보를 현재 로그인 ID로, 수정일시를 Sysdate로 갱신합니다.
