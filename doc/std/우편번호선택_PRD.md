# 우편번호선택 팝업 PRD (Product Requirements Document)

## 1. User Flow
사용자가 우편번호 검색 팝업을 진입하여 주소를 검색하고 선택하여 부모 창으로 데이터를 전달하는 흐름은 다음과 같습니다.

1.  **팝업 진입 (Open):** 사용자가 부모 화면에서 우편번호 검색 기능을 호출하면 팝업이 오픈됩니다.
2.  **검색 조건 입력:** 사용자는 '우편번호' 또는 '읍면동' 입력란에 검색어를 입력합니다.
    *   우편번호는 일부만 입력하여 조회할 수 있습니다 (Partial Match 지원).
3.  **조회 실행:** '검색' 버튼을 클릭합니다.
4.  **목록 확인:** 하단 그리드(Grid) 영역에 검색 조건에 해당하는 우편번호 목록이 출력됩니다.
5.  **항목 선택:**
    *   **Click:** 목록에서 특정 행을 클릭하면 해당 행이 선택 상태가 됩니다.
    *   **Double Click:** 목록에서 특정 행을 더블 클릭하면 선택이 확정됩니다.
    *   **선택 버튼 (Select):** 사용자가 행을 선택한 후 '선택' 기능을 수행하면, `Double Click`과 동일하게 우편번호와 주소를 리턴하고 팝업을 닫습니다.
6.  **데이터 반환 및 종료:**
    *   선택된 우편번호와 주소 정보를 부모 화면(Opener)으로 반환(Return)하고 팝업이 닫힙니다.
    *   '닫기' 버튼 클릭 시 데이터를 반환하지 않고 팝업을 종료합니다.

---

## 2. UI Component 리스트
화면 레이아웃은 크게 **조회 조건 영역**과 **결과 목록 영역**, **버튼 영역**으로 구성됩니다.

### 2.1 조회 조건 영역 (Header)
| 구분 | Component | Label (KOR) | 속성/설명 |
| :-- | :-- | :-- | :-- |
| Label | Label | 우편번호 | 검색 조건 라벨 |
| Input | Text Field | (없음) | 우편번호 입력 필드 (Editable) |
| Label | Label | 읍면동 | 검색 조건 라벨 |
| Input | Text Field | (없음) | 읍면동 입력 필드 (Editable) |
| Action | Button | 검색 | 클릭 시 조회 이벤트 트리거 |

### 2.2 결과 목록 영역 (Body - Grid)
| 구분 | Component | Header Label | 설명 |
| :-- | :-- | :-- | :-- |
| List | Grid Table | 일련번호 | 순번 표시 |
| List | Grid Table | 우편번호 | 우편번호 데이터 (예: 100-725) |
| List | Grid Table | 우편주소 | 전체 주소 표시 |
| List | Grid Table | 시도 | 시/도 정보 |
| List | Grid Table | 시군구 | 시/군/구 정보 |
| List | Grid Table | 읍면동 | 읍/면/동 정보 |
| List | Grid Table | 시작번지 (주/부) | 시작 번지 정보 (Main/Sub 구분) |
| List | Grid Table | 끝번지 (주/부) | 끝 번지 정보 (Main/Sub 구분) |
| Scroll | Scrollbar | (없음) | 목록이 길어질 경우 우측 스크롤 생성 |

### 2.3 하단 액션 영역 (Footer)
| 구분 | Component | Label | 설명 |
| :-- | :-- | :-- | :-- |
| Action | Button | 닫기 | 팝업 종료 버튼 |

---

## 3. Data Mapping
화면설계서에 명시된 영문 속성명과 한글 항목명을 매핑합니다. 개발 시 해당 변수명을 준수해야 합니다.

### 3.1 조회 조건 (Input Data)
| 항목명(Kor) | 항목명(Eng) | 영문속성명 (ID) | 타입 | 비고 |
| :-- | :-- | :-- | :-- | :-- |
| 우편번호 | ZipCode | `zipCd` | String | 일부 입력 가능 |
| 읍면동 | EupMyonDong Division | `eupdiv` | String | - |

### 3.2 우편번호 목록 (Output List Data)
| 항목명(Kor) | 항목명(Eng) | 영문속성명 (ID) | 설명 |
| :-- | :-- | :-- | :-- |
| 일련번호 | Sequence | `seq` | - |
| 우편번호 | ZipCode | `zipCd` | - |
| 우편주소 | ZipAddress | `zipAddrCd` | - |
| 시도 | Sido | `sidoCd` | - |
| 시군구 | SiGunGu | `sgngCd` | - |
| 읍면동 | EupMyonDong Division | `eupdivCd` | - |
| 시작번지 | StartHouseNumber | `strtHouseno` | 시작번지 전체 |
| - 주 | Week (Main)* | `wek` | 시작번지 본번 |
| - 부 | Minstry (Sub)* | `mnst` | 시작번지 부번 |
| 끝번지 | EndHouseNumber | `endHouseno` | 끝번지 전체 |
| - 주 | Week (Main)* | `wek` | 끝번지 본번 |
| - 부 | Minstry (Sub)* | `mnst` | 끝번지 부번 |

*\*주/부의 영문 표기(Week, Minstry)는 원본 소스의 표기를 따랐으나, 문맥상 주소의 본번(Main)/부번(Sub)을 의미함.*

---

## 4. Logic Definition

### 4.1 초기화 로직 (Initialization)
*   **Event:** Open
*   **Action:** 팝업이 열릴 때 로그인 ID 정보를 수신합니다. (소스상 화면 Display 조건에 관여하는 것으로 보임).
*   **Display:** 등록일시/수정일시는 DB sysdate를, 등록자/수정자는 현재 로그인 사용자를 기본값으로 설정합니다.

### 4.2 조회 로직 (Search)
*   **Event:** `RetrieveZipCdListCmd` (조회 버튼 Click).
*   **Input:** `zipCd`(우편번호), `eupdiv`(읍면동) 조회 조건.
*   **Process:**
    1.  입력된 조회 조건을 쿼리 파라미터로 전송합니다.
    2.  우편번호는 전체가 아닌 **일부만 입력해도 조회가 가능**해야 합니다 (Like 검색).
*   **Output:** 조회된 데이터를 그리드(Grid)에 바인딩하여 출력합니다.

### 4.3 선택 및 반환 로직 (Selection & Return)
*   **Event 1: Row Click**
    *   그리드의 특정 행을 클릭하면 해당 행이 Highlight 됩니다.
*   **Event 2: Row Double Click**
    *   **Input:** 선택된 행의 `zipCd`(우편번호), `zipAddrCd`(주소).
    *   **Action:** 해당 우편번호와 주소 정보를 부모창(Caller)으로 리턴(Return)하고 팝업을 닫습니다.
*   **Event 3: Select Button Click** (문서상 '선택버튼' 언급됨)
    *   사용자가 행을 선택(Click)한 후 '선택' 기능을 수행하면, `Double Click`과 동일하게 우편번호와 주소를 리턴하고 팝업을 닫습니다.

### 4.4 종료 로직 (Close)
*   **Event:** 닫기 버튼 Click.
*   **Action:** 아무런 데이터를 반환하지 않고 팝업 창을 닫습니다.
