class System::RoleUserController < System::BaseController
  def index
    @roles = AdmRole.where(use_yn: "Y").ordered
  end

  def available_users
    role = find_role_by_param
    users = if role.present?
      User.ordered.where(role_id: nil).or(User.ordered.where.not(role_id: role.id))
    else
      User.none
    end

    render json: users.map { |user| user_json(user) }
  end

  def assigned_users
    role = find_role_by_param
    users = if role.present?
      User.ordered.where(role_id: role.id)
    else
      User.none
    end

    render json: users.map { |user| user_json(user) }
  end

  def save_assignments
    role_cd = normalized_code(save_params[:role_cd])
    user_ids = Array(save_params[:user_ids]).map { |id| id.to_s.strip }.reject(&:blank?).uniq

    if role_cd.blank?
      render_failure(errors: [ "역할코드는 필수입니다." ])
      return
    end

    role = AdmRole.find_by(role_cd: role_cd)
    if role.nil?
      render_failure(errors: [ "역할코드를 찾을 수 없습니다." ])
      return
    end

    ActiveRecord::Base.transaction do
      User.where(role_id: role.id).where.not(user_id_code: user_ids).update_all(role_id: nil, updated_at: Time.current)
      User.where(user_id_code: user_ids).update_all(role_id: role.id, updated_at: Time.current)
    end

    render_success(message: "역할 사용자 저장이 완료되었습니다.")
  end

  private
    def save_params
      params.permit(:role_cd, user_ids: [])
    end

    def find_role_by_param
      role_cd = normalized_code(params[:role_cd])
      AdmRole.find_by(role_cd: role_cd)
    end

    def user_json(user)
      {
        id: user.id,
        user_id_code: user.user_id_code,
        user_nm: user.user_nm,
        dept_nm: user.dept_nm,
        position_cd: user.position_cd,
        job_title_cd: user.job_title_cd,
        role_cd: user.role_cd
      }
    end
end
