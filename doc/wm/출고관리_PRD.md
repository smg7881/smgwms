# 출고관리 PRD

## 0. 문서 정보
- 화면 ID: `giMngt.dev`
- 화면명: `출고관리`
- 작성일: `2026-03-08`
- 기준 문서:
  - `LogisT-WM-DS02(화면설계서-V1.0)-출고관리.pdf`
  - `LogisT-WM-AN13(화면정의서-V1.0)-출고관리.pdf`
- 적용 패턴:
  - `master-detail-screen-pattern`
  - `공통코드관리 화면 패턴(PageComponent + Stimulus BaseGridController + batch_save)`

## 1. 목표
- 출고지시(마스터)와 출고지시상세/피킹(디테일)을 한 화면에서 조회/처리한다.
- 출고 상태 전이를 `출고지시(10) -> 할당(20) -> 피킹(30) -> 출고확정(40)`으로 관리한다.
- 검색조건/그리드에서 팝업 검색(작업장/고객/아이템/로케이션)을 지원한다.
- 신규 테이블은 `tb_` 대신 `wm_` 접두를 사용한다.

## 2. 화면 구성
- 검색영역
  - 작업장(팝업, 필수)
  - 고객(팝업)
  - 출고유형(공통코드 `154`)
  - 출고상태(공통코드 `155`)
  - 지시일자(from/to)
  - 출고일자
  - 아이템(팝업)
  - 오더번호
  - 배차번호
  - 차량번호
- 마스터 그리드: `출고지시목록`
  - 출고예정번호, 고객, 출고유형, 배차번호, 출고상태, 지시일자, 출고일자, 출고시간, 오더번호, 차량번호, 기사명, 기사전화번호, 운송사, 비고
- 디테일 탭 1: `아이템상세`
  - 라인번호, 아이템코드/명, 단위, 출고지시물량, 출고실적물량, 할당물량, 피킹물량, 재고속성01~10, 비고
- 디테일 탭 2: `할당/피킹`
  - 라인번호, 피킹번호, 아이템코드/명, 단위, 출고지시물량, 로케이션, 재고물량, 할당물량(편집), 피킹물량(편집), 피킹일자/시간, 비고
- 액션 버튼
  - `할당`, `피킹`, `출고확정`, `출고취소`

## 3. 데이터 모델(신규)
> 레거시 PDF의 `TB_WM03001/2/3` 구조를 현재 시스템 규칙에 맞춰 `wm_` 접두로 재설계한다.

### 3.1 wm_gi_prars (출고지시 헤더)
- PK: `gi_prar_no` (string, 20)
- 주요 컬럼:
  - `workpl_cd`, `corp_cd`, `cust_cd`
  - `gi_type_cd` (공통코드 `154`)
  - `gi_stat_cd` (공통코드 `155`, 기본 `10`)
  - `idct_ymd`(지시일자), `gi_ymd`, `gi_hms`
  - `ord_no`, `exec_ord_no`, `asign_no`
  - `dlv_prar_ymd`, `dlv_prar_hms`
  - `car_no`, `driver_nm`, `driver_telno`, `transco_cd`, `rmk`
  - `create_by`, `create_time`, `update_by`, `update_time`

### 3.2 wm_gi_prar_details (출고지시 상세)
- PK: `(gi_prar_no, lineno)`
- 주요 컬럼:
  - `item_cd`, `item_nm`, `unit_cd`
  - `gi_idct_qty`, `gi_rslt_qty`, `assign_qty`, `pick_qty`
  - `gi_stat_cd`
  - `stock_attr_col01 ~ stock_attr_col10`
  - `rmk`, 감사필드

