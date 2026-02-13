# 에러 리포트에 사용자 및 계정 컨텍스트를 자동으로 추가한다.
#
# Rails.error 미들웨어를 활용해, 에러가 실제로 발생할 때만 컨텍스트를 평가한다.
# (지연 평가이므로 에러가 없을 때 불필요한 Current 접근이 발생하지 않는다)
#
# 연동 가능한 에러 추적 도구:
#   - Sentry (sentry-rails gem)
#   - Honeybadger
#   - Bugsnag
#   - 기타 Rails.error.subscribe를 지원하는 모든 도구
#
# TODO: user_id, account_id를 자신의 Current 속성에 맞게 변경한다
#   예: identity_id: Current.identity&.id (Fizzy 방식)
#       organization_id: Current.account&.id
#
# 참고: Fizzy의 config/initializers/error_context.rb
Rails.error.add_middleware ->(error, context:, **) do
  context.merge \
    user_id: Current.user&.id,       # 현재 로그인한 사용자 ID
    account_id: Current.account&.id  # 현재 테넌트(계정) ID
end
