# Current - 스레드 로컬 요청 컨텍스트
#
# ActiveSupport::CurrentAttributes를 상속해, 현재 요청(또는 잡)의 컨텍스트를
# 스레드에 안전하게 저장한다. 컨트롤러, 모델, 잡 어디서나 Current.user처럼
# 직접 접근할 수 있다.
#
# 주의: 각 요청이 끝나면 모든 속성이 자동으로 리셋된다.
class Current < ActiveSupport::CurrentAttributes
  # 요청 전반에서 사용하는 핵심 속성
  # - session:  현재 Session 레코드 (로그인 세션)
  # - user:     현재 계정(account) 내 사용자 (User 레코드)
  # - identity: 이메일 기반 글로벌 사용자 (여러 계정에 걸쳐 동일한 Identity)
  # - account:  현재 테넌트 (멀티테넌시)
  attribute :session, :user, :identity, :account

  # HTTP 요청 메타데이터 (에러 추적, 로깅 등에 활용)
  attribute :http_method, :request_id, :user_agent, :ip_address, :referrer

  # session= 세터 오버라이드
  # session을 설정하면 자동으로 identity도 연쇄 설정된다.
  def session=(value)
    super(value)

    if value.present?
      self.identity = session.identity
    end
  end

  # identity= 세터 오버라이드
  # identity를 설정하면 현재 account 안에서 해당 사용자(User)를 찾아 자동으로 설정한다.
  # account가 먼저 설정되어 있어야 user를 올바르게 찾을 수 있다.
  def identity=(identity)
    super(identity)

    if identity.present?
      self.user = identity.users.find_by(account: account)
    end
  end

  # 특정 account 컨텍스트 안에서 블록을 실행한다.
  # 백그라운드 잡에서 account를 복원할 때 주로 사용된다.
  #
  # 예시:
  #   Current.with_account(account) { do_something }
  def with_account(value, &)
    with(account: value, &)
  end

  # account 없이 블록을 실행한다.
  # 계정 컨텍스트가 없는 글로벌 작업(예: 시스템 잡)에서 사용한다.
  def without_account(&)
    with(account: nil, &)
  end
end
