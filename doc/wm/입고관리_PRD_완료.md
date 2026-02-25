# 입고관리(입고처리) PRD

**화면 ID**: grMngt.dev
**화면명**: 입고처리
**화면 패턴**: P4-4
**문서 버전**: 1.0
**작성일**: 2026-02-26

---

## 1. User Flow (화면 간 유기적 흐름)

```
[화면 진입]
    ↓
[OPEN 이벤트]
  - 입고유형 콤보 로드 (공통코드 152)
  - 입고상태 콤보 로드 (공통코드 153)
  - 출발지유형 콤보 로드 (공통코드)
  - 예정일자 From~To = 오늘날짜 자동 셋팅
    ↓
[검색 조건 입력]
  - 작업장 (필수, 팝업 선택)
  - 고객 (팝업 선택)
  - 입고유형 / 입고상태 / 예정일자 / 입고일자
  - 아이템 (팝업) / 오더번호 / 출발지유형 / 출발지 / 차량번호
    ↓
[검색 버튼 클릭]
  → TB_WM02001 + TB_WM02002 JOIN 조회
  → 입고예정목록 그리드 Display
    ↓
[입고예정 행 클릭]
  → 입고예정상세 탭: TB_WM02002 조회 (gr_prar_no 기준)
  → 입고처리내역 탭: TB_WM05001 조회 (exce_rslt_type = 'DP','RC')
  → 고객재고속성 조회 (TB_WM01001, 입출고구분='입고') → Tab 상단 Display
  → 고객RULE 조회 (TB_WM01002) → 저장 시 Validation 사용
    ↓
[입고예정상세 탭에서 편집]
  - 입고로케이션: STAGED 로케이션 드롭다운 선택 (필수)
  - 입고물량: 숫자 입력 (필수, 음수 불가)
  - 재고속성01~10: 텍스트 편집
  - 비고: 텍스트 편집
    ↓
[저장 버튼] → 입고내역저장 프로세스 (6단계 트랜잭션)
    ↓                    ↓
  성공                   실패
  - 상태: 입고처리(20)     - 에러 메시지 Display
  - 입고처리내역 탭 갱신
    ↓
[입고확정 버튼] → 입고상태 = '입고처리'(20)인 경우만 가능
  → 입고상태: 확정(30) 업데이트
  → 오더시스템 연동 (stub)
    ↓
[입고취소 버튼] → 재고 차감 + 취소 실행실적 생성
  → 입고상태: 취소(40) 업데이트
  → 입고확정 전: 신규 입고예정 생성
  → 입고확정 후: 작업단계별실적취소 호출 (stub)
```

---

## 2. UI Component List (Rails 8 기반)

| 컴포넌트 | 역할 | 파일 경로 |
|---------|------|----------|
| `Wm::GrPrars::PageComponent` | 전체 화면 래퍼 | `app/components/wm/gr_prars/page_component.rb` |
| `Ui::SearchFormComponent` | 검색 폼 (접기/펼치기) | 공통 컴포넌트 |
| `Ui::GridHeaderComponent` | 그리드 헤더 + 버튼 | 공통 컴포넌트 |
| `Ui::AgGridComponent` | AG Grid 인스턴스 | 공통 컴포넌트 |
| `wm_gr_prar_grid_controller.js` | Stimulus 컨트롤러 | `app/javascript/controllers/` |
| `Wm::GrPrarsController` | Rails API 컨트롤러 | `app/controllers/wm/gr_prars_controller.rb` |

### 화면 레이아웃

