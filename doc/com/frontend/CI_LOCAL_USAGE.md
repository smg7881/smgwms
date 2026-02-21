# 로컬 CI 사용 가이드

## 1. 개요
이 문서는 GitHub Actions CI와 유사한 검사를 로컬에서 먼저 실행하는 방법을 설명합니다.

로컬 스크립트:
- `bin/ci-local`

실행 스크립트 본문:
- `script/ci_local.rb`

## 2. 어떤 검사를 하나요?
기본 실행(`ruby bin/ci-local`)은 아래 순서로 실행됩니다.

1. `Brakeman`
- 명령: `ruby bin/brakeman --no-pager`
- 내용: Rails 보안 취약점 정적 분석

2. `Bundler Audit`
- 명령: `ruby bin/bundler-audit`
- 내용: Gem 의존성 취약점 검사

3. `Importmap Audit`
- 명령: `ruby bin/importmap audit`
- 내용: JavaScript 의존성 취약점 검사

4. `RuboCop`
- 명령: `ruby bin/rubocop -f github`
- 내용: 코드 스타일/정적 규칙 검사

5. `Stimulus Action Lint`
- 명령: `ruby bin/lint-stimulus-actions`
- 내용: Stimulus `data-action` 배선 누락 검사

6. `Rails Test`
- 명령: `ruby bin/rails db:test:prepare test`
- 내용: 단위/통합 테스트 실행

7. `Rails System Test`
- 명령: `ruby bin/rails db:test:prepare test:system`
- 내용: 시스템 테스트 실행

## 3. 사용 방법
프로젝트 루트에서 실행합니다.

기본(전체 검사):
```bash
ruby bin/ci-local
```

빠른 검사(시스템 테스트 제외):
```bash
ruby bin/ci-local --fast
```

시스템 테스트만 제외:
```bash
ruby bin/ci-local --no-system
```

도움말:
```bash
ruby bin/ci-local --help
```

## 4. 언제 사용하면 좋나요?
- PR 올리기 전에 사전 점검할 때
- CI 실패를 로컬에서 빠르게 재현할 때
- Stimulus 배선 누락 같은 프론트 규약 오류를 조기에 잡을 때

## 5. 실패 시 대응
- 출력에서 `FAILED: <step name>`을 확인
- 해당 단계 로그를 먼저 수정
- 다시 `ruby bin/ci-local` 실행

## 6. CI와의 관계
- 이 스크립트는 GitHub Actions의 CI 흐름을 로컬에서 재현하기 위한 용도입니다.
- CI 설정 파일: `.github/workflows/ci.yml`
