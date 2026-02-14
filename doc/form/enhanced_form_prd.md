# EnhancedForm PRD

## 개요

Rails 8.1 / Hotwire 기반의 선언적 CRUD 폼 시스템. 필드 정의 배열만으로 `form_with model:` 기반 데이터 입력/수정 폼을 자동 생성합니다.

## 목표

- 필드 정의 배열만으로 CRUD 폼을 선언적으로 생성
- 기존 `SearchFormHelper` 패턴과 일관된 구조
- `form_with model:` 기반 (POST/PATCH 자동 추론)
- 24컬럼 반응형 그리드 레이아웃 (`sf-grid` CSS 재사용)

## 지원 필드 타입 (8종)

| 타입 | 설명 | HTML 요소 |
|------|------|-----------|
| `input` | 텍스트 입력 | `f.text_field` |
| `number` | 숫자 입력 (min/max/step) | `f.number_field` |
| `select` | 드롭다운 선택 | `<select>` |
| `date_picker` | 날짜/날짜시간 입력 | `f.date_field` / `f.datetime_local_field` |
| `textarea` | 여러 줄 텍스트 | `f.text_area` |
| `checkbox` | 체크박스 | `f.check_box` |
| `radio` | 라디오 그룹 | `f.radio_button` x N |
| `switch` | 토글 스위치 | `f.check_box` + CSS |

## API

```ruby
enhanced_form_tag(
  model: @post,
  fields: [
    { field: "title", type: "input", label: "제목", required: true, span: "24" },
    { field: "content", type: "textarea", label: "내용", span: "24" }
  ],
  url: post_path(@post),          # 선택 (모델에서 추론)
  cols: 3,                         # 기본: 3
  show_buttons: true,              # 기본: true
  submit_label: "저장",             # 제출 버튼 텍스트
  cancel_url: posts_path           # 취소 시 이동 URL
)
```

## 필드 정의 형식

```ruby
{
  field: "title",              # 필수: 모델 속성명
  type: "input",               # 필수: 필드 타입
  label: "제목",               # 선택: 라벨 (없으면 humanize)
  label_key: "post.title",     # 선택: I18n 키
  placeholder: "제목 입력...",  # 선택: placeholder
  required: true,              # 선택: 필수 여부
  disabled: false,             # 선택: 비활성화
  span: "24 s:12 m:8",         # 선택: 그리드 span
  help: "도움말 텍스트",        # 선택: 도움말
  options: [...],              # select/radio용 옵션
  depends_on: "parent_field",  # select 의존성: 부모 필드명
  depends_filter: "filter_key" # select 의존성: 필터 키
}
```

## 핵심 기능

### 1. 24컬럼 반응형 그리드
기존 `sf-grid`, `sf-field`, `sf-span-*` CSS 클래스 재사용.

### 2. 클라이언트 사이드 유효성 검사
HTML5 `required`, `pattern`, `min`, `max` 속성 + Stimulus `blur` 이벤트에서 `checkValidity()`.

### 3. 서버 사이드 유효성 검사
Rails `model.errors` 기반 에러 메시지 표시. 필드별 인라인 에러 + 상단 에러 요약.

### 4. 필드 간 의존성
부모 select 변경 시 자식 select 옵션 필터링. `data-all-options` JSON으로 전체 옵션 저장, Stimulus에서 동적 필터링.

### 5. Submit/Reset/Cancel 버튼
제출 시 로딩 스피너, 초기화 시 폼 리셋 + 에러 클리어, 취소 시 URL 이동.

### 6. I18n 지원
`label_key`, `placeholder_key`로 I18n 번역 키 지원.

## 파일 구조

```
app/helpers/enhanced_form_helper.rb
app/views/shared/enhanced_form/_form.html.erb
app/views/shared/enhanced_form/_buttons.html.erb
app/views/shared/enhanced_form/fields/_input.html.erb
app/views/shared/enhanced_form/fields/_number.html.erb
app/views/shared/enhanced_form/fields/_select.html.erb
app/views/shared/enhanced_form/fields/_date_picker.html.erb
app/views/shared/enhanced_form/fields/_textarea.html.erb
app/views/shared/enhanced_form/fields/_checkbox.html.erb
app/views/shared/enhanced_form/fields/_radio.html.erb
app/views/shared/enhanced_form/fields/_switch.html.erb
app/javascript/controllers/enhanced_form_controller.js
app/assets/stylesheets/enhanced_form.css
test/helpers/enhanced_form_helper_test.rb
```

## 사용 예시

```erb
<%= enhanced_form_tag(
  model: @post,
  fields: [
    { field: "title", type: "input", label: "제목", required: true, span: "24 s:12 m:8" },
    { field: "category", type: "select", label: "카테고리",
      options: [{ label: "기술", value: "tech" }, { label: "일반", value: "general" }] },
    { field: "published", type: "switch", label: "공개 여부" },
    { field: "content", type: "textarea", label: "내용", span: "24", rows: 10 }
  ],
  submit_label: "저장",
  cancel_url: posts_path
) %>
```
