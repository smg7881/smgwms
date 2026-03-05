# 매입요율관리 PRD

## 1. 문서 개요
- 화면명: 매입요율관리
- 화면 ID: `purFeeRtMngt.dev`
- 기준 문서:
  - `LogisT-WM-AN13(화면정의서-V1.0)-매입요율관리.pdf`
  - `LogisT-WM-DS02(화면설계서-V1.0)-매입요율관리.pdf`
- 적용 범위: WMS > 매입요율관리 (`/wm/pur_fee_rt_mngs`)

## 2. 핵심 요구사항
1. 매입요율 마스터/상세를 1:N 구조로 관리한다.
2. 저장 버튼은 마스터 영역에 1개만 제공한다.
3. 저장 시 마스터/상세 변경분을 한 번의 요청으로 동시 저장한다.
4. 공통코드 참조는 숫자 코드로 사용한다.
  - 사용여부/자동여부/확정여부: `06`
  - 매입단위분류: `20`
  - 통화코드: `27`
  - 매입아이템유형: `69`
5. 테이블명은 `tb_` 대신 `wm_` 접두를 사용한다.

## 3. 사용자 흐름
1. 화면 진입
  - 조회조건 기본값:
    - 사용여부 = `Y`
    - 적용일자 From = 당해년도 1월 1일
    - 적용일자 To = 오늘
2. 조회조건 입력 후 검색
  - 조건: 작업장, 계약협력사, 매입항목, 사용여부, 적용일자(From~To)
  - 결과: 마스터 그리드(요율목록) 표시
3. 마스터 행 선택
  - 선택된 마스터의 상세목록을 디테일 그리드에 표시
4. 행추가/행삭제
  - 마스터: 신규 요율 생성
  - 디테일: 선택 마스터의 요율상세 생성
5. 저장
  - 마스터/디테일 변경분을 단일 트랜잭션으로 저장
  - 신규 마스터는 상세 1건 이상 없이 저장 불가

## 4. 화면 구성
### 4.1 검색 영역
- 작업장 (팝업)
- 계약협력사 (팝업)
- 매입항목 (팝업)
- 사용여부 (`06`)
- 적용일자 From/To (Date Range)

### 4.2 마스터 그리드 (요율목록)
- 상태, 작업장, 계약협력사, 매입항목, 매입부서, 매입아이템유형(`69`), 매입아이템, 매입단위분류(`20`), 매입단위, 사용여부(`06`), 자동여부(`06`), 비고, 수정/생성 이력

### 4.3 디테일 그리드 (요율상세목록)
- 상태, 라인번호, 확정여부(`06`), 적용시작일자, 적용종료일자, 적용단가, 통화코드(`27`), 기준작업물량, 적용시작물량, 적용종료물량, 비고, 수정/생성 이력

## 5. 업무 규칙
1. 적용종료일자는 적용시작일자보다 빠를 수 없다.
2. 신규 저장 시 마스터 + 상세를 모두 입력해야 저장 가능하다.
3. 마스터 수정 가능 항목:
  - 매입아이템유형, 매입아이템, 매입단위분류, 매입단위, 사용여부, 자동여부, 비고
4. 디테일 수정 가능 항목:
  - 전체 컬럼 수정 가능

## 6. 데이터 모델
### 6.1 마스터 테이블
- 테이블명: `wm_pur_fee_rt_mngs`
- 키: `wrhs_exca_fee_rt_no` (PK)
- 주요 컬럼:
  - `corp_cd`, `work_pl_cd`, `sell_buy_sctn_cd(고정:20)`, `ctrt_cprtco_cd`, `sell_buy_attr_cd`
  - `pur_dept_cd`, `pur_item_type`, `pur_item_cd`, `pur_unit_clas_cd`, `pur_unit_cd`
  - `use_yn`, `auto_yn`, `rmk`
  - `create_by`, `create_time`, `update_by`, `update_time`

### 6.2 상세 테이블
- 테이블명: `wm_pur_fee_rt_mng_dtls`
- 키: `id` (PK), 업무키 `wrhs_exca_fee_rt_no + lineno` (Unique Index)
- 주요 컬럼:
  - `wrhs_exca_fee_rt_no(FK)`, `lineno`
  - `dcsn_yn`, `aply_strt_ymd`, `aply_end_ymd`, `aply_uprice`, `cur_cd`
  - `std_work_qty`, `aply_strt_qty`, `aply_end_qty`, `rmk`
  - `create_by`, `create_time`, `update_by`, `update_time`

## 7. API 요건
### 7.1 목록 조회
- `GET /wm/pur_fee_rt_mngs`
- `GET /wm/pur_fee_rt_mngs/:id/details`

### 7.2 통합 저장
- `POST /wm/pur_fee_rt_mngs/batch_save`
- 요청 본문:
  - 마스터: `rowsToInsert`, `rowsToUpdate`, `rowsToDelete`
  - 상세: `detailOperations.rowsToInsert`, `rowsToUpdate`, `rowsToDelete`
  - 선택 마스터 참조값: `master_key` 또는 `master_client_temp_id`
- 처리 방식:
  - 단일 DB 트랜잭션
  - 마스터 저장 후 상세 저장
  - 신규 마스터 임시키(`client_temp_id`)를 실키로 매핑 후 상세 FK 주입

## 8. 테스트 기준
1. 마스터/상세 동시 저장 성공
2. 신규 마스터 + 상세 미입력 시 저장 실패
3. 적용일자 역전(시작 > 종료) 검증
4. 마스터 삭제 시 연관 상세 정리
5. 공통코드 숫자 코드 렌더링/저장 확인
