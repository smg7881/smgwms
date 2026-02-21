# PRD: 메뉴관리 (Menu Management)

## 1. 개요

### 1.1 목적
시스템 관리자가 사이드바 메뉴 구조를 DB에서 관리할 수 있는 `메뉴관리` 화면을 제공합니다.

- 현재 하드코딩된 메뉴(`app/views/shared/_sidebar.html.erb`)를 DB 기반으로 전환한다.
- 메뉴 추가/수정/삭제를 코드 수정 없이 운영할 수 있게 한다.
- 메뉴 트리 무결성(부모/자식 관계, 레벨, 순환 참조)을 애플리케이션 레벨에서 보장한다.

### 1.2 메뉴 위치
- 사이드바 경로: `시스템 > 메뉴관리`
- 탭 ID: `system-menus`
- URL: `/system/menus`

### 1.3 범위 (MVP)
- 포함:
  - 메뉴 CRUD (생성/수정/삭제)
  - 메뉴 조회/검색
  - 사이드바 DB 렌더링
- 제외:
  - 권한(Role)별 메뉴 노출 제어
  - 완전한 TabRegistry 동적화

### 1.4 탭 정책 (중요)
MVP에서는 `TabRegistry`를 유지한다.

- `tab_id`가 `TabRegistry`에 있으면 기존 탭 오픈 동작 사용
- `tab_id`가 없거나 미등록이면 URL 직접 이동
- 메뉴관리 저장 시 `tab_id` 형식만 검증하고, 존재 여부 검증은 경고 수준으로 처리

이 정책으로 "사이드바 DB 동적화"와 "탭 시스템 안정성"을 동시에 유지한다.

---

## 2. 데이터베이스 설계

### 2.1 테이블: `adm_menus`

| 컬럼명 | 타입 | 제약조건 | 설명 |
|---|---|---|---|
| `id` | integer | PK, auto increment | 기본키 |
| `menu_cd` | string(20) | NOT NULL, UNIQUE, INDEX | 메뉴 코드 |
| `menu_nm` | string(100) | NOT NULL | 메뉴명 |
| `parent_cd` | string(20) | NULL, INDEX | 상위 메뉴 코드 (`NULL`이면 최상위) |
| `menu_url` | string(200) | NULL | 메뉴 URL |
| `menu_icon` | string(10) | NULL | 메뉴 아이콘 |
| `sort_order` | integer | NOT NULL, DEFAULT 0 | 같은 부모 내 정렬 |
| `menu_level` | integer | NOT NULL, DEFAULT 1 | 깊이 (`1..3`) |
| `menu_type` | string(10) | NOT NULL, DEFAULT 'MENU' | `FOLDER` / `MENU` |
| `use_yn` | string(1) | NOT NULL, DEFAULT 'Y' | `Y` / `N` |
| `tab_id` | string(50) | NULL | 탭 ID |
| `created_at` | datetime | NOT NULL | 생성일시 |
| `updated_at` | datetime | NOT NULL | 수정일시 |

### 2.2 마이그레이션

```ruby
# db/migrate/XXXXXXXX_create_adm_menus.rb
class CreateAdmMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_menus do |t|
      t.string  :menu_cd,    limit: 20,  null: false
      t.string  :menu_nm,    limit: 100, null: false
      t.string  :parent_cd,  limit: 20
      t.string  :menu_url,   limit: 200
      t.string  :menu_icon,  limit: 10
      t.integer :sort_order, null: false, default: 0
      t.integer :menu_level, null: false, default: 1
      t.string  :menu_type,  limit: 10,  null: false, default: "MENU"
      t.string  :use_yn,     limit: 1,   null: false, default: "Y"
      t.string  :tab_id,     limit: 50
      t.timestamps
    end

    add_index :adm_menus, :menu_cd, unique: true
    add_index :adm_menus, :parent_cd
    add_index :adm_menus, [:parent_cd, :sort_order, :menu_cd]
  end
end
```

