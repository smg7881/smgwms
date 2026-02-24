# 실행오더전송이력조회 PRD

## 1. 개요
실행오더의 생성내역 및 보관/운송 시스템으로의 전송 결과 리스트를 조회하고, 전송 오류가 발생한 내역에 대해 재전송 처리를 수행하는 화면입니다.

## 2. User Flow (화면 간의 유기적인 흐름)
1. **오더번호 검색**: 사용자가 `오더번호`를 입력하여 실행오더 전송 이력을 검색합니다.
   * 필요시 오더번호 팝업을 통해 상세 오더를 선택할 수 있습니다.
2. **이력 목록 조회 (List)**: 검색 조건에 맞는 전송 이력 리스트가 화면에 노출됩니다.
   * 조회 목록 내용: 실행구분, 실행오더번호, 출발지, 도착지, 작업장, 전송순번, 전송구분, 전송시간, 수신시간, 전송여부, 배차지시번호, 오류메시지
3. **재전송 처리**: 
   * 조회된 내역 중 전송 여부가 오류(`E`, Error)인 건을 선택합니다.
   * 상단의 `재전송` 버튼을 클릭하여 수동으로 전송을 재시도합니다.
   * 재전송 시 전송 상태가 `N` (대기) 등으로 변경되어 백엔드 배치나 연동 로직이 다시 읽어갈 수 있도록 처리됩니다.

## 3. UI Component List (Rails 8 & Stimulus 기반)
* **Page Layout**: `Om::BasePageComponent` 모듈 상속
* **서치폼 영역 (오더번호 검색)**: `resource_form` (컴포넌트 가이드라인 준수)을 활용한 단일 검색.
    * 조회 필드: 오더번호(Text + 팝업 지원 가능)
    * `search-form` Stimulus Controller 연동(`data-controller="search-form"`).
* **그리드 영역 (실행오더목록)**: `ag_grid_tag`
    * 단순 목록 조회 및 단일/다중 행 선택(Checkbox)을 제공하는 AG Grid (`rowSelection: "multiple"`).
* **Toolbar 컴포넌트**: `Ui::GridToolbarComponent`
    * 버튼: `조회`, `재전송`.
* **프론트엔드 액션 제어**: `om_execution_order_transmission_grid_controller.js`
    * 체크된 행 중 상태가 `E`인 것들만 필터링하여 재전송 API 요청을 보내는 기능 처리.

## 4. Data Mapping (화면 입력 필드와 매칭되는 DB 메타데이터)
> **대상 테이블 (예상):** 출고실행오더(`tb_om04014i`), 입고실행오더(`tb_om04012i`), 운송실행오더(`tb_om04010i`) 혹은 이들을 감싸는 통합 이력(Log) 테이블. 
*(smgWms 기준 `om_order_transmission_logs`, `om_work_routes` 등 연관 테이블 탐색 매핑)*

| 화면 항목명 | 영문/속성명 | 연관 DB 컬럼 | 속성 | 비고 |
|---|---|---|---|---|
| 오더번호 | ordNo | `ord_no` | E, M | 검색조건 |
| 선택 | slc | - | R | AG Grid Checkbox |
| 실행구분 | exceSctn | `work_step_cd` 혹은 구분값 | R | 10(운송), 20(입고), 30(출고), 창고배차지시 등으로 명칭 치환하여 표기 |
| 실행오더번호 | eoNo | `eo_no` / `route_no` | R | |
| 출발지 | dptArNm | `dpt_cd` 관련 | R | 작업장 or 고객거래처 명칭 Join |
| 도착지 | arvArNm | `arv_cd` 관련 | R | 작업장 or 고객거래처 명칭 Join |
| 작업장 | workPlNm | `work_pl_cd` | R | 출고/입고는 작업장명, 운송은 영업소(부서명) 표기 |
| 전송 순번 | trmsSeq | `trms_seq` | R | |
| 전송 구분 | trmsSctnNm | `trms_type_cd` | R | C(신규), U(수정), D(취소) 표기 |
| 전송시간 | trmsHms | `create_time` | R | |
| 수신시간 | rcvHms | `trms_end_time` | R | |
| 전송 여부 | trmsYn | `trms_status_cd` | R | Y/N/E 상태코드 |
| 배차지시번호 | asignIdctNo| `assign_no` | R | |
| 오류메시지 | errMsg | `err_msg` | R | |

## 5. Logic Definition (비즈니스 로직)
1. **코드 명칭 표기 로직**
    * `실행구분`: 각 실행오더 Table 종류에 따라 다르게 표기 (출고, 입고, 운송, 창고배차지시).
    * `출발지명 / 도착지명`: 유형코드(10:작업장, 20:고객거래처, 30:우편번호)를 판별하여 관련된 마스터 테이블(`TB_CM02004` 작업장, `TB_CM04005` 고객거래처 등)의 이름을 조인하여 표시.
    * `작업장명`: 출/입고는 작업장코드, 운송은 영업소코드(부서코드) 표시.
    * `전송구분`: C(신규), U(수정), D(취소) 변환.
2. **재전송 처리 로직**
    * 전송 여부가 `E`(Error)인 실행오더에 한하여 `재전송` 버튼이 동작합니다.
    * 재전송 시 타겟 레코드의 인터페이스(전송) 여부를 `E`에서 `N`(대기)으로 변경 업데이트하여 백그라운드 Job이 다시 채어가도록 유도합니다.

## 6. 화면 정의 (System Layout)
* **Toolbar**: 우측 상단 `조회`, `재전송` 버튼 배치.
* **검색 조건 구역**: 상단 Box 처리, 오더번호(Text/Popup).
* **Grid 구역**: 화면 하단에 꽉 차는 메인 리스트 뷰 표출. AG Grid 제공.
