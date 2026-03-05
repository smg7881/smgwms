# WM Master-Detail 표준

## 목적
- 같은 기능을 같은 로직으로 구현하기 위해 마스터-디테일 화면의 구조/행동 계약을 고정합니다.
- 구현 편차는 문서가 아니라 자동검증(테스트/CI)에서 차단합니다.

## 표준 계약
### 1. PageComponent
- `detail_collection_path`, `detail_grid_url`, `master_batch_save_url`, `detail_batch_save_url_template`를 반드시 구현합니다.
- 마스터/디테일 컬럼과 검색 필드를 분리합니다.

### 2. View(ERB)
- `data-controller="<name>-grid"` 형태를 사용합니다.
- `master-batch-url`, `detail-batch-url-template`, `detail-list-url-template` 값을 모두 주입합니다.
- `masterGrid`, `detailGrid` 타겟을 고정합니다.

### 3. Stimulus
- `BaseGridController`를 상속합니다.
- `gridRoles()`에 `master`, `detail`, `parentGrid: "master"`를 정의합니다.
- `detailLoader`, `saveMasterRows`, `saveDetailRows`를 구현합니다.

### 4. Rails Controller
- master: `index`(HTML/JSON), `batch_save`를 구현합니다.
- detail: `index`, `batch_save`를 구현합니다.
- detail CRUD는 항상 master scope 안에서 처리합니다.

### 5. Route
- master collection `batch_save`
- nested detail `index`
- nested detail collection `batch_save`

## 자동 강제 장치
### 레지스트리
- 파일: `config/master_detail_screen_contracts.yml`
- 계약 검증 대상 화면은 이 파일에 등록합니다.

### 계약 테스트
- 파일: `test/contracts/master_detail_pattern_contract_test.rb`
- 레지스트리 등록 화면이 표준 계약을 어기면 테스트 실패합니다.

### 실행
- 로컬: `ruby bin/rails test test/contracts/master_detail_pattern_contract_test.rb`
- 태스크: `ruby bin/rails wm:contracts:master_detail`
- CI: `.github/workflows/ci.yml`의 계약 테스트 단계에서 실행됩니다.

## 생성기(스캐폴드)
- 명령:
  - `ruby bin/rails generate wm:master_detail <name> <master_key> <detail_key> --namespace=<wm|std|system> --menu-code=<MENU_CODE>`
- 생성 파일:
  - page component / page erb / stimulus controller
  - master controller / detail controller
- 생성 후 해야 할 일:
  - `config/routes.rb`에 nested route 추가
  - `config/master_detail_screen_contracts.yml`에 화면 등록
  - model/query/json/validation 도메인 규칙 채우기

## 리뷰/승인 규칙
- `.github/PULL_REQUEST_TEMPLATE.md` 체크리스트의 Master-Detail 항목을 필수로 점검합니다.
- `.github/CODEOWNERS`의 패턴 소유자 승인이 없으면 머지하지 않습니다.

## 예외 처리
- 표준에서 벗어나야 하면 PR에 아래를 반드시 기록합니다.
  - 왜 표준으로 해결이 불가능한지
  - 대안 로직과 영향 범위
  - 회귀 테스트 항목
