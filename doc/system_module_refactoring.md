# 시스템 관리 모듈 리팩토링

## 목적

시스템 관리 모듈(dept, menus, users)의 불필요한 래퍼 컴포넌트와 모듈 간 중복 코드를 제거하여 유지보수성을 개선한다.

---

## 변경 내역

### 1. `System::BasePageComponent` 생성

3개 PageComponent에서 동일했던 `initialize`, `create_url`, `update_url`, `delete_url`, `grid_url`을 추상 베이스 클래스로 추출했다.

**새 파일:** `app/components/system/base_page_component.rb`

서브클래스는 `collection_path`와 `member_path`만 구현하면 된다.

```ruby
class System::Dept::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_dept_index_path(**)
    def member_path(id, **) = helpers.system_dept_path(id, **)
end
```

### 2. FormModalComponent를 PageComponent에 통합

각 모듈의 `FormModalComponent`는 `form_fields` 배열만 보유하고 있었다. 이를 `PageComponent`의 private 메서드로 이동하고, 모달 렌더링은 `page_component.html.erb`에 인라인으로 통합했다.

### 3. Ui:: 래퍼 컴포넌트 제거

`Ui::AgGridComponent`, `Ui::SearchFormComponent`, `Ui::ResourceFormComponent`는 헬퍼 메서드를 그대로 위임만 하는 래퍼였다. 템플릿에서 `helpers.*_tag`를 직접 호출하도록 변경하고 래퍼를 삭제했다.

```erb
<%# Before %>
<%= render Ui::SearchFormComponent.new(url: create_url, fields: search_fields, ...) %>
<%= render Ui::AgGridComponent.new(columns: columns, url: grid_url, ...) %>

<%# After %>
<%= helpers.search_form_tag(url: create_url, fields: search_fields, ...) %>
<%= helpers.ag_grid_tag(columns: columns, url: grid_url, ...) %>
```

### 4. BaseCrudController에 공통 메서드 추출

3개 서브 컨트롤러에서 동일했던 `handleDelete`, `save`, `submit`을 `BaseCrudController`로 추출했다. 서브클래스는 static 프로퍼티로 차이점만 선언한다.

```javascript
// 서브클래스 설정 예시
static resourceName = "dept"        // JSON body 키
static deleteConfirmKey = "deptNm"  // 삭제 확인 표시명 키
static entityLabel = "부서"          // 삭제 확인 메시지 라벨
```

`user_crud_controller`는 multipart 전송이 필요하므로 `save()`만 오버라이드한다.

템플릿의 action 문자열도 통일했다: `submitDept` / `submitMenu` / `submitUser` -> `submit`

---

## 파일 변경 목록

### 생성 (1개)

| 파일 | 설명 |
|------|------|
| `app/components/system/base_page_component.rb` | 공통 베이스 클래스 |

### 수정 (10개)

| 파일 | 변경 내용 |
|------|-----------|
| `app/components/system/dept/page_component.rb` | BasePageComponent 상속, `form_fields` 추가 |
| `app/components/system/dept/page_component.html.erb` | helpers 직접 호출, 모달 인라인 |
| `app/components/system/menus/page_component.rb` | BasePageComponent 상속, `form_fields` 추가 |
| `app/components/system/menus/page_component.html.erb` | helpers 직접 호출, 모달 인라인 |
| `app/components/system/users/page_component.rb` | BasePageComponent 상속, `form_fields` 추가 |
| `app/components/system/users/page_component.html.erb` | helpers 직접 호출, 모달 인라인 |
| `app/javascript/controllers/base_crud_controller.js` | `handleDelete`, `save`, `submit` 추가 |
| `app/javascript/controllers/dept_crud_controller.js` | 중복 메서드 제거, static config 추가 |
| `app/javascript/controllers/menu_crud_controller.js` | 중복 메서드 제거, static config 추가 |
| `app/javascript/controllers/user_crud_controller.js` | 중복 메서드 제거, `save()` 오버라이드 유지 |

### 삭제 (9개)

| 파일 | 사유 |
|------|------|
| `app/components/system/dept/form_modal_component.rb` | PageComponent에 통합 |
| `app/components/system/dept/form_modal_component.html.erb` | PageComponent에 통합 |
| `app/components/system/menus/form_modal_component.rb` | PageComponent에 통합 |
| `app/components/system/menus/form_modal_component.html.erb` | PageComponent에 통합 |
| `app/components/system/users/form_modal_component.rb` | PageComponent에 통합 |
| `app/components/system/users/form_modal_component.html.erb` | PageComponent에 통합 |
| `app/components/ui/ag_grid_component.rb` | 헬퍼 직접 호출로 대체 |
| `app/components/ui/search_form_component.rb` | 헬퍼 직접 호출로 대체 |
| `app/components/ui/resource_form_component.rb` | 헬퍼 직접 호출로 대체 |

---

## 결과

| 항목 | Before | After |
|------|--------|-------|
| 모듈당 파일 수 | 7 | 4 |
| 공유 인프라 파일 | 10 | 7 |
| 서브 컨트롤러(JS) 평균 줄 수 | ~148줄 | ~80줄 |

검증: 전체 테스트 61건 통과, RuboCop 변경 파일 전건 통과
