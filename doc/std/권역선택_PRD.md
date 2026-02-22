# 권역선택 팝업 (Region Selection Popup) PRD

## 1. User Flow
사용자가 권역을 조회하고 선택하여 부모 화면으로 데이터를 전달하는 흐름은 다음과 같습니다.

1.  **팝업 진입**: 사용자가 메인 화면에서 권역 검색 기능을 호출하면 팝업이 오픈됩니다.
2.  **초기화 (Initialization)**:
    *   로그인 ID 등 기본 파라미터를 수신합니다.
    *   '사용여부' 조건이 기본값('Y' 또는 '전체')으로 설정됩니다.
3.  **조건 입력**: 사용자가 `권역코드`, `권역명`, `사용여부`, `법인` 등의 검색 조건을 입력합니다.
4.  **조회 실행**: 사용자가 **[검색]** 버튼을 클릭합니다.
5.  **목록 확인**: 시스템이 조건에 맞는 권역 목록을 조회하여 화면에 Tree 형태 또는 리스트로 표시합니다.
6.  **권역 선택**:
    *   **Case A (더블 클릭)**: 권역 목록에서 특정 항목을 더블 클릭합니다.
    *   **Case B (버튼 선택)**: 권역 목록에서 항목을 단건 선택(Click) 후, **[선택]** 버튼을 클릭합니다.
7.  **데이터 반환 및 종료**: 선택된 `권역코드`와 `권역명`이 호출한 부모 화면으로 반환되고 팝업이 닫힙니다.
8.  **닫기**: 선택 없이 취소하려면 **[닫기]** 버튼을 눌러 팝업을 종료합니다.

---

## 2. UI Component 리스트
화면설계서의 레이아웃과 정의서의 항목을 기반으로 구성된 UI 요소입니다.

### 2.1 조회 조건 영역 (Header/Search Area)
| 구분 | Label (Kor) | Label (Eng) | UI Type | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| **Input** | 권역코드 | RegionCode | Text Input | Editable |
| **Input** | 권역명 | RegionName | Text Input | Editable |
| **Select** | 사용여부 | UseYesOrNo | ComboBox | 기본값: 'Y' (사용중) <br> 옵션: 전체, Y, N |
| **Input** | 법인 | Corporation | Text Input + Search Icon | 법인코드 테이블 및 팝업 연동 |
| **Button** | 검색 | Search | Button | 아이콘 형태 (돋보기) |

### 2.2 목록 영역 (Body/List Area)
*   **표시 형태**: Tree 형태의 그리드
*   **컬럼 구성**:

| Header (Kor) | Data Field | 비고 |
| :--- | :--- | :--- |
| 권역코드 | regnCd | |
| 권역명 | regnNm | |
| 법인코드 | (corpCd) | |
| 법인명 | (corpNm) | |

### 2.3 하단 액션 영역 (Footer)
| 구분 | Label | Action | 비고 |
| :--- | :--- | :--- | :--- |
| **Button** | 닫기 | Close | 팝업 종료 |
| **Button** | 선택 | Select | 선택된 데이터 반환 |

---

## 3. Data Mapping
화면 UI 항목과 내부 데이터 속성 간의 매핑 정보입니다.

| 한글명 | 영문명 (ID) | 속성 | Type | 필수 여부 | 설명 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **권역코드** | `regnCd` | Editable | String | Optional | 조회 조건 및 반환 데이터 |
| **권역명** | `regnNm` | Editable | String | Optional | 조회 조건 및 반환 데이터 |
| **사용여부** | `useYn` | Editable | String (1) | **Required** | 'Y'(사용), 'N'(미사용) |
| **법인** | `corp` | Editable | String | Optional | 법인 조회 조건 |
| **본사** | (Unknown) | Editable | String | Optional | |

---

## 4. Logic Definition
각 이벤트 및 업무 규칙에 대한 상세 로직 정의입니다.

### 4.1 초기화 로직 (Open Event)
*   **Trigger**: 화면 로딩 시 (Open)
*   **Input**: 로그인 ID (`LoginId`)
*   **Logic**:
    *   조회 조건의 `사용여부(useYn)` 값을 설정한다.
    *   **규칙**: 기본적으로 '사용 중(Y)'인 코드만 조회하도록 설정하되, '전체' 조회가 가능하도록 수정할 수 있어야 한다.

### 4.2 조회 로직 (Retrieve)
*   **Trigger**: [검색] 버튼 클릭 (`Click`)
*   **Input**: 권역조회조건 (`regnCd`, `regnNm`, `useYn`, `corp`)
*   **Logic**:
    *   입력된 법인코드가 있다면 공통 법인 테이블 또는 법인 팝업을 참조한다.
    *   조건에 해당하는 하위 권역 목록을 조회한다.
    *   결과 데이터를 **Tree 형태**로 화면에 Display 한다.
*   **Output**: 권역 목록 (`List`)

### 4.3 선택 및 반환 로직 (Select & Return)
*   **Trigger A**: 그리드 내 항목 **더블 클릭** (`DoubleClick`)
*   **Trigger B**: 항목 선택 후 **[선택] 버튼 클릭** (`Click`)
*   **Input**: 선택된 행의 `권역코드`
*   **Logic**:
    *   선택된 행의 데이터(`권역코드`, `권역명`)를 추출한다.
    *   부모 화면으로 해당 데이터를 리턴(Return)하고 팝업을 닫는다.

### 4.4 화면 제어 및 공통 규칙
*   **Display**: 등록일시, 수정일시는 DB `sysdate`를 기본값으로 한다.
*   **사용자**: 등록자, 수정자는 현재 로그인 사용자를 기본값으로 한다.
*   **사용여부 필터**: 사용여부는 항상 사용 중인 건만 조회되도록 설정하되, 사용자가 수정하여 전체 조회가 가능해야 한다.
