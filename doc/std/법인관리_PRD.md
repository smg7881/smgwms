# 법인관리 (Corporation Management) PRD

## 1. User Flow

사용자의 화면 진입부터 데이터 저장까지의 주요 흐름은 다음과 같습니다.

1.  **화면 진입 (Initial Load)**
    *   사용자가 법인관리 화면에 접속합니다.
    *   시스템은 자동으로 콤보박스(사용여부, 화폐코드, 시스템언어, 부가세구분 등)를 초기화하고 기본값(예: '전체')을 설정합니다.

2.  **법인 조회 (Search)**
    *   사용자가 검색 조건(법인명)을 입력하고 **[검색]** 버튼을 클릭합니다.
    *   좌측 리스트에 법인 목록이 조회됩니다.

3.  **상세 정보 확인 (View Details)**
    *   좌측 법인 목록에서 특정 법인을 선택합니다.
    *   우측 상단에 해당 법인의 **[법인상세]** 정보가 출력되고, 우측 하단에 **[법인별 국가정보]** 리스트가 조회됩니다.

4.  **신규 등록 및 수정 (Create/Update)**
    *   **법인 추가:** 좌측 하단의 **[행추가]** 버튼을 클릭하면 우측 상세 입력 폼이 초기화되고, 등록자/수정자 정보가 현재 사용자 기준으로 세팅됩니다.
    *   **데이터 입력:** 사용자는 법인 필수 정보(법인명, 업종, 대표자명 등)를 입력하고, 필요 시 팝업(우편번호, 상위법인 찾기)을 이용합니다.
    *   **국가정보 추가:** 우측 하단의 **[행추가]** 버튼을 눌러 해당 법인에 속한 국가 정보를 입력합니다.

5.  **저장 (Save)**
    *   모든 입력을 마친 후 **[저장]** 버튼을 클릭합니다.
    *   시스템은 유효성을 검증(필수값, 대표여부 중복 등)하고 DB에 저장합니다. 수정 시 변경 이력이 별도 테이블에 저장됩니다.

---

## 2. UI Component 리스트

화면은 크게 검색 영역, 좌측 목록(Master), 우측 상세(Detail), 하단 국가정보(Sub-Detail)로 구성됩니다.

### 2.1 검색 영역 (Header)
| 구분 | 라벨(Label) | 타입(Type) | 설명 | 필수여부 |
| :--- | :--- | :--- | :--- | :--- |
| Input | 법인 (Corporation) | Text Input + Search Icon | 법인명 검색 조건 입력 | Optional |
| Button | 검색 | Button | 법인 목록 조회 이벤트 실행 | - |

### 2.2 법인 목록 (Left Area)
| 구분 | 컬럼명 | 타입 | 속성 |
| :--- | :--- | :--- | :--- |
| Grid | No | Text | 순번 |
| Grid | 법인코드 (Corp Code) | Text | ReadOnly |
| Grid | 법인명 (Corp Name) | Text | ReadOnly |
| Grid | 사용여부 (Use Y/N) | Text | ReadOnly |
| Button | 행추가/행취소 | Button | 신규 법인 등록 모드 전환 및 취소 |

### 2.3 법인 상세 (Right Top Area)
| 라벨 | 타입 | 매핑 ID | 속성/비고 |
| :--- | :--- | :--- | :--- |
| 법인코드 | Input | `corpCd` | ReadOnly, Mandatory |
| 법인명 | Input | `corpNmCd` | Editable, Mandatory |
| 업종 | Input | `indstypeCd` | Editable, Mandatory |
| 업태 | Input | `bizcondCd` | Editable, Mandatory |
| 대표자명 | Input | `rptrNmCd` | Editable, Mandatory |
| 사업자등록증 | Input | `compregSlipCd` | Editable, Mandatory |
| 상위법인코드 | Input + Popup | `upperCorpCd` | Editable, 팝업(법인선택) |
| 주소 | Input + Popup | `addrCd` | Editable, 팝업(우편번호) |
| 상세주소 | Input | `dtlAddrCd` | Editable, Mandatory |
| 부가세구분 | Combo | `vatSctnCd` | Choice, Mandatory, 공통코드(131) |
| 사용여부 | Combo | `useYnCd` | Choice, Mandatory, 공통코드(06) |
| 등록자/일시 | Text | `regrNmCd` | ReadOnly, 자동세팅 |
| 수정자/일시 | Text | `mdfrNmCd` | ReadOnly, 자동세팅 |