### 2.3 시드 데이터
기존 사이드바 메뉴를 초기값으로 이관한다.

- 1레벨: `MAIN`, `POST`, `ANALYSIS`, `SYSTEM`
- 2레벨: 각 하위 메뉴
- `SYS_MENU` (`/system/menus`, `tab_id: system-menus`) 포함

---

## 3. 도메인 규칙

### 3.1 계층 규칙
- 최대 3레벨(`menu_level` 1~3) 지원
- `parent_cd`가 있으면 실제 부모가 반드시 존재해야 함
- `menu_level = parent.menu_level + 1` 이어야 함
- 자기 자신을 부모로 지정 불가
- 순환 참조 금지

### 3.2 타입 규칙
- `menu_type = FOLDER`면 `menu_url`은 `NULL` 허용
- `menu_type = MENU`면 `menu_url` 필수

### 3.3 삭제 규칙
- 활성/비활성 여부와 무관하게 자식이 있으면 삭제 불가
- 에러 메시지: `하위 메뉴가 존재하여 삭제할 수 없습니다.`

---

## 4. 화면 설계

### 4.1 구성
- 검색폼: `search_form_tag`
  - `menu_cd`, `menu_nm`, `use_yn`
- 그리드: `ag_grid_tag`
  - 읽기 전용
  - 작업 컬럼: `하위추가`, `수정`, `삭제`
- 모달: 생성/수정 공용

### 4.2 AG Grid 컬럼
- `menu_nm` (트리 렌더러)
- `menu_cd`
- `menu_url`
- `sort_order`
- `menu_type`
- `use_yn`
- `tab_id`
- `actions` (action 렌더러)

### 4.3 셀 렌더러
- `treeMenuCellRenderer`
  - `menu_level` 기반 들여쓰기
  - `FOLDER`: `📁`, `MENU`: `📄`
  - 폴더 행에는 `.tree-menu-folder` 클래스 부여
- `actionCellRenderer`
  - `➕`, `✏️`, `🗑️`
  - Stimulus 이벤트(`menu-crud:*`) 전파

---

## 5. API 설계

### 5.1 라우팅

```ruby
namespace :system do
  resources :menus, only: [:index, :create, :update, :destroy]
end
```

### 5.2 컨트롤러
`System::MenusController`

- `before_action :require_authentication`
- `index`
  - 검색조건 없음: 트리 순서 반환
  - 검색조건 있음: 필터된 플랫 목록 반환
- `create`, `update`, `destroy`
  - JSON 응답 `{ success, message/errors, menu }`

### 5.3 검색 규칙
- 기본: `LIKE '%keyword%'`
- 데이터 증가 시 대응:
  - 접두 검색(`keyword%`) 옵션 추가
  - 필요 시 별도 검색 컬럼/색인 전략 도입

`LIKE '%...%'`는 일반 인덱스를 충분히 활용하지 못하므로, 성능 가정은 "현재 데이터 규모에서 허용"으로 명시한다.

---

## 6. 모델 설계

### 6.1 `AdmMenu` 검증
- `menu_cd`: presence/uniqueness/length
- `menu_nm`: presence/length
- `use_yn`: `Y`, `N`
- `menu_type`: `FOLDER`, `MENU`
- `menu_level`: `1..3`
- `sort_order`: integer
- 도메인 커스텀 검증:
  - `parent_exists`
  - `level_consistency`
  - `prevent_cycle`
  - `url_required_for_menu`

### 6.2 트리 조회
- `tree_ordered`는 재귀(또는 스택) 방식으로 N 레벨 확장 가능하게 구현
- 하드코딩 2레벨 루프 금지

### 6.3 사이드바 조회
- `sidebar_tree`는 1회 조회 후 메모리 그룹핑
- 뷰에서 반복 쿼리 금지

---

## 7. 프론트엔드 설계

