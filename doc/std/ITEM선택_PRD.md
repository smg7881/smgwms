# Product Requirements Document (PRD): ITEM 선택 팝업

## 1. User Flow (화면 흐름)

사용자가 상위 업무 화면(예: 주문 등록 등)에서 특정 ITEM을 입력하거나 검색해야 할 때 발생하는 흐름입니다.

1.  **팝업 호출 (Entry Point)**
    *   사용자가 부모 창에서 'ITEM 검색' 돋보기 버튼을 클릭합니다.
    *   **ITEM 선택 팝업**이 모달(Modal) 형태로 오픈됩니다. 이때 로그인한 사용자의 ID 정보가 전달됩니다.
2.  **조회 조건 입력**
    *   팝업이 열릴 때 **사용여부**는 기본값 'Y'로 설정되어 있습니다.
    *   사용자는 `화주 ITEM 번호`, `품명번호` 등을 직접 입력하거나, `고객명` 옆의 검색 버튼([C]고객명 찾기)을 눌러 거래처 선택 팝업을 띄웁니다.
    *   거래처 선택 팝업에서 거래처를 선택하면 `화주` 코드와 `고객명`이 자동으로 입력됩니다.
3.  **목록 검색**
    *   조건 입력 후 **[검색]** 버튼을 클릭합니다.
    *   로그인한 위탁업체(화주)에 등록된 ITEM 중 조건에 맞는 목록이 하단 그리드에 표시됩니다.
4.  **ITEM 선택 및 복귀**
    *   사용자가 조회된 목록 중 원하는 ITEM 행(Row)을 클릭합니다.
    *   선택된 ITEM 정보(번호, 명칭, 화주 정보 등)가 부모 창(Parent Window)의 입력 필드로 전달됩니다.
    *   팝업이 자동으로 닫힙니다.

---

## 2. UI Component List (Rails 8 Based)

Rails 8의 최신 기능(Turbo Frames, Stimulus, Propshaft 등)을 활용한 UI 컴포넌트 구조입니다.

| 구분 | 컴포넌트 명 | Rails 8 구현 방안 / 역할 |
| :--- | :--- | :--- |
| **Container** | `ItemSelectionModal` | `Turbo Frame`을 사용하여 부모 창 내에서 비동기로 로드되는 모달 컨테이너. |
| **Search Form** | `SearchFilterComponent` | `form_with` 헬퍼 사용. 조회 조건 입력 필드 그룹. |
| **Input Field** | `TextInput` | `custITEMNo`, `goodsnmNo` 등을 입력받는 표준 텍스트 필드. |
| **Search Button** | `CustomerSearchBtn` | `Stimulus Controller`를 연결하여 별도의 `BzacSlc` 팝업을 호출하는 버튼 (`[C]고객명 찾기`). |
| **Select Box** | `UseYnSelect` | 사용여부(Y/N)를 선택하는 드롭다운. 기본값 `selected: 'Y'`. |
| **Action Button** | `SubmitButton` | "검색" 버튼. 클릭 시 `RetrieveITEMCmd` 액션을 트리거하여 `Turbo Stream`으로 목록 영역만 갱신. |
| **Data Grid** | `ItemResultTable` | 조회 결과를 표시하는 테이블. 각 행(`<tr>`)은 클릭 가능하며(`data-action="click->selection#pick"`), 선택 시 부모 창으로 데이터 전송 이벤트 발생. |
| **Close Button** | `CloseButton` | "닫기" 버튼. 모달을 닫는 Stimulus 액션 연결. |

---

## 3. Data Mapping

화면의 입력 필드 및 목록 컬럼과 DB/메타데이터 간의 매핑 정의입니다. 설계서에 명시된 영문 속성명을 기준으로 합니다.

