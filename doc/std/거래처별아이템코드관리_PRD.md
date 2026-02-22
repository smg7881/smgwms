# PRD: 거래처별 아이템코드 관리 (Item Code Management by Business Partner)

## 1. User Flow (화면 흐름)

사용자의 업무 수행 절차에 따른 화면 간의 유기적인 흐름은 다음과 같습니다.

1.  **화면 진입 및 초기화**
    *   사용자가 화면에 진입하면 시스템은 로그인 ID와 현재 날짜(Sysdate)를 확인합니다.
    *   사용여부, 위험물여부 등 각종 여부 필드 및 단위(중량, 수량, 온도 등) 콤보박스 데이터를 공통코드(기타코드 19~24번)에서 조회하여 세팅합니다.
2.  **아이템 검색 (Search)**
    *   사용자는 **[아이템관리찾기조건]** 영역에서 거래처, 아이템코드, 아이템명, 사용여부를 입력합니다.
    *   거래처 입력 시 돋보기 아이콘을 클릭하면 **[거래처선택 팝업]**이 호출되어 값을 선택할 수 있습니다.
    *   '검색' 버튼 클릭 시 좌측 **[아이템목록]** 그리드에 검색 결과가 바인딩됩니다.
3.  **상세 정보 조회 (View Detail)**
    *   좌측 목록에서 특정 행(Row)을 클릭하면, 우측 **[아이템상세정보]** 영역에 해당 아이템의 상세 데이터가 조회됩니다.
4.  **신규 등록 (Create)**
    *   '행추가(신규)' 버튼 클릭 시 우측 상세 입력 폼이 초기화됩니다.
    *   이때 **사용여부**는 자동으로 'YES'로 설정되며, 등록자/수정자는 현재 사용자, 일시는 현재 시간으로 기본 세팅됩니다.
    *   품명 입력 시 **[품명선택 팝업]**을 호출하여 값을 입력받습니다.
5.  **저장 및 수정 (Save/Update)**
    *   필수 입력값(아이템코드, 아이템명, 거래처 등)을 작성 후 '저장' 버튼을 클릭합니다.
    *   시스템은 신규 데이터는 Insert, 기존 데이터는 Update 처리합니다.
6.  **삭제 (Delete)**
    *   '행삭제' 버튼 클릭 시, 화면상에서 행이 삭제됩니다. 단, DB에 이미 저장된 데이터인 경우 실제 삭제하지 않고 **사용여부**만 '아니오(No)'로 업데이트하여 비활성화 처리합니다.

---

## 2. UI Component List (Rails 8 Based)

Rails 8의 최신 기능(Turbo, Stimulus)을 활용한 UI 컴포넌트 구성안입니다.

| 영역 | 컴포넌트 명 (Rails/HTML) | 설명 및 용도 |
| :--- | :--- | :--- |
| **Layout** | `SplitPanes` or `Grid Layout` | 좌측 목록(List)과 우측 상세(Detail)를 나누는 2단 레이아웃. |
| **Search** | `SearchForm` (`form_with`) | 검색 조건을 입력하는 상단 폼. |
| **Input** | `AutocompleteField` | 거래처, 품명 검색 시 팝업 대신 또는 병행하여 사용할 자동완성 필드 (Stimulus Controller 활용). |
| **List** | `TurboFrame` (`<turbo-frame id="item_list">`) | 검색 결과에 따라 페이지 전체 리로드 없이 목록만 갱신하는 영역. |
| **List** | `DataTable` | 아이템 목록 표시. 정렬 및 행 선택 이벤트(`click->detail-loader#load`) 처리. |
| **Detail** | `TurboFrame` (`<turbo-frame id="item_detail">`) | 목록 선택 시 우측 상세 폼을 비동기로 불러오는 영역. |
| **Form** | `SelectBox` (Combobox) | 단위(kg, m, CBM 등) 및 Y/N 선택용 드롭다운. |
| **Form** | `NumberField` | 중량, 부피, 길이 등 숫자 입력 필드 (Client-side validation 포함). |
| **Modal** | `TurboStream Modal` | [거래처선택], [품명선택] 팝업을 띄우기 위한 모달 컴포넌트. |
| **Action** | `ButtonGroup` | 조회, 저장, 행추가, 행삭제 버튼 그룹. |

---

## 3. Data Mapping (DB Metadata)

화면의 입력 필드와 매핑되는 DB 컬럼 및 속성 정의입니다.

