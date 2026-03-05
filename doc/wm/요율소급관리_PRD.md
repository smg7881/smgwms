# 요율소급관리 PRD

## 1. 문서 개요
- 화면명: 요율소급관리
- 화면 ID: `feeRtRtacMngt.dev`
- 기준 문서:
  - `D:\_LOGIS\4.보관\pdf\LogisT-WM-DS02(화면설계서-V1.0)-요율소급관리.pdf`
  - `D:\_LOGIS\4.보관\pdf\LogisT-WM-AN13(화면정의서-V1.0)-요율소급관리.pdf`
- 적용 범위: WMS > 요율소급관리 (`/wm/rate_retroacts`)
- 개발 패턴: `master-detail-screen-pattern` (Master=매출입요율목록, Detail=매출입실적목록)

## 2. 핵심 요구사항
1. 창고정산담당자가 특정 매출입항목의 요율을 소급 적용할 수 있어야 한다.
2. 검색조건 필수값: 작업장, 매출입구분, 거래처.
3. 마스터(요율목록) 선택 시 디테일(실적목록)을 조회한다.
4. `소급요율검색` 팝업에서 소급 적용할 요율을 선택한다.
5. `소급요율적용` 시 디테일 목록의 소급단가/소급금액/차이값을 계산한다.
6. `소급처리` 시 선택된 실적행을 반영해 소급처리 이력을 저장한다.
7. 공통코드는 숫자코드를 사용한다.
  - 매출입구분: `80`
  - 통화코드: `27`
  - 사용여부: `06`
8. 신규 테이블은 `tb_` 대신 `wm_` 접두를 사용한다.

## 3. 현행 시스템 매핑/제약
1. 원본 문서의 실적 원천 테이블(`TB_WM05004`, `TB_WM05005`)과 확정판정 테이블(`TB_IS31001`, `TB_IS31003`)은 현재 시스템에 없음.
2. 실적 원천은 현행 `tb_wm05001`(`Wm::ExceRslt`)로 대체한다.
3. 원본의 확정구분코드 기반 Insert/Update 분기는 현행에서는 소급이력 존재 여부로 대체한다.
  - 이력 없음: `C`(신규)
  - 이력 있음: `U`(갱신)
4. 원본 요구의 `창고정산상태코드=소급적용`은 이력 테이블의 `rtac_proc_stat_cd='RTAC'`로 관리한다.

## 4. 사용자 흐름
1. 화면 진입
  - 적용일자 From: 당해년도 1월 1일
  - 적용일자 To: 오늘
  - 실적기준일자 From/To: 오늘 기준 최근 30일
  - 사용여부: `Y`
2. 검색조건 입력 후 조회
  - 작업장/매출입구분/거래처/매출입항목/적용일자
  - 마스터 그리드 조회
3. 마스터 행 선택
  - 선택 요율 기준으로 디테일(실적) 조회
4. 소급요율검색
  - `보관요율선택(커스텀)` 팝업에서 소급요율 선택
5. 소급요율적용
  - 디테일 행 계산: 소급단가/소급금액/단가차이/금액차이
6. 소급처리
  - 선택된 디테일 행을 소급처리 이력 테이블에 반영

## 5. 화면 구성
### 5.1 검색 영역
- 작업장 (팝업: `workplace`)
- 매출입구분 (코드 `80`)
- 거래처 (팝업: `client`)
- 매출입항목 (팝업: `sellbuy_attr`)
- 적용일자 From/To
- 실적기준일자 From/To
- 사용여부 (`06`)

### 5.2 마스터 그리드: 매출입요율목록
- 요율번호
- 매출입항목코드/명
- 매출입단위
- 적용요율
- 적용시작일자
- 적용종료일자
- 소급요율(선택값 표시)

### 5.3 디테일 그리드: 매출입실적목록
- 선택(체크)
- 실적기준일자
- 실적인식구분
- 운영실적관리번호
- 라인번호
- 실적물량
- 적용단가
- 실적금액
- 통화코드
- 소급단가
- 소급금액
- 단가차이
- 금액차이

## 6. 팝업 요구사항
1. 작업장선택: 공통 `search_popups/workplace`
2. 거래처선택: 공통 `search_popups/client`
3. 매출입항목선택: 공통 `search_popups/sellbuy_attr`
4. 소급요율검색: 신규 `search_popups/fee_rate`
  - 입력: 작업장, 매출입구분, 거래처, 매출입항목, 기준일자
  - 출력: 요율번호, 항목, 단위, 적용단가, 통화코드

## 7. 데이터 모델
### 7.1 소급처리 이력
- 테이블명: `wm_rate_retroact_histories`
- PK: `id`
- Unique 키: `exce_rslt_no`
- 주요 컬럼:
  - 실적 참조: `exce_rslt_no`, `op_rslt_mngt_no`, `op_rslt_mngt_no_seq`, `rslt_std_ymd`
  - 조건: `work_pl_cd`, `sell_buy_sctn_cd`, `bzac_cd`, `sell_buy_attr_cd`
  - 단가/금액: `base_uprice`, `base_amt`, `rtac_uprice`, `rtac_amt`, `uprice_diff`, `amt_diff`
  - 기타: `cur_cd`, `rslt_qty`, `ref_fee_rt_no`, `ref_fee_rt_lineno`
  - 처리: `prcs_sctn_cd(C/U)`, `rtac_proc_stat_cd(RTAC)`
  - 감사: `create_by`, `create_time`, `update_by`, `update_time`

## 8. API 설계
1. `GET /wm/rate_retroacts`
  - HTML: 화면
  - JSON: 마스터 요율목록 조회
2. `GET /wm/rate_retroacts/:rate_retroact_id/details`
  - 선택 요율 기준 실적목록 조회
3. `POST /wm/rate_retroacts/apply_retro_rates`
  - 선택 요율 기준 계산 결과 반환
4. `POST /wm/rate_retroacts/process_retroacts`
  - 선택 실적행 소급처리 이력 저장(C/U)

## 9. 업무 규칙
1. `소급요율적용` 전에는 `소급처리` 불가.
2. 실적물량이 0 이하인 행은 처리 제외.
3. 금액 계산식:
  - `실적금액 = 실적물량 * 적용단가`
  - `소급금액 = 실적물량 * 소급단가`
  - `단가차이 = 소급단가 - 적용단가`
  - `금액차이 = 소급금액 - 실적금액`
4. 소급처리 시 동일 `exce_rslt_no`가 있으면 갱신(`U`), 없으면 신규(`C`).

## 10. 메뉴/권한
- 메뉴코드: `WM_RATE_RETROACT_MNG`
- 메뉴명: `요율소급관리`
- URL: `/wm/rate_retroacts`
- 권한: `adm_user_menu_permissions`에 전 사용자 기본 `Y` 부여

## 11. 테스트 기준
1. 검색 조건으로 마스터 목록 조회 성공
2. 마스터 선택 시 디테일 자동 조회 성공
3. 소급요율 팝업 선택값 반영 성공
4. 소급요율적용 계산값(소급단가/소급금액/차이) 검증
5. 소급처리 저장 시 `C/U` 분기 및 이력 저장 검증
6. 메뉴 접근권한 검증(`WM_RATE_RETROACT_MNG`)
