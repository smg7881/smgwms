# 우편번호 관리 (Zip Code Management) PRD

## 1. User Flow

사용자가 우편번호를 검색, 조회, 신규 등록 및 수정하는 전체적인 흐름은 다음과 같습니다.

1.  **화면 진입 (Entry):**
    *   사용자가 화면에 접속하면 시스템은 기본 설정된 국가 코드, 로그인 ID, 현재 날짜(Sysdate)를 기준으로 초기 우편번호 목록을 조회하여 표시합니다.
2.  **검색 (Search):**
    *   사용자가 상단 검색 영역에 검색 조건(국가, 우편번호, 우편번호 주소)을 입력하고 **[검색]** 버튼을 클릭합니다.
    *   *조건:* 국가 코드를 모를 경우 돋보기 아이콘을 클릭하여 **[국가선택 팝업]**을 호출합니다. 조회된 국가가 1건일 경우 팝업 없이 바로 세팅됩니다.
    *   시스템은 조건에 맞는 우편번호 목록을 그리드(List) 영역에 표시합니다.
3.  **상세 조회 (View Detail):**
    *   사용자가 우편번호 목록(List)에서 특정 행(Row)을 클릭합니다.
    *   하단 상세 정보(Detail) 영역에 해당 우편번호의 상세 데이터가 바인딩됩니다.
4.  **신규 등록 (Create New):**
    *   사용자가 하단의 **[신규]** 버튼을 클릭합니다.
    *   상세 정보 영역의 입력 필드가 초기화되고, 입력 가능한 상태로 변경됩니다.
    *   '사용여부'는 자동으로 "YES"로 설정됩니다.
    *   사용자가 상세 정보를 입력하고 **[저장]** 버튼을 클릭하면 DB에 신규 데이터가 저장됩니다.
5.  **수정 (Update):**
    *   목록에서 선택 후 상세 영역에서 데이터를 수정합니다.
    *   **[저장]** 버튼을 클릭하면 변경된 정보가 DB에 반영됩니다.
6.  **엑셀 업로드 (Excel Upload):**
    *   사용자가 **[엑셀업로드]** 버튼을 클릭하여 우편번호 정보를 일괄 등록합니다.

---

## 2. UI Component 리스트

화면은 크게 **검색 영역(Search)**, **목록 영역(List)**, **상세 영역(Detail)**으로 구성됩니다.

### 2.1 검색 영역 (Top)
| Component | Label | Description | Action/Event |
| :--- | :--- | :--- | :--- |
| Input (Text) | 국가 (Country) | 국가 코드 입력 (Mandatory) | `CtrySlcPopup.jsp` 호출 (돋보기 클릭 시) |
| Input (Text) | 우편번호 (ZipCode) | 우편번호 검색어 입력 | - |
| Input (Text) | 우편번호 주소 | 주소 검색어 입력 | - |
| Button | 검색 | 조회 실행 버튼 | `SearchZipcdListCmd` 실행 |

### 2.2 목록 영역 (Middle - Grid)
우편번호 조회 결과가 표시되는 그리드입니다.

| Column Header | Description |
| :--- | :--- |
| 국가 | 국가명 표시 |
| 우편번호 | Zip Code (예: 100-011) |
| 일련번호 | 우편번호 일련번호 (Sequence) |
| 우편주소 | 전체 우편 주소 |
| 시도 | 시/도 명칭 |
| 시군구 | 시/군/구 명칭 |
| 읍면동 | 읍/면/동 명칭 |
| 시작번지 (주/부) | 시작 번지 정보 |
| 끝번지 (주/부) | 끝 번지 정보 |

### 2.3 상세 영역 (Bottom - Form)
우편번호 상세 정보를 입력하거나 수정하는 영역입니다.

| Component | Label | Editable | Description |
| :--- | :--- | :--- | :--- |
| Input + Button | 국가코드 | Yes | 팝업을 통해 국가 선택 |
| Input | 우편번호 | Yes | 우정국 고시 우편번호 |
| Input | 우편번호 일련번호 | Yes | 우정국 고시 일련번호 |
| Input | 시도 / 시군구 / 읍면동 | Yes | 주소 상세 정보 |
| Input | 주소리 / 도서산간 / 산번지 | Yes | 주소 상세 정보 |
| Input | 우편주소 / 아파트건물명 | Yes | 주소 상세 정보 |
| Input | 시작번지 (주/부) | Yes | 번지 정보 |
| Input | 끝번지 (주/부) | Yes | 번지 정보 |
| Input | 동 범위 시작 / 동 번지 끝 | Yes | 동 범위 정보 |
| Input (Date) | 변경일자 | Yes | Format: YYYY-MM-DD |
| Select Box | 사용여부 | Yes | YES / NO 선택 (신규 시 'YES' 기본) |
| Input | 등록자 / 등록일시 | No | 시스템 자동 입력 (로그인 사용자/Sysdate) |
| Input | 수정자 / 수정일시 | No | 시스템 자동 입력 (로그인 사용자/Sysdate) |
| Button | 엑셀업로드 | - | 엑셀 파일 업로드 기능 |
| Button | 신규 | - | 입력 폼 초기화 |
| Button | 저장 | - | 데이터 저장 (SaveCmd) |

---

## 3. Data Mapping

