class System::RolesController < System::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: roles_scope.map { |role| role_json(role) } }
    end
  end

  def create
    role = AdmRole.new(role_params)
    if role.save
      render json: { success: true, message: "역할이 추가되었습니다.", role: role_json(role) }
    else
      render json: { success: false, errors: role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    role = find_role
    attrs = role_params.to_h
    attrs.delete("role_cd")

    if role.update(attrs)
      render json: { success: true, message: "역할이 수정되었습니다.", role: role_json(role) }
    else
      render json: { success: false, errors: role.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    role = find_role
    role.destroy
    render json: { success: true, message: "역할이 삭제되었습니다." }
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:role_cd].to_s.strip.blank? && attrs[:role_nm].to_s.strip.blank?
          next
        end

        role = AdmRole.new(attrs.permit(:role_cd, :role_nm, :description, :use_yn))
        if role.save
          result[:inserted] += 1
        else
          errors.concat(role.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        role_cd = attrs[:role_cd].to_s
        role = AdmRole.find_by(role_cd: role_cd)
        if role.nil?
          errors << "역할코드를 찾을 수 없습니다: #{role_cd}"
          next
        end

        update_attrs = attrs.permit(:role_nm, :description, :use_yn)
        if role.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(role.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |role_cd|
        role = AdmRole.find_by(role_cd: role_cd.to_s)
        next if role.nil?

        if role.destroy
          result[:deleted] += 1
        else
          errors.concat(role.errors.full_messages.presence || [ "역할 삭제에 실패했습니다: #{role_cd}" ])
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "역할 저장이 완료되었습니다.", data: result }
    end
  end

  private
    def find_role
      AdmRole.find_by!(role_cd: params[:id])
    end

    def search_params
      params.fetch(:q, {}).permit(:role_cd, :role_nm, :use_yn)
    end

    def roles_scope
      scope = AdmRole.ordered

      if search_params[:role_cd].present?
        scope = scope.where("role_cd LIKE ?", "%#{search_params[:role_cd]}%")
      end
      if search_params[:role_nm].present?
        scope = scope.where("role_nm LIKE ?", "%#{search_params[:role_nm]}%")
      end
      if search_params[:use_yn].present?
        scope = scope.where(use_yn: search_params[:use_yn])
      end

      scope
    end

    def role_params
      params.require(:role).permit(:role_cd, :role_nm, :description, :use_yn)
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :role_cd, :role_nm, :description, :use_yn ],
        rowsToUpdate: [ :role_cd, :role_nm, :description, :use_yn ]
      )
    end

    def role_json(role)
      {
        id: role.role_cd,
        role_cd: role.role_cd,
        role_nm: role.role_nm,
        description: role.description,
        use_yn: role.use_yn,
        update_by: role.update_by,
        update_time: role.update_time,
        create_by: role.create_by,
        create_time: role.create_time
      }
    end
end
