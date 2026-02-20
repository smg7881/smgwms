class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :ensure_tab_session, if: :authenticated?
  helper_method :admin?

  private
    def admin?
      Current.user&.role_cd == "ADMIN"
    end

    def require_admin!
      if admin?
        true
      else
        respond_to do |format|
          format.html { redirect_to root_path, alert: "관리자 권한이 필요합니다." }
          format.any { head :forbidden }
        end
      end
    end

    def ensure_tab_session
      session[:open_tabs] ||= []

      unless session[:open_tabs].any? { |t| t["id"] == "overview" }
        session[:open_tabs].unshift({ "id" => "overview", "label" => "대시보드", "url" => "/" })
      end

      session[:active_tab] ||= "overview"
    end
end
