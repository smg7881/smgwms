# 제품 요구사항 정의서 (PRD) - 환율 정보 수집 배치

## 1. Overview (개요)
본 문서는 외부 API를 활용하여 일별 환율 정보를 자동으로 수집하고 내부 데이터베이스(`std_exchange_rates`)에 적재하는 배치(Batch) 프로그램의 요구사항을 정의합니다. 수집된 환율 데이터는 WMS 내 다국어 통화 처리 및 정산/청구 등의 환율 계산 기준으로 활용됩니다.

## 2. Batch Flow (배치 처리 흐름)
1. **배치 트리거 (Trigger)**: 스케줄러에 의해 매일 지정된 시각에 백그라운드 작업으로 실행됩니다.
2. **외부 API 호출**: 한국수출입은행(KEXIM) 등의 외부 환율 정보 제공 API에 당일 환율 데이터를 요청합니다.
3. **응답 데이터 수신 및 파싱**: API로부터 수신된 JSON 형태의 응답 데이터를 시스템에서 사용 가능한 형태로 파싱합니다.
4. **유효성 검증**: 수신된 데이터의 정상 여부(결과 코드, 필수 필드 누락 등)를 확인합니다.
5. **데이터 적재 (Upsert)**: `std_exchange_rates` 테이블에 날짜, 국가, 금융기관, 회차, 통화별 환율 정보를 갱신 및 추가합니다.
6. **결과 기록 (Logging)**: 성공/실패 여부를 애플리케이션 로그에 기록하고, 필요 시 모니터링 시스템과 연동합니다.

---

## 3. Data Mapping (데이터 매핑)

### 3.1 Input Parameter (요청 데이터)
*   **검색일자** (`searchdate`): 조회 대상 일자 (YYYYMMDD 포맷)
*   **인증키** (`authkey`): API 사용을 위한 인증 키 (환경변수 `EXCHANGE_API_KEY`에서 가져오거나 설정 파일 참조)
*   **데이터타입** (`data`): "AP01" (환율)

### 3.2 Output Data (응답 데이터 및 DB 매핑)
기존 `std_exchange_rates` 테이블(`StdExchangeRate` 모델)을 그대로 활용합니다. 복합 유니크 키(`ctry_cd`, `fnc_or_cd`, `std_ymd`, `anno_dgrcnt`, `mon_cd`)를 기준으로 Upsert를 진행합니다.

| 분류 | 속성명 (Table Column) | API 매핑 데이터 | 설명 |
| :--- | :--- | :--- | :--- |
| **PK/UK** | `ctry_cd` | `"KR"` 고정 (혹은 통화국가코드) | 시스템상 조회 기준 국가 (기본 한국 기준이므로 KR) |
| **PK/UK** | `fnc_or_cd` | `"KEXIM"` 고정 | 조회 금융기관 코드 (Korea Eximbank) |
| **PK/UK** | `std_ymd` | 검색 일자 (`YYYYMMDD`) | 환율 기준 일자 |
| **PK/UK** | `anno_dgrcnt` | `"1"` 고정 | 고시 회차 (하루 1번 기준) |
| **PK/UK** | `mon_cd` | `cur_unit` | 통화 코드 (예: USD, EUR) |
| **Data** | `sendmoney_sndg` | `tts` | 송금 보내실 때 환율 (Parse to Decimal) |
| **Data** | `sendmoney_rcvng`| `ttb` | 송금 받으실 때 환율 (Parse to Decimal) |
| **Data** | `tradg_std_rt` | `deal_bas_r` | 매매 기준율 (Parse to Decimal) |
| **Data** | `convmoney_rt` | `bkpr` | 장부가격 |
| **Data** | `if_yn_cd` | `"Y"` 고정 | 인터페이스 유무 (Y) |
| **Data** | `use_yn_cd` | `"Y"` 고정 | 사용 여부 (Y) |

> *API 특성상 쉼표(,)가 포함된 문자열로 숫자가 내려올 수 있으므로, parseFloat 시 `,` 제거 로직이 필수적입니다.*
> *일부 API 필드에 없는 정보(`cash_buy`, `cash_sell` 등)는 `nil`(null) 로 유지합니다.*

---

## 4. Logic Definition (상세 로직)

### 4.1 스케줄링 로직 (Scheduling)
*   **실행 방식**: ActiveJob을 활용하여 `Std::SyncExchangeRatesJob`로 생성.
*   하루 단위 고시 데이터가 생성되는 시점(매일 오전 11:30경 혹은 환율 마감 후)을 타깃으로 스케줄링합니다.

### 4.2 외부 연동 및 휴일 처리 로직 (Holiday Handling)
*   한국수출입은행 API는 **주말 및 공휴일에는 데이터를 반환하지 않음 (빈 배열 반환 또는 결과코드 오류)**.
*   오늘 데이터가 없는 경우, 어제(`Date.yesterday`)의 데이터를 기준으로 **반복 조회(Fallback)**하여, 가장 최근 영업일의 데이터를 현재 일자로 끌어와 `std_exchange_rates`에 당일 일자(`std_ymd`)로 Insert합니다. 이를 통해 시스템 상 공백 없이 환율 정보가 유지됩니다.

### 4.3 데이터 처리 로직 (Upsert)
*   `StdExchangeRate.find_or_initialize_by` 구문을 활용하여 `ctry_cd`, `fnc_or_cd`, `std_ymd`, `anno_dgrcnt`, `mon_cd`가 동일한 건이 있으면 `update!`, 없으면 `save!`를 수행합니다.

## 5. Development Tasks
1. `app/services/std/exchange_rate_sync_service.rb` 모듈 구현 (API 통신, 데이터 파싱, 휴일 대비 이전 데이터 스캔 등)
2. `app/jobs/std/sync_exchange_rates_job.rb` 작성
3. 개발 결과 및 사용법을 담은 마크다운(`환율정보_연동배치_개발완료보고서.md`) 작성
