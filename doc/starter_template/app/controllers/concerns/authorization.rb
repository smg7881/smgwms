# Authorization - 역할 기반 접근 제어 Concern
#
# ApplicationController에 include하면 모든 컨트롤러에 권한 제어 기능이 적용된다.
# - 계정이 활성 상태인지, 사용자가 유효한지 자동으로 확인한다
# - 개별 컨트롤러에서 ensure_admin 등의 헬퍼로 역할을 제한한다
#
# 멀티테넌시를 사용하지 않는 경우:
#   before_action :ensure_can_access_account 라인과 관련 메서드를 제거한다
#
# 참고: Fizzy의 app/controllers/concerns/authorization.rb
module Authorization
  extend ActiveSupport::Concern

  included do
    # 인증된 계정 접근 시 계정/사용자 상태를 자동으로 확인한다.
    # authenticated_account_access? 조건이 false이면 (미인증 또는 계정 없음) 건너뛴다.
    before_action :ensure_can_access_account, if: :authenticated_account_access?
  end

  class_methods do
    # 특정 액션에서 계정 접근 확인을 건너뛴다.
    # 공개 페이지나 웹훅 엔드포인트 등에서 사용한다.
    #
    # 예시: allow_unauthorized_access only: [:show]
    def allow_unauthorized_access(**options)
      skip_before_action :ensure_can_access_account, **options
    end

    # 사용자 없이 계정에 접근할 수 있도록 허용한다.
    # 이미 로그인된 사용자는 루트로 리다이렉트한다.
    # 초대 링크, 회원가입 완료 등의 페이지에서 사용한다.
    def require_access_without_a_user(**options)
      skip_before_action :ensure_can_access_account, **options
      before_action :redirect_existing_user, **options
    end
  end

  private
    # 관리자 권한이 있는지 확인한다.
    # 없으면 403 Forbidden을 반환한다.
    # 관리자 전용 컨트롤러의 before_action에서 사용한다.
    def ensure_admin
      head :forbidden unless Current.user.admin?
    end

    # 인증된 계정 접근인지 확인하는 조건 메서드.
    # account가 있고 인증된 상태일 때만 true를 반환한다.
    def authenticated_account_access?
      Current.account.present? && authenticated?
    end

    # 계정과 사용자가 모두 활성 상태인지 확인한다.
    # 비활성 계정이나 정지된 사용자는 로그인 페이지로 리다이렉트한다.
    # JSON 요청에는 403 Forbidden을 반환한다.
    #
    # TODO: 자신의 계정/사용자 상태 필드에 맞게 조건을 수정한다
    def ensure_can_access_account
      unless Current.account.active? && Current.user&.active?
        respond_to do |format|
          format.html { redirect_to new_session_path }
          format.json { head :forbidden }
        end
      end
    end

    # 이미 로그인된 사용자를 루트로 리다이렉트한다.
    # require_access_without_a_user와 함께 사용된다.
    def redirect_existing_user
      redirect_to root_path if Current.user
    end
end
