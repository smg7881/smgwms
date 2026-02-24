# PRD - 내부오더관리 (isdOrdMngt)

## 1. 화면 정의

| 항목 | 내용 |
|---|---|
| 화면ID | isdOrdMngt |
| 화면명 | 내부오더관리 |
| 설명 | 고객의 사전오더 없이 실행시스템에서 매입으로 발생한 오더 내역을 등록/수정/취소하는 화면 |
| 화면패턴 | 폼 기반 마스터-디테일 (헤더 폼 + 출도착지 폼 + 아이템 그리드) |
| URL | /om/internal_orders |
| 메뉴코드 | OM_INTERNAL_ORD |

## 2. User Flow

### 2.1 신규 등록 흐름
1. 사용자가 "신규" 버튼 클릭
2. 오더 헤더 폼 초기화 및 편집 모드 활성화
3. 필수 필드 입력 (계약번호, 오더유형, 청구고객, 계약고객 등)
4. 출도착지 탭에서 출발지/도착지 정보 입력
5. 아이템 탭에서 행 추가 → 아이템 정보 입력 (최대 20건)
6. "저장" 버튼 클릭 → 오더번호 자동 생성 (IO + YYYYMMDD + 6자리 시퀀스)
7. 저장 성공 시 읽기 전용 모드로 전환

### 2.2 수정/저장 흐름
1. 오더번호로 검색하여 기존 오더 로드
2. 편집 가능한 필드 수정
3. 아이템 추가/삭제/수정
4. "저장" 버튼 클릭 → PATCH 요청으로 업데이트

### 2.3 오더취소 흐름
1. 오더번호로 검색하여 기존 오더 로드
2. "오더취소" 버튼 클릭 → 확인 다이얼로그
3. 취소 확인 시 cancel_yn=Y, ord_stat_cd=CANCEL로 업데이트
4. 폼을 읽기 전용으로 전환

## 3. UI Component List

### 3.1 검색 영역
- 오더번호 입력 필드
- 찾기 버튼
- 검색 버튼

### 3.2 오더 헤더 폼
읽기전용 필드:
- 오더번호 (ord_no)
- 오더상태 (ord_stat_cd)
- 오더생성일시 (created_at)

편집 가능 필드:
- 계약번호 (ctrt_no)
- 오더유형코드 (ord_type_cd)
- 청구고객코드 (bilg_cust_cd)
- 계약고객코드 (ctrt_cust_cd)
- 오더실행부서코드 (ord_exec_dept_cd)
- 오더실행부서명 (ord_exec_dept_nm)
- 오더실행담당자코드 (ord_exec_ofcr_cd)
- 오더실행담당자명 (ord_exec_ofcr_nm)
- 사유코드 (ord_reason_cd)
- 특이사항 (remk)

### 3.3 출도착지상세 탭
출발지:
- 출발지유형코드 (dpt_type_cd)
- 출발지코드 (dpt_cd)
- 출발지우편번호 (dpt_zip_cd)
- 출발지주소 (dpt_addr)
- 시작요청일 (strt_req_ymd)

도착지:
- 도착지유형코드 (arv_type_cd)
- 도착지코드 (arv_cd)
- 도착지우편번호 (arv_zip_cd)
- 도착지주소 (arv_addr)
- 납기요청일시 (aptd_req_dtm)

### 3.4 아이템상세 탭
AG Grid 컬럼:
- 순번 (seq_no)
- 아이템코드 (item_cd)
- 아이템명 (item_nm)
- 기본단위 (basis_unit_cd)
- 수량 (ord_qty)
- 수량단위 (qty_unit_cd)
- 중량 (ord_wgt)
- 중량단위 (wgt_unit_cd)
- 부피 (ord_vol)
- 부피단위 (vol_unit_cd)

행추가/행삭제 버튼 (최대 20건)

### 3.5 하단 버튼
- 신규 (newOrder)
- 오더취소 (cancelOrder)
- 저장 (saveOrder)