### 7.1 `menu_crud_controller.js`
- 모달 열기/닫기
- create/update/delete 요청
- 에러 메시지 표출
- 저장 후 그리드 `refresh()`

### 7.2 `ag_grid_controller.js`
- `components`에 아래 렌더러 등록:
  - `treeMenuCellRenderer`
  - `actionCellRenderer`

### 7.3 AG Grid Helper
- `ALLOWED_COLUMN_KEYS`에 `cellRenderer` 추가

### 7.4 스타일
- `app/assets/stylesheets/menu_modal.css`
- `.tree-menu-folder` 실제 렌더링과 연결

---

## 8. 사이드바 연동

### 8.1 렌더링 전략
사이드바는 `AdmMenu.active`를 한 번에 조회한 뒤 메모리에서 트리를 구성해 렌더링한다.

- 금지: 뷰 내부 `where` 반복 호출
- 목표: N+1 없이 일정 쿼리 수 유지

### 8.2 TabRegistry 연동
MVP에서는 `TabRegistry`를 유지한다.

- `tab_id`가 등록된 메뉴만 탭 오픈
- 미등록 `tab_id` 또는 빈값 메뉴는 URL 이동
- 추후 Phase에서 TabRegistry DB 연동 검토

---

## 9. 파일 구조

### 9.1 신규 생성 파일

```text
db/migrate/XXXXXXXX_create_adm_menus.rb
app/models/adm_menu.rb
app/controllers/system/menus_controller.rb
app/views/system/menus/index.html.erb
app/views/system/menus/_form_modal.html.erb
app/javascript/controllers/menu_crud_controller.js
app/assets/stylesheets/menu_modal.css
db/seeds/adm_menus.rb
```

### 9.2 수정 파일

```text
config/routes.rb
app/views/shared/_sidebar.html.erb
app/javascript/controllers/ag_grid_controller.js
app/helpers/ag_grid_helper.rb
app/models/tab_registry.rb
```

---

## 10. 구현 순서

### Phase 1. 백엔드
1. 마이그레이션/시드 작성
2. `AdmMenu` 모델 + 무결성 검증 구현
3. `System::MenusController` CRUD 구현 (`require_authentication` 포함)
4. 라우팅 연결

### Phase 2. 프론트엔드
1. `index.html.erb` (검색 + 그리드 + 버튼)
2. `_form_modal.html.erb`
3. `menu_crud_controller.js`
4. `ag_grid_controller.js` 렌더러 등록
5. `ag_grid_helper.rb` `cellRenderer` 허용
6. `menu_modal.css` 적용

### Phase 3. 사이드바/탭
1. `_sidebar.html.erb` DB 렌더링 전환 (반복 쿼리 제거)
2. `tab_id` 정책 반영

### Phase 4. 안정화
1. 캐시 적용 (`Rails.cache`)
2. 검색 성능 보완(접두검색/색인 전략)
3. 테스트 보강

---

## 11. 테스트 요구사항

### 11.1 모델 테스트
- 부모 존재/레벨 일치/순환 참조 금지
- `MENU` URL 필수
- 자식 있는 메뉴 삭제 불가

### 11.2 요청 테스트
- CRUD 정상/실패 케이스
- 인증 없는 접근 차단
- 검색 파라미터 필터링

### 11.3 시스템 테스트
- 모달 CRUD 플로우
- 그리드 액션 버튼 동작
- 사이드바 렌더링/탭 또는 URL 이동 동작

---

## 12. 보안/성능/확장성

### 12.1 보안
- Strong Parameters
- CSRF 기본 검증
- 인증 필수

### 12.2 성능
- 사이드바 단일 조회 + 메모리 트리 구성
- 캐시 적용 가능 구조
- 검색은 현재 규모 허용, 증가 시 전략 전환

### 12.3 확장성
- 현재 최대 3레벨
- 향후 Role 기반 메뉴(`adm_menu_roles`) 확장 가능
- TabRegistry DB 통합은 후속 과제로 분리
