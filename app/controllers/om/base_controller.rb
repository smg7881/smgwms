class Om::BaseController < ApplicationController
  around_action :use_korean_locale
  before_action :require_menu_permission!

  private
    def menu_code_for_permission
      raise NotImplementedError, "Subclasses must implement menu_code_for_permission"
    end

    def require_menu_permission!
      if admin?
        return
      end

      if Current.user.blank?
        head :forbidden
        return
      end

      if !defined?(AdmUserMenuPermission) || !AdmUserMenuPermission.table_exists?
        head :forbidden
        return
      end

      if AdmUserMenuPermission.active.exists?(user_id: Current.user.id, menu_cd: menu_code_for_permission)
        return
      end

      respond_to do |format|
        format.html { redirect_to root_path, alert: "메뉴 접근 권한이 없습니다." }
        format.any { head :forbidden }
      end
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      head :forbidden
    end

    def use_korean_locale(&block)
      I18n.with_locale(:ko, &block)
    end
end
