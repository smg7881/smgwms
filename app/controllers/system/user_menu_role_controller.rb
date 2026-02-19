class System::UserMenuRoleController < System::BaseController
  def index
  end

  def users
    render json: filtered_users_scope.map { |user| user_json(user) }
  end

  def roles_by_user
    user = User.find_by(user_id_code: params[:user_id_code].to_s.strip)

    roles = if user&.role_cd.present?
      AdmRole.where(role_cd: user.role_cd.to_s.strip.upcase).ordered
    else
      AdmRole.none
    end

    render json: roles.map { |role| role_json(role) }
  end

  def menus_by_user_role
    role_cd = params[:role_cd].to_s.strip.upcase
    role = AdmRole.find_by(role_cd: role_cd)

    if role.nil?
      render json: []
      return
    end

    menus = AdmMenu.active.ordered
    render json: menus.map { |menu| menu_json(menu) }
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:user_nm, :dept_nm)
    end

    def filtered_users_scope
      scope = User.ordered
      if search_params[:user_nm].present?
        scope = scope.where("user_nm LIKE ?", "%#{search_params[:user_nm]}%")
      end
      if search_params[:dept_nm].present?
        scope = scope.where("dept_nm LIKE ?", "%#{search_params[:dept_nm]}%")
      end
      scope
    end

    def user_json(user)
      {
        id: user.id,
        user_id_code: user.user_id_code,
        user_nm: user.user_nm,
        dept_nm: user.dept_nm,
        role_cd: user.role_cd
      }
    end

    def role_json(role)
      {
        role_cd: role.role_cd,
        role_nm: role.role_nm,
        description: role.description
      }
    end

    def menu_json(menu)
      {
        menu_cd: menu.menu_cd,
        menu_nm: menu.menu_nm,
        parent_cd: menu.parent_cd,
        menu_url: menu.menu_url,
        menu_type: menu.menu_type,
        menu_level: menu.menu_level,
        sort_order: menu.sort_order
      }
    end
end