### 3.1 조회 조건 (Search Condition)
| 한글명 | 영문 속성명 (Variable) | 데이터 타입 | 설명 및 속성 |
| :--- | :--- | :--- | :--- |
| 화주 ITEM 번호 | `custITEMNo` | String | Editable. 부분 일치 검색 가능성 있음. |
| 품명번호 | `goodsnmNo` | String | Editable. |
| 화주(코드) | `cust` | String | Editable. 거래처 선택 팝업에서 리턴받음. |
| 고객명 | `custNm` | String | Editable. 거래처 선택 팝업에서 리턴받음. |
| 사용여부 | `useYn` | Char(1) | Choice (Select Box). 기본값 'Y'. 전체/Y/N 선택 가능. |

### 3.2 조회 목록 (Result List)
| 한글명 | 영문 속성명 (Variable) | 설명 |
| :--- | :--- | :--- |
| 화주 ITEM 번호 | `custITEMNo` | 그리드 출력 항목. |
| 화주 ITEM명 | `custITEMNm` | 그리드 출력 항목. |
| 화주명 | `custNm` | 그리드 출력 항목. |
| 하태명 | `hataeNm` | 그리드 출력 항목. |
| 품목명 | `itemNm` | 그리드 출력 항목. |
| 품명명 | `goodsnmNm` | 그리드 출력 항목. |
| 화종명 | `hwajongNm` | 그리드 출력 항목. |

---

## 4. Logic Definition (Business Logic)

버튼 클릭 및 화면 초기화 시 발생하는 상세 로직입니다.

### 4.1 초기화 로직 (On Load / Open Event)
*   **로그인 정보 수신**: 팝업 오픈 시 로그인한 사용자의 ID와 소속 위탁업체 정보를 수신합니다.
*   **기본값 설정**: `사용여부(useYn)` 검색 조건을 'Y'(사용중)로 기본 설정합니다.
*   **데이터 범위 제한**: 로그인한 위탁업체에서 등록한 ITEM과 화주만 조회되도록 쿼리 스코프(Scope)를 제한합니다.

### 4.2 거래처 선택 버튼 로직 ([C]고객명 찾기)
*   **Trigger**: 돋보기 아이콘 또는 버튼 클릭.
*   **Action**: `거래처선택(BzacSlc.jsp)` 화면을 모달 또는 팝업으로 오픈합니다.
*   **Callback**: 거래처 선택 팝업에서 거래처가 선택되면 반환된 `거래처코드`, `거래처명`을 각각 본 화면의 `cust`, `custNm` 필드에 바인딩합니다.

### 4.3 검색 버튼 로직 (ITEM 조회)
*   **Trigger**: [검색] 버튼 클릭 (`RetrieveITEMCmd`).
*   **Validation**: 입력된 조회 조건의 유효성을 체크합니다(설계서상 필수 값 명시는 없으나 일반적인 텍스트 필터링 적용).
*   **Query Execution**:
    *   `SELECT * FROM ITEMS WHERE ...`
    *   조건 1: `custITEMNo`, `goodsnmNo`가 입력된 경우 `LIKE` 검색.
    *   조건 2: `useYn` 필터 적용 (Y 또는 N, 전체).
    *   **필수 보안 조건**: `WHERE consignor_id = current_user.consignor_id` (로그인한 위탁업체의 데이터만 조회).
*   **Output**: 조회된 결과를 `ITEM 목록` 그리드에 렌더링합니다.

### 4.4 ITEM 선택 로직 (Grid Row Click)
*   **Trigger**: 목록 내 특정 ITEM 행 클릭.
*   **Data Transfer**: 선택된 행의 `ITEM번호`, `ITEM명`, `화주ITEM번호`, `화주명` 데이터를 추출합니다.
*   **Callback**: 부모 창(Opener)에 정의된 수신 함수를 호출하여 데이터를 전달하거나, 부모 창의 특정 필드 값을 업데이트합니다.
*   **Close**: 데이터 전달 후 팝업을 즉시 닫습니다.
