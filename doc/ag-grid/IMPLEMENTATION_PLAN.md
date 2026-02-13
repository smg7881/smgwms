# AG Grid 구현 계획

> **v1.2** — 화이트리스트 검증 강제 + CDN 장애 대비 추가

## 구현 순서

### Step 1: Importmap에 AG Grid 핀 추가 (버전 고정)
- **파일**: `config/importmap.rb`
- **작업**: `pin "ag-grid-community"` CDN 핀 1줄 추가
- **중요**: `@35.1.0` 정확한 patch 버전까지 고정
- **URL**: `https://cdn.jsdelivr.net/npm/ag-grid-community@35.1.0/dist/ag-grid-community.auto.esm.min.js`

### Step 2: Stimulus 컨트롤러 생성
- **파일**: `app/javascript/controllers/ag_grid_controller.js` (신규)
- **작업**: AG Grid 래핑 Stimulus 컨트롤러 작성
  - 다크 테마 설정 (themeQuartz.withParams)
  - Turbo 캐시 대응 (`turbo:before-cache` → `#teardown()`)
  - Formatter Registry (키 → 함수 매핑, 문자열 expression 배제)
  - 한국어 locale 텍스트 (AG_GRID_LOCALE_KO)
  - 에러 오버레이와 빈 데이터 오버레이 분리
  - createGrid / destroy 라이프사이클
  - URL fetch 또는 인라인 데이터 지원
  - refresh(), exportCsv() 공개 메서드

### Step 3: 컨트롤러 등록
- **파일**: `app/javascript/controllers/index.js`
- **작업**: `AgGridController` import + register 2줄 추가

### Step 4: View Helper 생성
- **파일**: `app/helpers/ag_grid_helper.rb` (신규)
- **작업**: `ag_grid_tag()` 헬퍼 메서드 작성
- **참고**: columnDefs에는 데이터 속성만 (formatter는 Registry 키)
- **중요**: `ALLOWED_COLUMN_KEYS` 화이트리스트 검증 + `sanitize_column_defs` 메서드
  - 허용되지 않은 키(`valueFormatter`, `cellRenderer` 등)는 자동 제거
  - 제거 시 `Rails.logger.warn` 경고 출력

### Step 5: Posts 컨트롤러 JSON 응답 추가
- **파일**: `app/controllers/posts_controller.rb`
- **작업**: index 액션에 `respond_to` 블록 추가

### Step 6: Posts 뷰에 AG Grid 적용 + CDN 장애 대비 CSS
- **파일**: `app/views/posts/index.html.erb`
- **작업**: 기존 HTML 테이블을 `ag_grid_tag` 헬퍼로 교체
- **참고**: `created_at` 컬럼에 `formatter: "date"` 사용
- **파일**: `app/assets/stylesheets/application.css`
- **작업**: AG Grid 로딩 폴백 CSS 추가 (`[data-ag-grid-target="grid"]:empty::after`)
- **참고**: CDN 장애 시 사용자에게 "그리드를 불러오는 중..." 안내 표시

### Step 7: 테스트 작성
- Helper 테스트 (`ag_grid_helper_test.rb`)
  - **중요**: 화이트리스트 검증 테스트 포함 (허용되지 않은 키 제거 확인)
- Controller JSON 테스트 (`posts_controller_test.rb`)
- System 테스트 (`ag_grid_test.rb`)
  - **중요**: `assert_selector`, `assert_text`에 `wait:` 옵션으로 비동기 fetch 대기
  - Turbo 네비게이션 왕복 테스트 포함

### Step 8: CSP 설정 확인 (참고)
- **파일**: `config/initializers/content_security_policy.rb`
- **작업**: 현재 비활성화(주석) 상태 확인. 향후 CSP 활성화 시 `cdn.jsdelivr.net` 허용 필요
- **참고**: 현재는 코드 변경 없음, 문서화만