화면의 UI 항목과 내부 데이터 속성(English Variable Name)의 매핑 정보입니다.

### 3.1 Search Condition (검색 조건)
*   **국가 (Country):** `ctryCd`
*   **국가명 (CountryName):** `ctryNm`
*   **우편번호 (ZipCode):** `zipcd`
*   **우편번호 주소 (ZipCodeAddr):** `zipcdAddrCd`

### 3.2 List Data (목록 데이터)
*   **국가 (Country):** `ctry`
*   **우편번호 (ZipCode):** `zipcd`
*   **일련번호 (Sequence):** `seq`
*   **우편주소 (ZipAddress):** `zipaddrCd`
*   **시도 (Sido):** `sidoCd`
*   **시군구 (SiGunGu):** `sgngCd`
*   **읍면동 (EupMyonDong):** `eupdivCd`
*   **시작번지 (StartHouseNumber):** `strtHouseno` (주: `wek`, 부: `mnst`)
*   **끝번지 (EndHouseNumber):** `endHouseno` (주: `wek`, 부: `mnst`)

### 3.3 Detail Data (상세 데이터)
*   **국가코드 (CountryCode):** `ctryCd`
*   **우편번호 (ZipCode):** `zipcd`
*   **우편번호 일련번호 (ZipCodeSequence):** `zipcdSeq`
*   **시도 (Sido):** `sidoCd`
*   **시군구 (SiGunGu):** `sgngCd`
*   **읍면동 (EupMyonDongDivision):** `eupdivCd`
*   **주소리 (AddressRi):** `addrRiCd`
*   **도서산간 (IslandSan):** `ilandSanCd`
*   **산번지 (SanHouseNumber):** `sanHousenoCd`
*   **우편주소 (ZipAddress):** `zipaddrCd`
*   **아파트건물명 (ApartmentBulidingName):** `aptBildNmCd`
*   **시작번지 (StartHouseNumber):** 주(`strtHousenoWek`), 부(`strtHousenoMnst`)
*   **끝번지 (EndHouseNumber):** 주(`endHousenoWek`), 부(`endHousenoMnst`)
*   **동 범위 시작 (DongRangeStart):** `dongRngStrt`
*   **동 번지 끝 (DongHouseNumberEnd):** `dongHousenoEnd`
*   **변경일자 (ChangeYyyymmdd):** `chgYmd`
*   **사용여부 (UseYesOrNo):** `useYn`
*   **등록자 (Registrar):** `regr`
*   **등록일시 (RegistrationDate):** `regDate`
*   **수정자 (Modifier):** `mdfr`
*   **수정일시 (ChangePersonDate):** `chgdt`

---

## 4. Logic Definition

### 4.1 초기화 및 화면 제어 (Initialization & Control)
*   **기본값 설정:**
    *   화면 로드 시 **등록일시/수정일시**는 DB의 `sysdate`를 기본값으로 표시합니다.
    *   **등록자/수정자**는 현재 로그인한 사용자의 ID를 기본값으로 표시합니다.
    *   **국가코드**는 시스템 설정 국가 기본값을 사용합니다.
*   **화면 Display:** 초기 진입 시 또는 검색 후 우편번호 목록을 Grid에 표시합니다.

### 4.2 검색 및 팝업 로직 (Search & Popup)
*   **국가선택 팝업 (Common.CtrySlcPopup):**
    *   Input: 국가코드, 국가명.
    *   Logic: 국가코드 조회 값이 1개일 경우 팝업 없이 해당 값을 필드에 세팅합니다. 조회 값이 2개 이상이거나 없을 경우 선택 팝업을 오픈합니다.
*   **우편번호 검색:** 검색 조건 입력 후 실행 시 `SearchZipcdListCmd`를 호출하여 목록을 갱신합니다.

### 4.3 상세 정보 처리 (Detail Handling)
*   **목록 클릭 (Click Event):**
    *   그리드에서 행을 클릭하면 해당 우편번호 코드(`zipcd`)를 키로 하여 상세 정보를 조회하고 하단 폼에 바인딩합니다.
*   **신규 입력 (New Logic):**
    *   [신규] 버튼 클릭 시 상세 폼의 모든 데이터를 초기화합니다.
    *   단, **사용여부(`useYn`)**는 자동으로 "YES"로 설정합니다.
    *   `NewInsCmd` 관련 로직을 수행하여 입력 모드로 전환합니다.

### 4.4 저장 및 업무 규칙 (Save & Business Rules)
*   **저장 (Save Logic):**
    *   [저장] 버튼 클릭 시 `SaveCmd`를 호출하여 변경된 정보를 DB에 저장합니다.
    *   저장 대상 데이터: 국가코드, 우편번호, 일련번호, 각종 주소지 정보, 번지수, 변경일자, 사용여부 등.
*   **업무 규칙:**
    *   **우편번호/일련번호:** 우정국에서 시행 공지되는 데이터를 기준으로 등록해야 합니다.
    *   **날짜 포맷:** 변경일자는 `YYYY-MM-DD` 포맷을 따릅니다.

### 4.5 엑셀 업로드 (Excel Upload)
*   **기능:** 엑셀 파일을 통해 다수의 우편번호 정보를 일괄 입력받아 서버 DB에 저장합니다 (`UploadXlsCmd`).