### 3.3 wm_gi_picks (할당/피킹 목록)
- PK: `pick_no` (string, 20)
- 주요 컬럼:
  - `gi_prar_no`, `lineno`, `item_cd`
  - `loc_cd`, `stock_attr_no`
  - `stock_qty`, `assign_qty`, `pick_qty`
  - `pick_stat_cd` (`10`/`20`/`30`), `pick_ymd`, `pick_hms`
  - `stock_attr_col01 ~ stock_attr_col10`
  - `rmk`, 감사필드

## 4. 공통코드 매핑(숫자 코드만 사용)
- 출고유형: `154`
  - `10` 일반출고
  - `20` 창고간이관출고
  - `30` 인수연기출고
- 출고상태: `155`
  - `10` 출고지시
  - `20` 할당
  - `30` 피킹
  - `40` 출고확정

## 5. 팝업 요구사항
- 검색조건 팝업
  - `workplace`: 작업장 선택
  - `customer`: 고객 선택
  - `item`: 아이템 선택
- 디테일(할당/피킹) 팝업
  - `location`: 로케이션 선택(작업장/구역/존 컨텍스트 전달)
- 필요 시 신규 타입 추가
  - 출고화면 전용으로 부족한 팝업 타입은 `SearchPopupsController#generic_rows`에 매핑 확장

## 6. 상태 전이 및 처리 규칙
- `할당`
  - 가능 상태: 헤더 상태 `10`
  - `wm_gi_picks` 생성/갱신, 상세 `assign_qty` 누적, 상세/헤더 상태 `20` 갱신
- `피킹`
  - 가능 상태: 헤더 상태 `20`
  - `wm_gi_picks.pick_qty` 반영, 상세 `assign_qty` 차감 + `pick_qty` 누적, 상태 `30` 갱신
- `출고확정`
  - 가능 상태: 헤더 상태 `30`
  - 재고 차감(기존 재고 테이블 API 활용), 상세 `gi_rslt_qty = pick_qty`, assign/pick 잔량 정리, 상태 `40`
- `출고취소`
  - 상태 `40` 이전 또는 이후 분기 처리
  - 배정/피킹/확정 단계의 역정산 규칙 적용, 필요 시 피킹/재고 수량 롤백

## 7. 라우트/API 설계
- `GET /wm/gi_prars` (HTML/JSON)
- `POST /wm/gi_prars/batch_save` (마스터 저장)
- `GET /wm/gi_prars/:gi_prar_id/details` (상세 목록)
- `POST /wm/gi_prars/:gi_prar_id/details/batch_save` (상세 저장)
- 추가 액션
  - `GET /wm/gi_prars/:id/picks`
  - `POST /wm/gi_prars/:id/assign`
  - `POST /wm/gi_prars/:id/pick`
  - `POST /wm/gi_prars/:id/confirm`
  - `POST /wm/gi_prars/:id/cancel`

## 8. UI/구현 패턴
- ViewComponent
  - `app/components/wm/gi_prars/page_component.rb`
  - `.../page_component.html.erb`
- Stimulus
  - `app/javascript/controllers/wm/gi_prar_grid_controller.js`
  - `BaseGridController` 상속, `master/detail/pick` role 운용
- Controller
  - `app/controllers/wm/gi_prars_controller.rb`
  - `index + batch_save + assign/pick/confirm/cancel`

## 9. 메뉴/권한
- 신규 메뉴코드: `WM_GI_PRAR`
- URL: `/wm/gi_prars`
- 권한: `adm_user_menu_permissions` 전 사용자 기본 부여 마이그레이션 포함
- 탭 ID: `wm-gi-prars`

## 10. 검증 항목
- 마스터-디테일 계약 등록
  - `config/master_detail_screen_contracts.yml`에 `wm_gi_prars` 추가
- 계약 테스트 통과
  - `ruby bin/rails test test/contracts/master_detail_pattern_contract_test.rb`
- 기능 테스트
  - 검색/선택/디테일 로드
  - 할당/피킹/확정/취소 상태전이
  - 팝업 선택값 반영
  - 출고확정 상태에서 편집 비활성
