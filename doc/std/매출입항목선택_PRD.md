# PRD: 매출입항목 선택 팝업

## 1. User Flow (사용자 흐름)

사용자가 상위 화면에서 매출입항목 검색을 요청했을 때부터 데이터를 선택하여 복귀하는 과정입니다.

1.  **팝업 진입**: 사용자가 부모 화면(호출 화면)에서 돋보기 아이콘 또는 검색 버튼을 클릭하여 [매출입항목 선택 팝업]을 호출합니다.
    *   *System*: 로그인 ID를 파라미터로 받으며 팝업을 오픈합니다.
    *   *System*: 초기 조회 조건 중 '사용여부'는 'Y'(사용 중)로 기본 설정되어 로드됩니다.
2.  **조회 조건 입력**: 사용자가 원하는 검색 조건을 입력합니다.
    *   매출입항목코드, 명칭, 법인, 운송여부, 보관여부 등을 입력 또는 선택합니다.
    *   법인 검색 시 별도의 법인 팝업을 호출할 수 있습니다.
3.  **목록 조회**: [검색] 버튼을 클릭합니다.
    *   *System*: 입력된 조건(위탁업체 관리 항목 등)에 일치하는 매출입항목 목록을 그리드에 표시합니다.
4.  **항목 선택**: 조회된 목록(Grid)에서 원하는 매출입항목 행(Row)을 선택합니다.
5.  **확정 및 복귀**: 목록을 더블 클릭하거나 선택 후 확인 동작(선택 이벤트)을 수행합니다.
    *   *System*: 선택된 매출입항목 정보(코드, 명칭 등)를 부모 화면으로 전달하고 팝업을 자동으로 닫습니다.
6.  **취소/닫기**: [닫기] 버튼을 클릭하면 값 전달 없이 팝업을 종료합니다.

---

## 2. UI Component 리스트

화면설계서의 Layout과 항목 설명을 기반으로 구성된 UI 요소입니다.

### 2.1 조회 영역 (Search Condition)
| Label (한글) | UI Type | Field Name (Eng) | 속성/기능 |
| :--- | :--- | :--- | :--- |
| **매출입항목코드** | Input Text | `sellBuyAttrCd` | Editable |
| **매출입항목명** | Input Text | `sellBuyAttrNm` | Editable |
| **사용여부** | Select Box | `useYn` | 기본값: Y (전체/Y/N 선택 가능) |
| **법인** | Input Text + Button | `corp` | 돋보기 아이콘 클릭 시 법인 검색 팝업 호출 |
| **운송여부** | Select Box | `tranYn` | Editable |
| **보관여부** | Select Box | `strgYn` | Editable |
| **검색** | Button | - | 조회 이벤트 트리거 |

### 2.2 목록 영역 (Grid List)
| Header (한글) | UI Type | Field Name (Eng) | 설명 |
| :--- | :--- | :--- | :--- |
| **매출입항목코드** | Text | `sellBuyAttrCd` | |
| **매출입항목명** | Text | `sellBuyAttrNm` | |
| **영문매출입항목명** | Text | `engSellBuyAttrNm` | |
| **단축명** | Text | `rdtnNm` | |
| **상위매출입항목코드** | Text | `upperSellBuyAttrCd` | |
| **상위매출입항목명** | Text | `upperSellBuyAttrNm` | |

### 2.3 하단 영역 (Footer)
| Label | UI Type | 기능 |
| :--- | :--- | :--- |
| **닫기** | Button | 팝업 종료 |

---

## 3. Data Mapping

화면 UI 항목과 내부 데이터 속성 간의 매핑 정의입니다.

### 3.1 Input Data (조회 조건)
| 한글명 | 영문 속성명 (Variable) | 데이터 타입 | 비고 |
| :--- | :--- | :--- | :--- |
| 매출입항목코드 | `sellBuyAttrCd` | String | 검색 키워드 |
| 매출입항목명 | `sellBuyAttrNm` | String | 검색 키워드 |
| 사용여부 | `useYn` | String (1) | 'Y' or 'N' (Default: 'Y') |
| 법인 | `corp` | String | 법인 코드 |
| 운송여부 | `tranYn` | String (1) | |
| 보관여부 | `strgYn` | String (1) | |

### 3.2 Output Data (조회 결과 리스트)
| 한글명 | 영문 속성명 (Variable) | 소스 매핑 |
| :--- | :--- | :--- |
| 상위매출입항목코드 | `upperSellBuyAttrCd` | `UpperSellingBuyingAttributeCode` |
| 상위매출입항목명 | `upperSellBuyAttrNm` | `UpperSellingBuyingAttributeName` |
| 매출입항목코드 | `sellBuyAttrCd` | `SellingBuyingAttributeCode` |
| 매출입항목명 | `sellBuyAttrNm` | `SellingBuyingAttributeName` |
| 영문매출입항목명 | `engSellBuyAttrNm` | `EnglishSellingBuyingAttributeName` |
| 단축명 | `rdtnNm` | `ReductionName` |

### 3.3 Return Data (부모 화면 전달 데이터)
선택 이벤트 발생 시 부모 창으로 반환되는 데이터입니다.
*   **매출입항목번호 (Code)**
*   **매출입항목명 (Name)**
*   **화주매출입항목번호**
*   **화주명**

---

## 4. Logic Definition

화면의 주요 기능 동작 및 제어 로직에 대한 상세 정의입니다.

### 4.1 초기화 로직 (Initialization)
*   **Open Event**: 팝업 오픈 시 로그인 ID(`Login Id`)를 수신합니다.
*   **Default Value**: '사용여부' 콤보박스는 'Y'(사용 중)로 기본 선택되어야 합니다. 사용자는 이를 변경하여 전체 또는 미사용 건도 조회할 수 있어야 합니다.

### 4.2 조회 로직 (Search Logic)
*   **Trigger**: [검색] 버튼 클릭 시 수행합니다.
*   **Validation**: 등록된 매출입항목 데이터만 조회되어야 합니다.
*   **Process**:
    1.  사용자가 입력한 검색 조건(코드, 명칭, 법인, 용도 등)을 수집합니다.
    2.  위탁업체에서 관리하는 매출입항목 중 조건에 부합하는 데이터를 쿼리합니다.
    3.  결과를 그리드(List)에 바인딩합니다.

### 4.3 선택 및 반환 로직 (Selection logic)
*   **Trigger**: 그리드 내 특정 행(Row) 선택 후 [확인/선택] 동작 수행 (또는 더블클릭).
*   **Process**:
    1.  선택된 행의 `매출입항목코드`, `매출입항목명` 등의 데이터를 추출합니다.
    2.  부모 화면(Opener)에 해당 데이터를 파라미터로 전달합니다.
    3.  데이터 전달 후 팝업 창을 즉시 닫습니다 (`window.close()` 등).

### 4.4 예외 처리 및 기타 (Exception & ETC)
*   **법인 조회**: 법인 입력란 옆의 돋보기 버튼 클릭 시, 공통 법인 팝업을 호출하여 법인 코드를 선택할 수 있도록 합니다.
*   **Read-Only**: 목록(Grid) 영역의 데이터는 수정할 수 없으며(Read-Only), 조회된 데이터의 선택만 가능합니다.