```
┌─────────────────────────────────────────────────────────┐
│ 입고처리                                                    │
├─────────────────────────────────────────────────────────┤
│ [검색폼] 작업장* | 고객 | 입고유형 | 입고상태 | 예정일자     │
│          입고일자 | 아이템 | 오더번호 | 출발지유형 | 출발지   │
│          차량번호                              [검색]      │
├─────────────────────────────────────────────────────────┤
│ [입고예정목록] - 읽기전용 그리드 (행 선택 → 탭 로드)        │
│ 입고예정번호 | 고객 | 입고유형 | 오더사유 | 입고상태 |        │
│ 입고예정일자 | 입고일자 | 시간 | 오더번호 | 출발지 |          │
│ 차량번호(편집) | 기사명 | 기사전화번호 | 운송사 | 비고        │
├─────────────────────────────────────────────────────────┤
│ [입고예정상세] [입고처리내역]  ← 탭                          │
│                                                          │
│ Tab1: 입고예정상세목록                                      │
│ 라인번호 | 아이템코드 | 아이템명 | 단위 | 예정수량            │
│ 입고로케이션(편집*) | 입고물량(편집*) | 입고실적물량            │
│ 재고속성01~10(편집) | 비고                                  │
│                                                          │
│ Tab2: 입고처리내역 (읽기전용)                                │
│ 라인번호 | 순번 | 처리유형 | 아이템코드 | 입고로케이션          │
│ 입고물량 | 단위 | 입고일자 | 재고속성01~10                   │
├─────────────────────────────────────────────────────────┤
│                         [저장] [입고확정] [입고취소]         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Data Mapping (DB 메타데이터)

### 3.1 TB_WM02001 - 입고예정 (헤더)

| 화면 항목 | 영문속성명 | DB 컬럼 | 타입 | 필수 | 비고 |
|---------|----------|--------|------|------|------|
| 입고예정번호 | grPrarNo | gr_prar_no | VARCHAR(20) PK | Y | 시퀀스 자동생성 |
| 작업장 | workplCd | workpl_cd | VARCHAR(20) | Y | - |
| 법인코드 | corpCd | corp_cd | VARCHAR(10) | Y | - |
| 고객 | custCd | cust_cd | VARCHAR(20) | Y | - |
| 입고유형 | grTypeCd | gr_type_cd | VARCHAR(10) | - | 공통코드 152 |
| 오더사유 | ordReasonCd | ord_reason_cd | VARCHAR(10) | - | 공통코드 87 |
| 입고상태 | grStatCd | gr_stat_cd | VARCHAR(10) | Y | 공통코드 153, 기본값:10 |
| 입고예정일자 | prarYmd | prar_ymd | VARCHAR(8) | - | YYYYMMDD |
| 입고일자 | grYmd | gr_ymd | VARCHAR(8) | - | YYYYMMDD |
| 입고시간 | grHms | gr_hms | VARCHAR(6) | - | HHMMSS |
| 오더번호 | ordNo | ord_no | VARCHAR(30) | - | - |
| 관련출고오더번호 | relGiOrdNo | rel_gi_ord_no | VARCHAR(30) | - | - |
| 출발지유형 | dptarTypeCd | dptar_type_cd | VARCHAR(10) | - | - |
| 출발지 | dptarCd | dptar_cd | VARCHAR(20) | - | - |
| 차량번호 | carNo | car_no | VARCHAR(20) | - | 편집 가능 |
| 기사명 | driverNm | driver_nm | VARCHAR(50) | - | - |
| 기사전화번호 | driverTelno | driver_telno | VARCHAR(20) | - | 편집 가능 |
| 운송사 | transcoCd | transco_cd | VARCHAR(20) | - | - |
| 비고 | rmk | rmk | VARCHAR(500) | - | 편집 가능 |
| 생성자 | createBy | create_by | VARCHAR(50) | - | 자동 |
| 생성일시 | createTime | create_time | DATETIME | - | 자동 |
| 수정자 | updateBy | update_by | VARCHAR(50) | - | 자동 |
| 수정일시 | updateTime | update_time | DATETIME | - | 자동 |

### 3.2 TB_WM02002 - 입고예정상세

| 화면 항목 | 영문속성명 | DB 컬럼 | 타입 | 필수 | 비고 |
|---------|----------|--------|------|------|------|
| 입고예정번호 | grPrarNo | gr_prar_no | VARCHAR(20) PK | Y | 복합 PK |
| 라인번호 | lineno | lineno | INTEGER PK | Y | 복합 PK |
| 아이템코드 | itemCd | item_cd | VARCHAR(30) | Y | - |
| 아이템명 | itemNm | item_nm | VARCHAR(200) | - | 비정규화 |
| 단위코드 | unitCd | unit_cd | VARCHAR(10) | - | - |
| 입고예정수량 | grPrarQty | gr_prar_qty | DECIMAL(18,3) | - | - |
| 입고로케이션 | grLocCd | gr_loc_cd | VARCHAR(20) | Y* | STAGED 로케이션 |
| 입고물량 | grQty | gr_qty | DECIMAL(18,3) | Y* | 음수 불가 |
| 입고실적물량 | grRsltQty | gr_rslt_qty | DECIMAL(18,3) | - | 누적 합산 |
| 입고일자 | grYmd | gr_ymd | VARCHAR(8) | - | - |
| 입고시간 | grHms | gr_hms | VARCHAR(6) | - | - |
| 입고상태 | grStatCd | gr_stat_cd | VARCHAR(10) | - | 공통코드 153 |
| 재고속성01~10 | stockAttr01~10 | stock_attr_col01~10 | VARCHAR(100) | - | - |
| 비고 | rmk | rmk | VARCHAR(500) | - | - |

### 3.3 TB_WM04001 - 재고속성

| DB 컬럼 | 타입 | 비고 |
|--------|------|------|
| stock_attr_no | VARCHAR(10) PK | 시퀀스 생성 |
| corp_cd | VARCHAR(10) | - |
| cust_cd | VARCHAR(20) | - |
| item_cd | VARCHAR(30) | - |
| stock_attr_col01~10 | VARCHAR(100) | - |

### 3.4 TB_WM04002 - 재고속성번호별재고

| DB 컬럼 | 타입 | 비고 |
|--------|------|------|
| corp_cd + workpl_cd + stock_attr_no | 복합 PK | - |
| cust_cd, item_cd | VARCHAR | - |
| basis_unit_cls | VARCHAR(10) | 기본단위분류 |
| basis_unit_cd | VARCHAR(10) | 기본단위 |
| qty | DECIMAL(18,3) | 물량 기본:0 |
| alloc_qty, pick_qty, hold_qty | DECIMAL(18,3) | 기본:0 |

### 3.5 TB_WM04003 - 속성/로케이션별재고

| DB 컬럼 | 타입 | 비고 |
|--------|------|------|
| corp_cd + workpl_cd + stock_attr_no + loc_cd | 복합 PK | - |
| (이하 TB_WM04002와 동일) | - | - |

### 3.6 TB_WM04004 - 로케이션별재고

| DB 컬럼 | 타입 | 비고 |
|--------|------|------|
| corp_cd + workpl_cd + cust_cd + loc_cd + item_cd | 복합 PK | - |
| (이하 TB_WM04002와 동일) | - | - |

### 3.7 TB_WM05001 - 실행실적

| DB 컬럼 | 타입 | 비고 |
|--------|------|------|
| exce_rslt_no | VARCHAR(10) PK | 시퀀스 생성 |
| op_rslt_mngt_no | VARCHAR(20) | 운영실적관리번호(=입고예정번호) |
| op_rslt_mngt_no_seq | INTEGER | 입고예정라인번호 |
| exce_rslt_type | VARCHAR(10) | DP:입고, CC:취소 |
| workpl_cd | VARCHAR(20) | - |
| corp_cd | VARCHAR(10) | - |
| cust_cd | VARCHAR(20) | - |
| item_cd | VARCHAR(30) | - |
| from_loc | VARCHAR(20) | 출발지 로케이션 |
| to_loc | VARCHAR(20) | 입고 로케이션 |
| rslt_qty | DECIMAL(18,3) | 실적물량 |
| rslt_cbm | DECIMAL(18,5) | 실적CBM |
| rslt_total_wt | DECIMAL(18,5) | 실적총중량 |
| rslt_net_wt | DECIMAL(18,5) | 실적순중량 |
| basis_unit_cls | VARCHAR(10) | - |
| basis_unit_cd | VARCHAR(10) | - |
| ord_no | VARCHAR(30) | 오더번호 |
| exec_ord_no | VARCHAR(30) | 실행오더번호 |
| exce_rslt_ymd | VARCHAR(8) | 실행실적일자 |
| exce_rslt_hms | VARCHAR(6) | 실행실적시간 |
| stock_attr_no | VARCHAR(10) | 재고속성번호 |
| stock_attr_col01~10 | VARCHAR(100) | - |

---

## 4. 공통코드 매핑

| 코드분류 | 코드 | 사용 화면/필드 | 설명 |
|---------|------|-------------|------|
| 87 | 오더사유 | 입고예정목록 - 오더사유 | - |
| 113 | 실행실적유형 | 입고처리내역 - 처리유형 | DP:입고, CC:취소 |
| 152 | 입고유형 | 검색조건, 입고예정목록 | - |
| 153 | 입고상태 | 검색조건, 입고예정목록 | 10:미입고, 20:입고처리, 30:입고확정, 40:입고취소 |

---

## 5. Logic Definition (버튼별 비즈니스 로직)

### 5.1 검색 버튼

```sql
SELECT a.*, b.item_cd
FROM tb_wm02001 a
LEFT JOIN tb_wm02002 b ON a.gr_prar_no = b.gr_prar_no
WHERE a.workpl_cd = :workpl_cd
  AND (:cust_cd IS NULL OR a.cust_cd = :cust_cd)
  AND (:gr_type_cd IS NULL OR a.gr_type_cd = :gr_type_cd)
  AND (:gr_stat_cd IS NULL OR a.gr_stat_cd = :gr_stat_cd)
  AND (:prar_ymd_from IS NULL OR a.prar_ymd >= :prar_ymd_from)
  AND (:prar_ymd_to IS NULL OR a.prar_ymd <= :prar_ymd_to)
  AND (:gr_ymd IS NULL OR a.gr_ymd = :gr_ymd)
  AND (:item_cd IS NULL OR b.item_cd = :item_cd)
  AND (:ord_no IS NULL OR a.ord_no LIKE '%:ord_no%')
  AND (:car_no IS NULL OR a.car_no LIKE '%:car_no%')
