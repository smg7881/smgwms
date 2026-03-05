# 재고관리 PRD

## 1. 문서 개요
- 대상 화면: `WM 재고관리` (`/wm/stock_moves`)
- 기준 문서:
  - `LogisT-WM-DS02(화면설계서-V1.0)-재고관리.pdf`
  - `LogisT-WM-AN13(화면정의서-V1.0)-재고관리.pdf`
- 작성일: 2026-03-05
- 목적: 재고 조회와 다건 재고이동 처리를 현재 Rails WMS 구조에 맞춰 구현한다.

## 2. 핵심 요구사항
1. 재고목록 검색 조건으로 작업장/고객/아이템/영역/적치구역/로케이션을 지원한다.
2. 재고목록에서 가용재고(재고-할당-피킹)를 확인하고, `TO 로케이션`과 `이동수량`을 입력한다.
3. 다중 행 선택 후 `재고이동`을 한 번에 처리한다.
4. 업무규칙:
   - 이동수량은 이동가능수량 이하만 허용한다.
   - 로케이션은 수기 입력 가능하되 저장 시 실제 존재 여부를 검증한다.
5. 조회 조건의 팝업 검색을 제공한다(없으면 신규 제공).

## 3. 화면 설계
### 3.1 검색 영역 (재고목록검색)
- 작업장(`workpl_cd`, 필수): 팝업(`workplace`)
- 고객(`cust_cd`): 팝업(`customer`)
- 아이템(`item_cd`): 팝업(`item`)
- 영역(`area_cd`): 팝업(`area`) 신규
- 적치구역(`zone_cd`): 팝업(`zone`) 신규
- 로케이션(`loc_cd`): 팝업(`location`) 신규
- 버튼: `검색`, `초기화`

### 3.2 목록 영역 (재고목록)
- 고객사(`cust_cd`, `cust_nm`)
- 영역(`area_cd`)
- 적치구역(`zone_cd`)
- 로케이션(`loc_cd`)
- 아이템코드(`item_cd`)
- 아이템명(`item_nm`)
- 재고속성번호(`stock_attr_no`)
- 재고속성01~10(`stock_attr_col01~10`)
- 단위코드(`basis_unit_cd`)
- 재고물량(`qty`)
- 할당물량(`alloc_qty`)
- 피킹물량(`pick_qty`)
- 이동가능물량(`move_poss_qty`)
- TO 로케이션(`to_loc_cd`, 입력)
- 이동수량(`move_qty`, 입력)
- 버튼: `재고이동`

## 4. 이벤트/처리 흐름
### 4.1 OPEN
- 입력: 로그인 사용자, 법인코드
- 동작: 검색조건 초기화 후 화면 진입

### 4.2 재고목록검색
- Trigger: `검색` 클릭
- 입력: 검색조건
- 조회원천:
  - 재고: `tb_wm04003` (속성/로케이션별 재고)
  - 재고속성: `tb_wm04001`
  - 보조 마스터: `wm_locations`, `std_*` 마스터
- 출력: 재고목록

### 4.3 재고이동
- Trigger: `재고이동` 클릭
- 입력: 선택행(법인/고객/작업장/재고속성번호/아이템/단위/From/To/이동수량)
- 처리(행별 트랜잭션 검증 포함):
  1. 가용재고 확인 (`qty - alloc_qty - pick_qty >= move_qty`)
  2. From 로케이션 재고 차감 (`tb_wm04003`, `tb_wm04004`)
  3. To 로케이션 재고 증가 (`tb_wm04003`, `tb_wm04004`)
  4. 이동이력 생성 (`wm_stock_moves`, `move_type='MV'`)
- 출력: 성공/실패, 실패 시 행별 오류 메시지 반환

## 5. 데이터 설계
### 5.1 기존 사용 테이블
- `tb_wm04001` 재고속성
- `tb_wm04003` 속성/로케이션별 재고
- `tb_wm04004` 로케이션별 재고
- `wm_locations` 로케이션 마스터

### 5.2 신규 테이블 (`wm_` prefix)
- 테이블명: `wm_stock_moves`
- 용도: 재고이동 실행이력(MV) 저장
- 주요 컬럼:
  - `corp_cd`, `workpl_cd`, `cust_cd`, `item_cd`
  - `stock_attr_no`
  - `from_loc_cd`, `to_loc_cd`
  - `move_qty`
  - `basis_unit_cls`, `basis_unit_cd`
  - `move_type` (`MV`)
  - `move_ymd`, `move_hms`
  - `stock_attr_col01~10` (이동시점 속성 스냅샷)
  - `create_by`, `create_time`, `update_by`, `update_time`

## 6. API 설계
- `GET /wm/stock_moves`
  - HTML: 화면 렌더
  - JSON: 검색조건 기반 재고목록 반환
- `POST /wm/stock_moves/move`
  - body: `{ rows: [...] }`
  - 응답:
    - 성공: `{ success: true, message: "재고이동이 완료되었습니다.", data: { moved: n } }`
    - 실패: `{ success: false, errors: [...] }`

## 7. 권한/메뉴
- 메뉴코드: `WM_STOCK_MOVE`
- 메뉴명: `재고관리`
- URL: `/wm/stock_moves`
- 상위메뉴: `WM_GROUP`
- 권한체계: `AdmUserMenuPermission` 기반

## 8. 공통코드 정책
- 본 화면에서 코드그룹이 필요한 항목은 숫자 코드 체계를 사용한다.
- 현재 재고관리 화면은 조회/이동 중심이라 코드 Select 의존도를 최소화하고, 필요한 경우 기존 숫자 코드그룹(`AdmCodeDetail.code`)을 우선 사용한다.

## 9. 테스트 기준
1. 검색조건 조합별 조회 결과 검증
2. 이동수량 > 이동가능수량 시 실패 검증
3. TO 로케이션 미존재 시 실패 검증
4. 다중 행 이동 성공 시 수불 정합성 검증
5. 이동 성공 시 `wm_stock_moves` 이력 생성 검증
6. 메뉴권한 없을 때 접근 차단 검증

## 10. 구현 산출물
- 라우트: `wm/stock_moves`, `wm/stock_moves/move`
- 컨트롤러: `Wm::StockMovesController`
- 컴포넌트: `Wm::StockMoves::PageComponent`
- Stimulus: `wm/stock_move_grid_controller.js`
- 모델: `Wm::StockMove`
- 마이그레이션: `create_wm_stock_moves`
- 팝업 확장: `search_popups` (`area`, `zone`, `location`)
- 메뉴 seed: `db/seeds/wm_stock_move_menu.rb`
