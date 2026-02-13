# Authentication - 세션 기반 인증 Concern
#
# ApplicationController에 include하면 모든 컨트롤러에 인증 기능이 적용된다.
# - HTTP-only 서명 쿠키로 세션을 관리한다 (XSS 토큰 탈취 방지)
# - 인증이 필요 없는 액션은 allow_unauthenticated_access로 건너뛴다
# - 멀티테넌시를 사용하지 않는다면 require_account 관련 코드를 제거한다
#
# 참고: Fizzy의 app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    # 계정(테넌트) 확인을 먼저 실행해야 한다 — user 조회가 account에 의존하기 때문
    before_action :require_account
    # 인증되지 않은 요청은 로그인 페이지로 리다이렉트
    before_action :require_authentication
    # 뷰에서 authenticated? 헬퍼를 사용할 수 있도록 노출
    helper_method :authenticated?

    # 인증된 사용자 기반으로 HTTP ETag를 설정 (캐시 무효화)
    etag { Current.identity.id if authenticated? }
  end

  class_methods do
    # 인증되지 않은 접근을 허용하면서, 이미 로그인된 사용자는 홈으로 리다이렉트
    # 주로 로그인/회원가입 페이지에 사용한다
    #
    # 예시: allow_unauthenticated_access only: [:new, :create]
    def require_unauthenticated_access(**options)
      allow_unauthenticated_access **options
      before_action :redirect_authenticated_user, **options
    end

    # 인증 없이 접근 가능하게 설정한다.
    # 세션이 있다면 복원하지만, 없어도 요청을 차단하지 않는다.
    #
    # 예시: allow_unauthenticated_access only: [:show]
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :resume_session, **options
      allow_unauthorized_access **options
    end
  end

  private
    # 현재 요청이 인증되어 있는지 확인한다.
    # identity가 설정되어 있으면 인증된 상태다.
    def authenticated?
      Current.identity.present?
    end

    # 계정(테넌트)이 설정되어 있는지 확인한다.
    # 멀티테넌시를 사용하지 않는 경우 이 메서드를 제거하거나 비워둔다.
    def require_account
      unless Current.account.present?
        redirect_to root_path
      end
    end

    # 인증 확인 순서:
    # 1. 쿠키로 세션 복원 시도
    # 2. Bearer 토큰으로 인증 시도 (API용, 필요 없으면 제거)
    # 3. 모두 실패하면 로그인 페이지로 리다이렉트
    def require_authentication
      resume_session || request_authentication
    end

    # 서명된 쿠키에서 세션을 찾아 Current에 설정한다.
    # 세션이 유효하면 Current.session → Current.identity → Current.user가 연쇄 설정된다.
    def resume_session
      if session = find_session_by_cookie
        set_current_session session
      end
    end

    # 쿠키에 저장된 서명 토큰으로 Session 레코드를 조회한다.
    # TODO: 자신의 Session 모델 조회 방식으로 교체한다
    # 예시: Session.find_signed(cookies.signed[:session_token])
    def find_session_by_cookie
      # TODO: Replace with your Session model lookup
      # Session.find_signed(cookies.signed[:session_token])
    end

    # 인증이 필요한 페이지에 미인증 사용자가 접근했을 때 호출된다.
    # 로그인 후 원래 요청 URL로 돌아올 수 있도록 session에 저장해둔다.
    def request_authentication
      if Current.account.present?
        session[:return_to_after_authenticating] = request.url
      end

      redirect_to_login_url
    end

    # 인증 성공 후 이동할 URL을 반환한다.
    # 로그인 전에 접근하려던 URL이 있으면 그곳으로, 없으면 루트로 이동한다.
    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    # 이미 로그인된 사용자를 루트 페이지로 리다이렉트한다.
    # 로그인 페이지 등 미인증 전용 페이지에서 사용한다.
    def redirect_authenticated_user
      redirect_to root_url if authenticated?
    end

    # 새 세션을 생성하고 쿠키에 저장한다.
    # 매직 링크 또는 비밀번호 인증 성공 후 호출한다.
    def start_new_session_for(identity)
      identity.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      ).tap do |session|
        set_current_session session
      end
    end

    # 세션을 Current에 저장하고, HTTP-only 영구 서명 쿠키에 기록한다.
    # - httponly: true  → JavaScript에서 쿠키 접근 불가 (XSS 방어)
    # - same_site: :lax → CSRF 공격 완화
    def set_current_session(session)
      Current.session = session
      cookies.signed.permanent[:session_token] = {
        value: session.signed_id,
        httponly: true,
        same_site: :lax
      }
    end

    # 현재 세션을 DB에서 삭제하고 쿠키도 제거한다.
    # 로그아웃 시 호출한다.
    def terminate_session
      Current.session.destroy
      cookies.delete(:session_token)
    end

    # 로그인 페이지로 리다이렉트한다.
    # TODO: 자신의 로그인 경로로 교체한다 (예: new_session_path, login_path)
    def redirect_to_login_url
      redirect_to new_session_path
    end
end