ORDER BY a.gr_prar_no DESC
```

### 5.2 저장 버튼 (입고내역저장) - 6단계 트랜잭션

입고예정상세목록에서 `gr_qty > 0`인 라인별 루프:

```
1) 재고속성 조회 (tb_wm04001)
   - corp_cd + cust_cd + item_cd + stock_attr_col01~10 → stock_attr_no 조회
   - 없으면 → 2번으로

2) 재고속성 생성 (tb_wm04001)
   - stock_attr_no = "SA" + Time.current.strftime("%Y%m%d%H%M%S") + rand(100..999)
   - INSERT into tb_wm04001

3) 재고생성 (3개 테이블 동시 처리)
   3-1) tb_wm04002: corp_cd+workpl_cd+stock_attr_no 키로 UPSERT
        → qty = qty + gr_qty
   3-2) tb_wm04003: corp_cd+workpl_cd+stock_attr_no+loc_cd 키로 UPSERT
        → qty = qty + gr_qty
   3-3) tb_wm04004: corp_cd+workpl_cd+cust_cd+loc_cd+item_cd 키로 UPSERT
        → qty = qty + gr_qty

4) 실행실적 생성 (tb_wm05001)
   - exce_rslt_no = "ER" + Time.current.strftime("%Y%m%d%H%M%S") + rand(100..999)
   - exce_rslt_type = 'DP'
   - to_loc = gr_loc_cd (입고로케이션)
   - op_rslt_mngt_no = gr_prar_no
   - op_rslt_mngt_no_seq = lineno