## 4. Data Mapping

### 4.1 오더 헤더 (om_internal_orders)
| 필드명 | 타입 | 필수 | 설명 |
|---|---|---|---|
| ord_no | string(30) | Y | 오더번호 (자동생성) |
| ord_stat_cd | string(20) | Y | 오더상태코드 (WAIT/PROC/DONE/CANCEL) |
| ctrt_no | string(30) | N | 계약번호 |
| ord_type_cd | string(20) | N | 오더유형코드 |
| bilg_cust_cd | string(20) | N | 청구고객코드 |
| ctrt_cust_cd | string(20) | N | 계약고객코드 |
| ord_exec_dept_cd | string(20) | N | 오더실행부서코드 |
| ord_exec_dept_nm | string(100) | N | 오더실행부서명 |
| ord_exec_ofcr_cd | string(20) | N | 오더실행담당자코드 |
| ord_exec_ofcr_nm | string(100) | N | 오더실행담당자명 |
| ord_reason_cd | string(20) | N | 사유코드 |
| remk | text | N | 특이사항 |
| dpt_type_cd | string(20) | N | 출발지유형코드 |
| dpt_cd | string(30) | N | 출발지코드 |
| dpt_zip_cd | string(10) | N | 출발지우편번호 |
| dpt_addr | string(200) | N | 출발지주소 |
| strt_req_ymd | string(8) | N | 시작요청일 (YYYYMMDD) |
| arv_type_cd | string(20) | N | 도착지유형코드 |
| arv_cd | string(30) | N | 도착지코드 |
| arv_zip_cd | string(10) | N | 도착지우편번호 |
| arv_addr | string(200) | N | 도착지주소 |
| aptd_req_dtm | string(14) | N | 납기요청일시 (YYYYMMDDHHMMSS) |
| wait_ord_internal_yn | string(1) | Y | 대기오더내부여부 (기본 N) |
| cancel_yn | string(1) | Y | 취소여부 (기본 N) |

### 4.2 오더 아이템 (om_internal_order_items)
| 필드명 | 타입 | 필수 | 설명 |
|---|---|---|---|
| internal_order_id | integer | Y | 오더 FK |
| seq_no | integer | Y | 순번 |
| item_cd | string(30) | Y | 아이템코드 |
| item_nm | string(100) | N | 아이템명 |
| basis_unit_cd | string(20) | N | 기본단위코드 |
| ord_qty | decimal | N | 수량 |
| qty_unit_cd | string(20) | N | 수량단위코드 |
| ord_wgt | decimal | N | 중량 |
| wgt_unit_cd | string(20) | N | 중량단위코드 |
| ord_vol | decimal | N | 부피 |
| vol_unit_cd | string(20) | N | 부피단위코드 |

## 5. Logic Definition

### 5.1 Open
- 화면 초기 로드 시 읽기 전용 모드
- 검색 영역만 활성화

### 5.2 검색
- 오더번호 입력 → JSON 조회 → 1건 반환
- 헤더 폼, 출도착지, 아이템 그리드에 데이터 채우기

### 5.3 저장
- 신규: POST /om/internal_orders → 오더번호 자동 생성
- 수정: PATCH /om/internal_orders/:id → 헤더 수정 + 아이템 delete_all 후 재생성

### 5.4 취소
- POST /om/internal_orders/:id/cancel
- cancel_yn=Y, ord_stat_cd=CANCEL

### 5.5 신규
- 폼 초기화 + 편집 모드 활성화

## 6. 업무 규칙

- 오더번호 자동생성: IO + YYYYMMDD + 6자리 시퀀스 (예: IO20260224000001)
- 아이템 최대 20건 제한
- 가용재고체크 미적용 (내부오더이므로)
- 대기오더내부여부(wait_ord_internal_yn) = 'N' 필터로 내부오더만 조회
- 취소된 오더는 수정 불가
