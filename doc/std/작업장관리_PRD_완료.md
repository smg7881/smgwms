# 작업장관리 시스템 PRD

## 1. User Flow (화면 간 유기적 흐름)

사용자는 법인별 작업장 정보를 조회, 상세 확인, 신규 등록 및 수정할 수 있습니다. 화면은 크게 좌측(목록 및 검색)과 우측(상세 정보)으로 나뉘어 동작합니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 '작업장관리' 메뉴에 진입합니다.
    *   시스템은 로그인한 사용자의 소속 법인 정보를 기본으로 설정하고, 필요한 공통 코드(작업장 구분, 용량/면적 단위 등)를 로드하여 검색 조건을 초기화합니다.

2.  **작업장 검색 (Search)**
    *   사용자가 좌측 상단 '작업장관리 찾기조건'에 검색어(작업장명 등)를 입력하고 **[조회]** 버튼을 클릭합니다.
    *   조건에 맞는 작업장 목록이 좌측 하단 그리드(List)에 표시됩니다.

3.  **상세 정보 조회 (View Detail)**
    *   좌측 목록에서 특정 작업장을 클릭(Select)합니다.
    *   우측 '작업장 상세 정보' 영역에 선택된 작업장의 데이터가 바인딩됩니다.

4.  **신규 등록 (Create New)**
    *   사용자가 **[신규]** 버튼을 클릭합니다.
    *   우측 상세 정보 폼이 초기화(Clear)됩니다. 단, 등록자/수정자 정보는 현재 사용자 및 시간으로, '사용여부'는 'Yes'로 자동 설정됩니다.
    *   사용자는 필수 항목(작업장명, 부서 등)을 입력합니다. 부서, 거래처, 국가 등은 **돋보기 아이콘(팝업)**을 통해 검색하여 입력합니다.

5.  **저장 (Save)**
    *   정보 입력 후 **[저장]** 버튼을 클릭합니다.
    *   유효성 검증(Mandatory Check) 후 DB에 데이터가 저장(Insert/Update)되며, 변경 사항이 반영됩니다.

---

## 2. UI Component List (Rails 8 기준)

Rails 8의 Hotwire(Turbo, Stimulus) 생태계를 고려하여 필요한 컴포넌트를 추출하였습니다.

| 영역 | 컴포넌트 명 (Rails Helper/Tag) | 설명 및 용도 |
| :--- | :--- | :--- |
| **Layout** | `SplitLayoutComponent` | 좌측(목록) 40%, 우측(상세) 60% 비율의 2-Column 레이아웃 구성. |
| **Search** | `form_with` | 검색 조건 입력 폼 (법인명, 작업장구분, 작업장명 등). |
| | `select_tag` | 공통코드(기타코드 92번)를 이용한 '작업장구분' 드롭다운 메뉴. |
| **List** | `TurboFrame` (`#workplace_list`) | 비동기 검색 결과를 표시하는 영역. |
| | `TableComponent` | 작업장 목록 표시 (Headers: 법인, 작업장구분, 작업장명 등). |
| **Detail** | `TurboFrame` (`#workplace_detail`) | 목록 클릭 시 상세 정보를 비동기로 로드하여 교체하는 영역. |
| | `text_field` / `number_field` | 작업장명, 최대용량, 면적 등 텍스트 및 숫자 입력 필드. |
| | `check_box` / `radio_button` | 창고관리여부, 인터페이스여부, 사용여부 등 Y/N 선택. |
| | `date_field` | 평균운영시간, 등록일시 표시 (Rails DatePicker 연동). |
| **Popup** | `ModalComponent` (Stimulus) | 돋보기 아이콘 클릭 시 호출되는 모달 (법인, 부서, 거래처, 자산, 국가, 우편번호 선택). |
| **Action** | `button_to` / `link_to` | 조회, 신규, 저장 버튼. Turbo Stream을 통해 페이지 전체 리로드 없이 동작. |

---

## 3. Data Mapping (DB 메타데이터 정의)

각 화면 입력 필드와 매칭되는 데이터 정의입니다. 필수 여부(M)와 속성(Read/Edit)은 화면설계서를 따릅니다.

### 3.1. 검색 조건 영역 (Left Top)
| 한글명 | 영문명 (Column) | 타입 | 속성 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| 법인 | `corp` / `corpNm` | String | ReadOnly | 로그인 사용자 소속 자동 바인딩 |
| 작업장구분 | `workplSctnCd` | String | Editable | 공통코드 92번 |
| 작업장명 | `workplNmCd` | String | Editable | 검색 키워드 |