5) 입고예정상세 수정 (tb_wm02002)
   - gr_ymd = 오늘날짜, gr_hms = 현재시간
   - gr_rslt_qty = gr_rslt_qty + gr_qty
   - gr_stat_cd = (gr_rslt_qty + gr_qty > 0 ? '20' : '10')

6) 입고예정 수정 (tb_wm02001)
   - gr_ymd = 오늘날짜, gr_hms = 현재시간
   - gr_stat_cd = (전체 상세의 총 입고실적물량 > 0 ? '20' : '10')
```

### 5.3 입고확정 버튼

```
전제 조건: gr_stat_cd = '20'(입고처리)인 경우만 가능
           그 외: "입고확정불가" 에러 메시지

1) tb_wm05001에서 op_rslt_mngt_no = gr_prar_no AND exce_rslt_type = 'DP' 조회

2) 오더시스템 연동 (stub - 현 프로젝트에서 메서드만 정의)
   - 작업단계별실적등록 오퍼레이션 호출
   - 작업단계별실적아이템등록 오퍼레이션 호출

3) 입고확정 처리
   - tb_wm02001.gr_stat_cd = '30'
   - tb_wm02002.gr_stat_cd = '30' (해당 gr_prar_no 전체)
```

### 5.4 입고취소 버튼

```
1) tb_wm05001 조회 (exce_rslt_type = 'DP')

