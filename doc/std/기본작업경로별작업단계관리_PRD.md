# 기본작업경로별 작업단계 관리 (PRD)

## 1. User Flow (사용자 흐름)

사용자가 화면에 진입하여 데이터를 조회, 등록, 수정, 삭제, 저장하는 전체적인 흐름은 다음과 같습니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 화면에 접속하면 `Open` 이벤트가 발생합니다.
    *   검색 조건의 '사용여부' 콤보박스가 '전체'로 자동 설정됩니다.
    *   공통코드(기타코드 07, 08, 09, 10, 12)를 로드하여 관련 콤보박스(화종, 작업유형, 작업단계 Level 등)를 세팅합니다.

2.  **작업경로 목록 조회 (Search)**
    *   사용자가 검색 조건(작업경로코드, 작업경로명, 사용여부)을 입력하고 `조회` 버튼을 클릭합니다.
    *   시스템은 조건에 맞는 '작업경로목록'을 좌측 그리드에 표시합니다.

3.  **상세 정보 확인 (Select)**
    *   좌측 '작업경로목록'에서 특정 행을 클릭합니다.
    *   우측 상단에 해당 경로의 '작업경로상세정보'가 표시됩니다.
    *   우측 하단에 해당 경로에 속한 '작업경로별작업단계목록'이 조회됩니다.

4.  **신규 등록 및 수정 (Create & Update)**
    *   **작업경로 추가:** 좌측 하단의 `행추가` 버튼을 클릭하면 우측 상단 상세정보 필드가 초기화되며, 등록자/일시가 현재 기준으로 세팅됩니다.
    *   **작업단계 추가:** 우측 하단의 `행추가` 버튼을 클릭하면 작업단계 목록에 신규 행이 추가되며 입력 필드가 활성화됩니다.
    *   **데이터 입력:** 필수 항목(코드, 명칭, 화종, 작업유형 등)을 입력하거나 수정합니다. 계층형 콤보박스(화종→작업유형1→작업유형2) 로직에 따라 데이터를 선택합니다.

5.  **삭제 (Delete)**
    *   **행삭제:** 목록에서 행을 선택 후 `행삭제` 버튼을 클릭합니다.
    *   신규 행인 경우 목록에서 즉시 삭제되며, DB에 존재하는 데이터인 경우 `사용여부`가 '아니오(No)'로 변경됩니다 (Soft Delete).

6.  **저장 (Save)**
    *   우측 하단의 `저장` 버튼을 클릭합니다.
    *   신규 등록 또는 수정된 마스터(작업경로) 및 디테일(작업단계) 데이터가 DB에 반영됩니다.

---

## 2. UI Component 리스트

화면은 크게 검색 영역, 좌측 목록 영역, 우측 상세정보 영역, 우측 단계목록 영역으로 구성됩니다.

### 2.1 검색 영역 (Top)
| Component | Type | Label | Description |
| :--- | :--- | :--- | :--- |
| TextBox | Input | 작업경로코드 | 검색할 경로 코드 입력 |
| TextBox | Input | 작업경로명 | 검색할 경로 명칭 입력 |
| ComboBox | Select | 사용여부 | 전체/YES/NO 선택 (Default: 전체) |
| Button | Button | 조회 | `SearchWorkRouteListCmd` 실행 |

### 2.2 좌측: 작업경로목록 (Left List)
| Component | Type | Label | Description |
| :--- | :--- | :--- | :--- |
| Grid | Table | 작업경로목록 | 조회된 결과 리스트 표시 (Read Only) |
| - Column | Text | 작업경로코드 | `workRouteCd` |
| - Column | Text | 작업경로명 | `workRouteNm` |
| - Column | Text | 화종 | `hwajong` |
| - Column | Text | 작업유형1 | `wrktype1` |
| - Column | Text | 작업유형2 | `wrktype2` |
| Button | Button | 행추가 | 작업경로 신규 등록 모드 전환 |
| Button | Button | 행취소 | |

### 2.3 우측 상단: 작업경로상세정보 (Detail Info)
| Component | Type | Label | Mandatory | Description |
| :--- | :--- | :--- | :--- | :--- |
| TextBox | Input | 작업경로코드 | **Y** | `workRouteCd` (Editable) |
| TextBox | Input | 작업경로명 | **Y** | `workRouteNm` (Editable) |
| ComboBox | Select | 화종 | **Y** | `hwajongCd` (기타코드 09) |
| ComboBox | Select | 작업유형1 | **Y** | `wrktype1Cd` (기타코드 10, 화종 종속) |
| ComboBox | Select | 작업유형2 | **Y** | `wrktype2Cd` (기타코드 12, 유형1 종속) |
| ComboBox | Select | 사용여부 | N | `useYn` (신규 시 자동 YES) |
| TextBox | Input | 비고 | N | `rmkCd` |
| TextBox | Display | 등록자/일시 | **Y** | 자동 세팅 (Read Only 성격) |
| TextBox | Display | 수정자/일시 | **Y** | 자동 세팅 (Read Only 성격) |