### 3.2. 상세 정보 영역 (Right Detail)
| 한글명 | 영문명 (Column) | 타입 | 필수(M) | 설명/Validation |
| :--- | :--- | :--- | :--- | :--- |
| 법인코드 | `corpCd` | String | **M** | |
| 작업장코드 | `workplCd` | String | **M** | PK, 자동채번 또는 입력 |
| 상위작업장 | `upperWorkplCd` | String | **M** | |
| 부서코드 | `deptCd` | String | **M** | 팝업 선택 (`DeptSlcPopup`) |
| 작업장명 | `workplNm` | String | **M** | |
| 작업장구분 | `workplSctnCd` | String | **M** | 공통코드 92번 |
| 용량단위 | `capaSpecUnitCd` | String | Optional | 공통코드 13번 (부피단위) |
| 최대/적정용량 | `maxCapa` / `adptCapa` | Number | Optional | |
| 면적단위 | `dimemSpecUnitCd` | String | Optional | 공통코드 14번 (길이단위) |
| 면적 | `dimem` | Number | Optional | |
| 창고관리여부 | `wmYnCd` | String | **M** | Y/N |
| 거래처 | `bzacCd` | String | Optional | 팝업 선택 (`BzacSlcPopup`) |
| 국가 | `ctryCd` | String | Optional | 팝업 선택 (`CtrySlcPopup`) |
| 주소 | `addrCd` / `dtlAddrCd` | String | Optional | 우편번호 팝업 (`ZipcdSlcPopup`) |
| 사용여부 | `useYnCd` | String | **M** | Default: 'Y' |
| 등록자/일시 | `regrNmCd` / `regDate` | String/Date | **M** | System 자동 입력 |

---

## 4. Logic Definition (비즈니스 로직)

버튼 클릭 및 이벤트 발생 시 수행해야 할 상세 로직입니다.

### 4.1. 초기화 (Open Event)
*   **Trigger**: 화면 로드 시.
*   **Logic**:
    1.  로그인한 사용자의 ID, 소속 법인 코드를 가져와 검색 조건의 '법인' 필드에 세팅합니다.
    2.  공통코드 시스템에서 다음 코드를 조회하여 Select Box를 초기화합니다.
        *   코드 92: 작업장 구분
        *   코드 13: 용량규격단위 (부피)
        *   코드 14: 면적규격단위 (길이)

### 4.2. 작업장 목록 조회 (Search Event)
*   **Trigger**: [조회] 버튼 클릭 (`SearchWorkplListCmd`).
*   **Logic**:
    1.  입력된 검색 조건(법인, 작업장구분, 작업장명)을 파라미터로 받습니다.
    2.  조건에 일치하는 작업장 목록을 DB에서 조회하여 좌측 그리드에 바인딩합니다.
    3.  조회된 목록에서 행을 클릭하면 `RetrieveWorkplDtlInfoCmd`를 호출합니다.

### 4.3. 신규 정보 입력 준비 (New Event)
*   **Trigger**: [신규] 버튼 클릭.
*   **Logic**:
    1.  상세 정보 폼의 모든 입력 필드를 초기화(Clear)합니다.
    2.  다음 필드에 기본값(Default Value)을 할당합니다.
        *   **법인코드**: 현재 로그인한 사용자의 소속 법인
        *   **사용여부**: 'Yes' (예)
        *   **등록자/수정자**: 현재 로그인 사용자 명
        *   **등록일시/수정일시**: 현재 시스템 날짜/시간 (`sysdate`)

### 4.4. 저장 (Save Event)
*   **Trigger**: [저장] 버튼 클릭 (`SaveWorkplDtlInfoCmd`).
*   **Logic**:
    1.  **Validation**: 필수 항목(법인코드, 작업장코드, 부서, 작업장명 등) 누락 여부를 확인합니다.
    2.  **Process**:
        *   신규 등록인 경우: 입력된 정보를 `INSERT` 합니다. 등록/수정 정보를 현재 사용자와 시간으로 기록합니다.
        *   수정인 경우: 기존 PK(`workplCd`)에 해당하는 레코드를 `UPDATE` 합니다. 수정자 및 수정일시를 갱신합니다.
    3.  **Post-Process**: 저장이 완료되면 사용자에게 성공 메시지를 알리고, 목록을 재조회(Refresh)합니다.

### 4.5. 팝업 선택 로직 (Popup Selection)
*   **Trigger**: 각 항목(법인, 부서, 거래처, 자산, 국가, 우편번호) 옆의 돋보기 아이콘 클릭.
*   **Logic**:
    *   해당하는 공통 팝업(예: `DeptSlcPopup.jsp`, `BzacSlcPopup.jsp` 등)을 오픈합니다.
    *   팝업에서 항목을 선택하면, 부모 창(Opener)의 해당 필드(코드 및 명칭)에 값을 반환하고 팝업을 닫습니다.
    *   *예외처리*: 검색 결과가 1건일 경우 팝업을 띄우지 않고 즉시 필드에 값을 채웁니다.