### 2.4 법인별 국가정보 (Right Bottom Area)
| 컬럼명 | 타입 | 매핑 ID | 속성/비고 |
| :--- | :--- | :--- | :--- |
| 선택 | Checkbox | `slc` | 삭제/선택용 |
| 일련번호 | Text | `seq` | 자동 생성 |
| 국가 | Input + Popup | `ctryCd` | Mandatory, 팝업(국가선택) |
| 적용화폐단위 | Combo | `aplyMonUnitCd` | Mandatory, 공통코드(27) |
| TIME ZONE | Combo | `tIMEZONECd` | Mandatory, 국가코드 기반 자동 필터 |
| 표준시간 | Text | `stdtime` | ReadOnly, TimeZone 선택 시 자동 세팅 |
| 썸머타임 | Text | - | TimeZone 선택 시 자동 세팅 |
| 시스템언어 | Combo | `sysLangSlc` | Mandatory, 공통코드(98) |
| 부가세율(%) | Input | `vatRt(%)` | Mandatory, 숫자 입력 |
| 대표여부 | Checkbox/Combo | `rptYnCd` | Mandatory, 법인당 1개만 설정 가능 |
| 사용여부 | Combo | `useYnCd` | Mandatory |
| Button | 행추가/행취소/저장 | Button | 하단 Grid 제어 및 전체 저장 |

---

## 3. Data Mapping

서버와 통신하거나 DB에 저장되는 주요 데이터 항목입니다.

### 3.1 Master Data (법인정보 - TB_CM02003)
*   **Input/Output:** `corpCd`, `corpNm`, `indstypeCd`, `bizcondCd`, `rptrNmCd`, `compregSlipCd`, `upperCorpCd`, `addrCd`, `dtlAddrCd`, `vatSctnCd`, `useYnCd`
*   **System Fields:** `regrNmCd` (등록자), `regDate` (등록일시), `mdfrNmCd` (수정자), `chgdt` (수정일시)

### 3.2 Detail Data (법인별 국가정보 - TB_CM02023)
*   **Input/Output:** `seq`, `ctryCd`, `aplyMonUnitCd`, `tIMEZONECd`, `stdtime`, `sysLangSlc`, `vatRt(%)`, `rptYnCd`, `useYnCd`

### 3.3 History Data (이력 관리 - TB_CM02022)
*   수정 발생 시 기존 데이터를 백업하기 위해 사용됩니다.
*   **Trigger:** 저장 버튼 클릭 시 수정으로 판단되는 경우.
*   **Data:** 법인코드 + 순번(History Seq) + 수정 전 Data

---

## 4. Logic Definition

### 4.1 초기화 및 공통코드 로딩 (Open Event)
*   화면 로드 시 다음 공통코드를 조회하여 콤보박스를 구성합니다.
    *   기타코드 06번: 사용여부
    *   기타코드 27번: 화폐코드
    *   기타코드 98번: 시스템언어
    *   기타코드 131번: 부가세구분코드
*   기본값으로 '전체' 또는 'YES' 등을 자동 선택합니다.

### 4.2 팝업 호출 로직 (Popup Logic)
*   **법인선택:** `CorpSlcPopup.jsp` 호출. 조회 결과가 1건일 경우 팝업 없이 바로 세팅합니다.
*   **국가선택:** `CtrySlcPopup.jsp` 호출. 조회 결과가 1건일 경우 바로 세팅합니다.
*   **우편번호선택:** `ZipcdSlcPopup.jsp` 호출. 우편번호 조회 결과가 1건일 경우 바로 주소명을 세팅합니다.

### 4.3 업무 규칙 (Business Rules)
*   **Time Zone 설정:** `TB_CM01016` (타임존 테이블)에서 국가코드에 해당하는 Time Zone을 조회하여 콤보를 구성합니다.
*   **표준시간/썸머타임:** 선택된 Time Zone에 매핑된 표준시간과 썸머타임 정보를 `TB_CM01016`에서 가져와 표시합니다.
*   **대표여부 체크:** 법인별 국가정보 등록 시, '대표여부'는 하나의 법인 내에서 단 하나의 국가(Row)만 'YES' 또는 체크 상태가 되도록 제어합니다.

### 4.4 저장 및 이력 관리 (Save & History Logic)
*   **신규 저장:**
    *   법인코드: 자동 생성 또는 입력값 검증 (문서상 명시되지 않았으나 ReadOnly 속성으로 보아 자동 채번 가능성 있음).
    *   등록자/수정자 정보: 현재 로그인 ID와 시스템 시간(Sysdate)으로 저장합니다.
*   **수정 저장:**
    *   수정 시, 변경 전 데이터를 `TB_CM02022`(법인 변경이력 테이블)에 이력으로 저장합니다.
    *   법인 상세 정보뿐만 아니라, 법인별 국가정보가 수정되는 경우에도 해당 건수만큼 이력을 생성합니다.
*   **법인별 국가정보 행 취소:**
    *   화면상에서 행 삭제를 하더라도 서버의 데이터는 즉시 삭제되지 않으며, '저장' 시 처리되거나 추가 입력 중인 건에 대해서만 화면에서 제거됩니다.