### 2.4 우측 하단: 작업경로별작업단계목록 (Right Bottom List)
| Component | Type | Label | Mandatory | Description |
| :--- | :--- | :--- | :--- | :--- |
| Grid | Table | 작업단계목록 | 경로에 포함된 단계 리스트 (Editable) |
| - Column | Text | 순서 | N | `seq` |
| - Column | Text | 작업단계코드 | **Y** | `workStepCd` |
| - Column | Text | 작업단계명 | N | `workStepNm` |
| - Column | Text | 작업단계Level1| N | `workStepLevel1` (기타코드 07) |
| - Column | Text | 작업단계Level2| N | `workStepLevel2` (기타코드 08, Level1 종속) |
| - Column | Text | 사용여부 | N | `useYn` |
| - Column | Text | 비고 | N | `rmk` |
| Button | Button | 행추가 | 작업단계 목록에 빈 행 추가 |
| Button | Button | 행삭제 | 선택된 행 삭제 처리 (Soft Delete) |
| Button | Button | 저장 | 전체 변경사항 DB 저장 (`SaveWorkRouteEachWorkStepCmd`) |

---

## 3. Data Mapping

### 3.1 작업경로 마스터 (Master Data)
| 한글명 | 영문명 (ID) | Type | PK | 필수 | 비고 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 작업경로코드 | `workRouteCd` | String | Y | **M** | |
| 작업경로명 | `workRouteNm` | String | | **M** | |
| 화종 | `hwajongCd` | Code | | **M** | 기타코드 09 |
| 작업유형1 | `wrktype1Cd` | Code | | **M** | 기타코드 10 |
| 작업유형2 | `wrktype2Cd` | Code | | **M** | 기타코드 12 |
| 사용여부 | `useYn` | Char | | | Y/N |
| 비고 | `rmkCd` | String | | | |
| 등록자명 | `regrNmCd` | String | | **M** | 시스템 자동 입력 |
| 등록일시 | `regDate` | Date | | **M** | 시스템 자동 입력 |
| 수정자명 | `mdfrNmCd` | String | | **M** | 시스템 자동 입력 |
| 수정일시 | `chgdt` | Date | | **M** | 시스템 자동 입력 |

### 3.2 작업경로 상세 단계 (Detail Data)
| 한글명 | 영문명 (ID) | Type | PK | 필수 | 비고 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 순서 | `seq` | Number | | | |
| 작업단계코드 | `workStepCd` | String | Y | **M** | |
| 작업단계Level1 | `workStepLevel1`| Code | | | 기타코드 07 |
| 작업단계Level2 | `workStepLevel2`| Code | | | 기타코드 08 |
| 사용여부 | `useYn` | Char | | | |
| 비고 | `rmk` | String | | | |

---

## 4. Logic Definition

### 4.1 초기화 및 공통코드 로드 (Initialization Logic)
*   **Open Event:** 화면 로드 시 로그인 ID와 DB Sysdate를 수신합니다.
*   **Combo Box Setup:** 다음 코드를 가져와 콤보박스를 구성합니다.
    *   기타코드 07: 작업단계 Level1
    *   기타코드 08: 작업단계 Level2 (Level1 선택 시 종속적으로 필터링됨)
    *   기타코드 09: 화종 (화물종류)
    *   기타코드 10: 작업유형1 (물류영역 - 화종 코드에 종속됨)
    *   기타코드 12: 작업유형2 (물류기능 - 작업유형1 코드에 종속됨)
*   **Default Value:** '사용여부' 검색 조건은 자동으로 "전체"로 선택됩니다.

### 4.2 계층형 데이터 표시 로직 (Hierarchical Display Logic)
*   **작업유형 연동:**
    *   사용자가 `화종`을 선택하면, 해당 화종 코드에 매핑된 `작업유형1`(물류영역) 목록만 필터링되어 표시됩니다.
    *   사용자가 `작업유형1`을 선택하면, 해당 유형 코드에 매핑된 `작업유형2`(물류기능) 목록만 필터링되어 표시됩니다.
*   **작업단계 연동:**
    *   작업단계를 등록할 때 `작업단계 Level1`에 해당하는 `작업단계 Level2` 값을 마스터 테이블에서 읽어와 자동으로 Display 하거나 필터링하여 보여줍니다.

### 4.3 신규 등록 로직 (Creation Logic)
*   **행추가 (Master/Detail 공통):**
    *   입력 필드를 모두 Clear 합니다.
    *   `사용여부`는 자동으로 'YES'로 설정합니다.
    *   `등록자명`, `등록일시`, `수정자명`, `수정일시`는 현재 로그인한 사용자 ID와 시스템 현재 시간(Sysdate)으로 표시합니다.

### 4.4 삭제 및 저장 로직 (Delete & Save Logic)
*   **Soft Delete:**
    *   `행삭제` 버튼 클릭 시, 해당 데이터가 화면에서 방금 추가된 신규 행이라면 즉시 삭제합니다.
    *   기존 DB에 저장되어 있던 데이터라면 레코드 자체를 삭제하지 않고, `사용여부` 값만 '아니오(No)'로 변경하여 수정 상태로 만듭니다.
*   **Save:**
    *   변경된 작업경로(Master)와 작업단계(Detail) 정보를 일괄 저장합니다.
    *   신규 등록 건은 `Insert`, 기존 수정 건은 `Update` 처리합니다.
    *   저장 시 등록/수정 정보(ID, 시간)를 최신화하여 DB에 반영합니다.
