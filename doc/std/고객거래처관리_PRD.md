# PRD: 고객거래처관리 (영업관리/거래처관리/고객거래처관리)

## 1. 기준 문서 및 시스템 반영 방향

- 원본 화면설계서: `D:\_LOGIS\1.공통\pdf\LogisT-CM-DS02(화면설계서-V1.0)-금융기관관리.pdf`
- 적용 패턴: 기존 `거래처관리(STD_CLIENT)` 화면의 3레이어 구조(ViewComponent + Stimulus + Rails Controller) 재사용
- 메뉴 위치: `영업관리 > 거래처관리 > 고객거래처관리`
- 메뉴코드: `SALES_CUST_CLIENT`
- URL: `/std/customer_clients`
- 테이블 정책: 기존 `tb_` 명명 대신 `std_` 계열만 사용

## 2. 화면 범위

고객거래처관리는 거래처관리 화면과 동일한 구조를 사용하며, 데이터 범위를 `고객거래처`로 제한한다.

- 마스터: 고객거래처 목록
- 디테일 탭
1. 고객거래처 기본정보
2. 고객거래처 추가정보
3. 고객거래처 담당자
4. 고객거래처 작업장

변경이력은 저장 시 `std_cm04004`에 적재하며, 본 화면에서는 조회 탭 없이 저장 로직만 동일 적용한다.

## 3. 공통코드 정의

고객거래처 전용 코드셋을 추가하고 화면에서 이를 사용한다.

| 코드 | 코드명 | 상세코드 | 상세코드명 | 비고 |
| --- | --- | --- | --- | --- |
| `STD_CUST_BZAC_SCTN_GRP` | 고객거래처구분그룹 | `CUSTOMER` | 고객거래처 | 검색/상세 그룹 |
| `STD_CUST_BZAC_SCTN` | 고객거래처구분 | `DOMESTIC` | 국내고객 | 그룹 `CUSTOMER` 하위 |
| `STD_CUST_BZAC_SCTN` | 고객거래처구분 | `OVERSEAS` | 해외고객 | 그룹 `CUSTOMER` 하위 |
| `STD_CUST_BZAC_KIND` | 고객거래처종류 | `CORP` | 법인 | 거래처종류 |
| `STD_CUST_BZAC_KIND` | 고객거래처종류 | `INDIV` | 개인 | 거래처종류 |
| `CMM_USE_YN` | 사용여부 | `Y`/`N` | 예/아니오 | 기존 코드 재사용 |

## 4. 데이터 모델 매핑

고객거래처 화면은 신규 물리 테이블을 만들지 않고 기존 `std_` 거래처 테이블을 공유 사용한다.

- 마스터: `std_bzac_mst`
- 담당자: `std_bzac_ofcr`
- 작업장: `std_bzac_workpl`
- 변경이력: `std_cm04004`

핵심 조건
- 고객거래처 화면은 `std_bzac_mst.bzac_sctn_grp_cd = 'CUSTOMER'` 데이터만 조회
- 저장 시 `bzac_sctn_grp_cd`는 항상 `CUSTOMER`로 강제
- 삭제는 물리삭제가 아니라 `use_yn_cd = 'N'`으로 처리(Soft Delete)

## 5. 사용자 흐름

1. 사용자가 고객거래처관리 메뉴 진입
2. 검색조건 입력 후 조회
3. 마스터 행 선택 시 기본/추가/담당자/작업장 탭 데이터 동기화
4. 행추가/수정 후 저장
5. 삭제 시 기존 데이터는 비활성화, 신규 미저장 데이터는 그리드에서 제거

## 6. 기능 상세

### 6.1 검색

- 검색조건: 거래처코드, 거래처명, 관리법인, 고객거래처구분그룹, 고객거래처구분, 사업자번호, 사용여부
- 그룹/구분 콤보는 `STD_CUST_*` 코드 기반
- `고객거래처구분그룹` 선택값에 따라 `고객거래처구분` 옵션을 의존 필터링

### 6.2 마스터 저장

- 배치 저장 API: `POST /std/customer_clients/batch_save`
- Insert/Update/Delete를 한 트랜잭션으로 처리
- Update/Soft Delete 시 변경 컬럼을 `std_cm04004`에 순번 증가로 적재

### 6.3 담당자/작업장 저장

- 담당자 조회: `GET /std/customer_clients/:id/contacts`
- 담당자 저장: `POST /std/customer_clients/:id/batch_save_contacts`
- 작업장 조회: `GET /std/customer_clients/:id/workplaces`
- 작업장 저장: `POST /std/customer_clients/:id/batch_save_workplaces`

### 6.4 검증

- 사업자번호: 숫자 10자리
- 필수: 거래처명, 관리법인, 사업자번호, 구분그룹, 구분, 종류, 국가, 대표영업사원, 적용시작일, 사용여부
- 적용종료일은 적용시작일보다 빠를 수 없음

## 7. 기술 구현 포인트

- Controller: `Std::CustomerClientsController` (기존 `Std::ClientsController` 패턴 준수)
- Component: `Std::CustomerClient::PageComponent`
- Stimulus: `std-customer-client-grid` 사용 (`client-grid` 상속 분리)
- View: `app/views/std/customer_clients/index.html.erb`
- 권한코드: `SALES_CUST_CLIENT`

## 8. 비기능 요구사항

- 기존 거래처관리와 동일한 조작감 유지
- 권한 없는 사용자는 접근 차단(403)
- 메뉴/권한/공통코드 마이그레이션 포함