2) 재고 가용재고 확인 (tb_wm04003)
   - 가용재고 = qty - alloc_qty - pick_qty
   - 가용재고 < 실적물량 → 에러: "취소처리할 재고가 존재하지 않습니다.(아이템코드-로케이션-실적물량)"

3) 재고 차감
   - tb_wm04002/04003/04004 qty -= rslt_qty

4) 실행실적 생성 (CC, 역전)
   - exce_rslt_type = 'CC'
   - rslt_qty = rslt_qty * -1

5) 입고취소 처리
   - tb_wm02001/02002.gr_stat_cd = '40'

6) [선택] 입고확정 전: 신규 입고예정 생성 (gr_prar_no 새로 채번)

7) [선택] 입고확정 후: 작업단계별실적취소 오퍼레이션 호출 (stub)
```

### 5.5 업무 규칙

- gr_stat_cd = '30'(입고확정)이면 모든 편집 컬럼 disable
- 입고확정은 gr_stat_cd = '20'일 때만 가능
- 입고물량 음수 입력 불가 (클라이언트 + 서버 Validation)
- 고객별 shortage/overage 체크 (TB_WM01002 기반)

---

## 6. 파일 목록

| 분류 | 파일 경로 |
|-----|---------|
| 마이그레이션 | `db/migrate/20260226010000_create_wm_gr_prar_tables.rb` |
| 마이그레이션 | `db/migrate/20260226020000_create_wm_stock_tables.rb` |
| 마이그레이션 | `db/migrate/20260226030000_create_wm_exce_rslt_table.rb` |
| 모델 | `app/models/wm/gr_prar.rb` |
| 모델 | `app/models/wm/gr_prar_dtl.rb` |
| 모델 | `app/models/wm/stock_attr.rb` |
| 모델 | `app/models/wm/stock_attr_qty.rb` |
| 모델 | `app/models/wm/stock_attr_loc_qty.rb` |
| 모델 | `app/models/wm/loc_qty.rb` |
| 모델 | `app/models/wm/exce_rslt.rb` |
| 컨트롤러 | `app/controllers/wm/gr_prars_controller.rb` |
| ViewComponent | `app/components/wm/gr_prars/page_component.rb` |
| ViewComponent | `app/components/wm/gr_prars/page_component.html.erb` |
| Stimulus | `app/javascript/controllers/wm_gr_prar_grid_controller.js` |
| 라우트 | `config/routes.rb` (수정) |
| 메뉴시드 | `db/seeds/wm_gr_prar_menu.rb` |
