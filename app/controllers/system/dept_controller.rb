class System::DeptController < System::BaseController
  def index
    respond_to do |format|
      format.html do
        @depts = search_present? ? filtered_scope : AdmDept.tree_ordered
      end
      format.json do
        depts = search_present? ? filtered_scope : AdmDept.tree_ordered
        render json: depts.map { |dept| dept_json(dept) }
      end
    end
  end

  def show
    dept = AdmDept.find(params[:id])
    render json: dept_json(dept)
  end

  def create
    dept = AdmDept.new(dept_params)
    if dept.dept_order.blank?
      dept.dept_order = AdmDept.next_child_order(dept.parent_dept_code)
    end

    if dept.save
      render json: { success: true, message: "추가되었습니다.", dept: dept_json(dept) }
    else
      render json: { success: false, errors: dept.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    dept = AdmDept.find(params[:id])
    attrs = dept_params.to_h
    attrs.delete("dept_code")

    if dept.update(attrs)
      render json: { success: true, message: "수정되었습니다.", dept: dept_json(dept) }
    else
      render json: { success: false, errors: dept.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    dept = AdmDept.find(params[:id])
    if dept.children.exists?
      render json: { success: false, errors: [ "하위 부서가 존재하여 삭제할 수 없습니다." ] }, status: :unprocessable_entity
      return
    end

    dept.destroy
    render json: { success: true, message: "삭제되었습니다." }
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:dept_code, :dept_nm, :use_yn)
    end

    def search_present?
      search_params.values.any?(&:present?)
    end

    def filtered_scope
      scope = AdmDept.ordered
      if search_params[:dept_code].present?
        scope = scope.where("dept_code LIKE ?", "%#{search_params[:dept_code]}%")
      end
      if search_params[:dept_nm].present?
        scope = scope.where("dept_nm LIKE ?", "%#{search_params[:dept_nm]}%")
      end
      if search_params[:use_yn].present?
        scope = scope.where(use_yn: search_params[:use_yn])
      end

      scope.map do |dept|
        dept.dept_level = dept.calculate_level
        dept
      end
    end

    def dept_params
      params.require(:dept).permit(
        :dept_code, :dept_nm, :dept_type, :parent_dept_code,
        :description, :dept_order, :use_yn
      )
    end

    def dept_json(dept)
      {
        id: dept.dept_code,
        dept_code: dept.dept_code,
        dept_nm: dept.dept_nm,
        dept_type: dept.dept_type,
        parent_dept_code: dept.parent_dept_code,
        description: dept.description,
        dept_order: dept.dept_order,
        use_yn: dept.use_yn,
        create_by: dept.create_by,
        create_time: dept.create_time,
        update_by: dept.update_by,
        update_time: dept.update_time,
        dept_level: dept.dept_level || dept.calculate_level
      }
    end
end
