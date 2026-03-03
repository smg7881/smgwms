# 우편번호관리 PRD (현행 시스템 반영본)

## 1. 문서 목적
- 레거시 산출물(PDF) 기반 우편번호관리 화면 요구사항을 Rails 표준 화면 패턴으로 재정의한다.
- 화면 구현 위치를 `/기준정보/코드관리/업무공통코드관리/우편번호관리`로 확정한다.
- 메뉴관리 화면과 동일한 `검색 + 그리드 + 모달 CRUD` 패턴으로 구현한다.

## 2. 참조 원본
- 화면정의서(실파일): `D:\_LOGIS\1.공통\pdf\LogisT-CM-AN13(화면정의서-V1.0)_우편번호관리_20100628.pdf`
- 화면설계서: `D:\_LOGIS\1.공통\pdf\LogisT-CM-DS02(화면설계서-V1.0)-우편번호관리.pdf`

참고:
- 요청 원문에 있던 `LogisT-CM-DS02(화면정의서-V1.0)-우편번호관리_20100628.pdf` 경로는 실파일이 없어 AN13 정의서로 대체 적용함.

## 3. 화면/권한/메뉴
- URL: `/std/zipcodes`
- 컨트롤러: `Std::ZipcodesController`
- 화면 컴포넌트: `Std::Zipcode::PageComponent`
- Stimulus: `std-zipcode-crud`
- 권한 메뉴코드: `STD_ZIP_CODE`
- 메뉴 위치: `STD > 코드관리 > 업무공통코드관리 > 우편번호관리`
- 탭 ID: `std-zipcodes`

## 4. 데이터 모델(현행)
- 테이블: `std_zip_codes`
- 키: `id` (내부 식별), 업무 유니크키 `(ctry_cd, zipcd, seq_no)`
- 주요 컬럼:
  - `ctry_cd` 국가코드
  - `zipcd` 우편번호
  - `seq_no` 일련번호
  - `zipaddr` 우편주소
  - `sido` 시도
  - `sgng` 시군구
  - `eupdiv` 읍면동
  - `use_yn_cd` 사용여부
  - `create_by/create_time`, `update_by/update_time` 감사필드

## 5. 공통코드
- 신규 코드:
  - 코드헤더: `STD_ZIP_USE_YN` (우편번호 사용여부)
  - 상세코드: `Y=예`, `N=아니요`
- 화면 적용 규칙:
  - `STD_ZIP_USE_YN`가 존재하면 우선 사용
  - 미존재 환경은 `CMM_USE_YN`로 자동 폴백

## 6. 사용자 흐름
1. 사용자가 우편번호관리 메뉴를 연다.
2. 검색조건(국가/우편번호/우편주소/사용여부) 입력 후 조회한다.
3. 목록에서 행의 수정/삭제를 수행한다.
4. `신규` 버튼으로 모달을 열어 우편번호를 등록한다.
5. 저장 성공 시 목록이 자동 새로고침된다.

## 7. UI 구성
### 7.1 검색영역
- 국가(팝업, `country`)
- 우편번호(`zipcd`, 부분검색)
- 우편주소(`zipaddr`, 주소/시도/시군구/읍면동 통합검색)
- 사용여부(`use_yn_cd`)

### 7.2 목록영역(AG Grid)
- 국가코드/국가명, 우편번호, 일련번호
- 우편주소, 시도, 시군구, 읍면동
- 사용여부, 수정자, 수정일시
- 작업항목(수정/삭제)

### 7.3 모달영역(등록/수정)
- 입력: 국가, 우편번호, 일련번호, 우편주소, 시도, 시군구, 읍면동, 사용여부
- 읽기전용: 등록자/등록일시/수정자/수정일시
- 수정 모드에서는 업무키(`국가+우편번호+일련번호`) 변경 불가

## 8. API 계약
### 8.1 목록 조회
- `GET /std/zipcodes`
- `GET /std/zipcodes.json`
- 검색 파라미터: `q[ctry_cd]`, `q[zipcd]`, `q[zipaddr]`, `q[use_yn_cd]`

### 8.2 등록
- `POST /std/zipcodes`
- Body: `zipcode[ctry_cd, zipcd, seq_no, zipaddr, sido, sgng, eupdiv, use_yn_cd]`

### 8.3 수정
- `PATCH /std/zipcodes/:id`
- 수정허용: 주소/행정구역/사용여부
- 업무키(`ctry_cd`, `zipcd`, `seq_no`)는 서버에서 변경 차단

### 8.4 삭제
- `DELETE /std/zipcodes/:id`
- 물리삭제가 아닌 `use_yn_cd = 'N'` 소프트삭제

## 9. 검증 규칙
- `ctry_cd`, `zipcd`, `seq_no` 필수
- `seq_no`는 1 이상의 정수
- `use_yn_cd`는 `Y/N`
- 유니크 제약: `(ctry_cd, zipcd, seq_no)`

## 10. 레거시 대비 반영 범위
- PDF의 상세 항목(주소리/도서산간/산번지/동범위 등)은 현행 `std_zip_codes` 스키마에 없는 항목으로 본 범위에서 제외.
- 우선순위는 현행 WMS 스키마/공통 컴포넌트/권한체계와의 정합성으로 둔다.
