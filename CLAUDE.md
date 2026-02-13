# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Ruby 4.0.1 / Rails 8.1 기반의 웹 애플리케이션입니다. SQLite3를 데이터베이스로 사용하며, `Post` 모델(title, content 필드)이 구현되어 있습니다. 프론트엔드는 Propshaft(에셋 파이프라인) + Importmap + Hotwire(Turbo/Stimulus) 스택을 사용합니다.

## 주요 명령어

```bash
# 개발 서버 실행
bin/rails server

# 데이터베이스 마이그레이션
bin/rails db:migrate

# 테스트 실행 (전체)
bin/rails db:test:prepare test

# 단일 테스트 파일 실행
bin/rails test test/models/post_test.rb

# 시스템 테스트
bin/rails db:test:prepare test:system

# 린트 (RuboCop - Rails Omakase 스타일)
bin/rubocop

# 보안 취약점 스캔
bin/brakeman --no-pager       # Ruby/Rails 정적 분석
bin/bundler-audit              # 젬 보안 취약점
bin/importmap audit            # JavaScript 의존성 취약점

# Rails 콘솔
bin/rails console
```

## 아키텍처

### 라우팅 및 컨트롤러

- 루트(`/`) → `DashboardController#show` (Post 통계 표시)
- `/posts` → `PostsController` (전체 CRUD)
- `/reports` → `ReportsController#index`
- `/tabs` → `TabsController` + `Tabs::ActivationsController` (탭 네비게이션 관리)
- `/up` → Rails 헬스 체크 엔드포인트

### 탭 시스템

`TabRegistry` (plain Ruby 클래스, `app/models/tab_registry.rb`)는 사이드바 탭 목록을 정의합니다. `Data.define`으로 불변 Entry 구조체를 사용합니다. 탭 CRUD는 `TabsController`, 탭 활성화는 `Tabs::ActivationsController`가 담당하며, 라우팅은 `scope module: :tabs`로 네임스페이스를 적용합니다.

### 데이터베이스

- 환경별로 별도 SQLite 파일 사용 (`storage/` 디렉토리)
- 프로덕션은 캐시·큐·케이블용 DB를 각각 분리 운영
  - `solid_cache`, `solid_queue`, `solid_cable` 젬 사용

### 배포

- Docker 컨테이너 배포는 Kamal(`config/deploy.yml`) 사용
- Puma 웹 서버 + Thruster(HTTP 캐싱/압축)

### CI (GitHub Actions)

PR 및 `master` 브랜치 푸시 시 다음 4개 잡이 실행됩니다:
1. `scan_ruby` - Brakeman + bundler-audit
2. `scan_js` - importmap audit
3. `lint` - RuboCop
4. `test` + `system-test` - 유닛/시스템 테스트

## 코딩 스타일 핵심 규칙

전체 규칙은 `STYLE.md`와 `STYLE_GUIDE.md`에 있습니다. 아래는 가장 자주 적용되는 규칙입니다.

### 조건문: guard clause보다 expanded conditional 선호

```ruby
# Bad
def todos_for_new_group
  return [] unless ids
  find(ids)
end

# Good
def todos_for_new_group
  if ids
    find(ids)
  else
    []
  end
end
```

예외: 메서드 상단에서 짧은 early return은 허용됩니다.

### visibility modifier 들여쓰기

`private` 다음에 빈 줄 없이 내용을 들여씁니다:

```ruby
class Foo
  def bar; end

  private
    def baz; end
end
```

### CRUD 컨트롤러 — 커스텀 액션 대신 새 리소스

```ruby
# Bad
resources :cards do
  post :close
end

# Good
resources :cards do
  scope module: :cards do
    resource :closure
  end
end
```

### 얇은 컨트롤러 + 풍부한 도메인 모델

서비스 객체를 만들지 않습니다. 복잡한 로직은 모델 메서드로 표현합니다.

### 백그라운드 잡 명명

비동기 트리거는 `_later`, 동기 메서드는 `_now` 접미사를 사용합니다.

## 개발 템플릿 참조 (필수)

새 기능 구현이나 구조 설계 시 `doc/starter_template/README.md`의 패턴과 컨벤션을 따릅니다.