| 한글명 | 영문명 (Variable) | 속성 (Type) | 필수 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **[검색조건]** | | | | |
| 거래처 | `bzac` | String | | 팝업 조회 |
| 거래처명 | `bzacNm` | String | | ReadOnly |
| 아이템코드 | `itemCd` | String | | |
| 아이템명 | `itemNm` | String | | |
| 사용여부 | `useYn` | String | | |
| **[상세정보]** | | | | |
| 아이템코드 | `itemCd` | String | **M** | Key |
| 아이템명 | `itemNmCd` (오기 추정: `itemNm`) | String | **M** | |
| 거래처코드 | `bzacCd` | String | **M** | |
| 품명코드 | `goodsnmCd` | String | **M** | 팝업 조회 |
| 품명명 | `goodsnmNm` | String | **M** | |
| 위험물여부 | `dangerYnCd` | Char(1) | **M** | Y/N |
| 패키징여부 | `pngYnCd` | Char(1) | **M** | Y/N |
| 다단적재여부 | `mstairLadingYnCd` | Char(1) | **M** | Y/N |
| 인터페이스여부 | `ifYnCd` | Char(1) | **M** | Y/N |
| 중량단위코드 | `wgtUnitCd` | String | | 공통코드(24) |
| 수량단위코드 | `qtyUnitCd` | String | | 공통코드(21) |
| 온도단위코드 | `tmptUnitCd` | String | | 공통코드(22) |
| 부피단위코드 | `volUnitCd` | String | | 공통코드(23) |
| 기본단위코드 | `basisUnitCd` | String | | 공통코드(20) |
| 길이단위코드 | `lenUnitCd` | String | | 공통코드(19) |
| 포장수량 | `pckgQty` | Number | | |
| 총중량 | `totWgt(KG)` | Number | | |
| 순중량 | `netWgt(KG)` | Number | | |
| 용기온도 | `vesselTmpt(C)` | Number | | |
| 용기가로 | `vesselWidth(M)` | Number | | |
| 용기세로 | `vesselVert(M)` | Number | | |
| 용기높이 | `vesselHght(M)` | Number | | |
| 용기부피 | `vesselVol(CBM)` | Number | | |
| 사용여부 | `useYnCd` | Char(1) | **M** | 기본값: YES |
| 제조원명 | `prodNmCd` | String | **M** | |
| 등록자/일시 | `regrNmCd`, `regDate` | String/Date | **M** | System Auto |
| 수정자/일시 | `mdfrNmCd`, `chgdt` | String/Date | **M** | System Auto |

---

## 4. Logic Definition (비즈니스 로직)

각 버튼 및 이벤트 발생 시 수행해야 하는 상세 로직입니다.

### 4.1. 초기화 (Initialize)
*   **Trigger:** 화면 Open 시.
*   **Logic:**
    *   로그인 사용자 ID 및 현재 날짜를 세션/시스템 시간으로부터 확보.
    *   **공통코드 로드:** 다음 코드 그룹을 조회하여 콤보박스에 바인딩 (기본값: '전체' 또는 선택 없음).
        *   중량단위(24), 수량단위(21), 온도단위(22), 부피단위(23), 기본단위(20), 길이단위(19).

### 4.2. 아이템 목록 조회 (Search)
*   **Trigger:** 검색 버튼 클릭 (`SearchItemListCmd`).
*   **Logic:**
    *   입력된 조건(거래처, 아이템코드 등)을 기반으로 시스템 관리 아이템 정보를 Query.
    *   조회된 리스트를 좌측 그리드에 표시.

### 4.3. 상세 정보 조회 (Select Detail)
*   **Trigger:** 목록 행 클릭 (`RetrieveItemDtlInpoCmd`).
*   **Logic:**
    *   선택된 `아이템코드`를 Key로 상세 정보를 DB에서 조회.
    *   조회된 데이터를 우측 입력 필드에 매핑.

### 4.4. 행추가 (Add Row)
*   **Trigger:** 행추가 버튼 클릭.
*   **Logic:**
    *   우측 상세 폼의 모든 입력 필드를 Clear.
    *   **Default Value Setting:**
        *   `사용여부`: **'YES'**로 강제 설정.
        *   `등록자/수정자`: 현재 로그인 사용자 ID 표시.
        *   `등록일시/수정일시`: 현재 시스템 시간(Sysdate) 표시.
    *   상태를 '신규(Insert)' 모드로 전환.

### 4.5. 행삭제 (Logical Delete)
*   **Trigger:** 행삭제 버튼 클릭.
*   **Logic:**
    *   **Case 1 (신규 행):** DB에 저장되지 않은 상태라면 화면 목록에서 즉시 제거 (Clear).
    *   **Case 2 (기존 데이터):** DB에 존재하는 데이터라면 레코드를 삭제(DELETE)하지 않음.
        *   대신 `사용여부` 필드 값을 **'아니오(No)'**로 변경하여 Update 대기 상태로 만듦.
        *   사용자에게 수정(사용여부 변경)됨을 알리는 메시지 처리.

### 4.6. 저장 (Save)
*   **Trigger:** 저장 버튼 클릭 (`SaveItemDtlInfoCmd`).
*   **Logic:**
    *   **Validation:** 필수 항목(M) 입력 여부 체크.
    *   **분기 처리:**
        *   신규 등록 건: `INSERT` 수행. (`등록자/일시`, `수정자/일시` 모두 현재 값으로 저장).
        *   기존 수정 건: `UPDATE` 수행. (`수정자`, `수정일시`만 현재 값으로 갱신).
    *   저장 완료 후 재조회 또는 성공 메시지 출력.
