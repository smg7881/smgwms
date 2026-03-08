class System::DeptController < System::BaseController
  include System::ExcelTransferable

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
    dept = find_dept
    render json: dept_json(dept)
  end

  def create
    dept = AdmDept.new(dept_params)
    if dept.dept_order.blank?
      dept.dept_order = AdmDept.next_child_order(dept.parent_dept_code)
    end

    if dept.save
      render_success(message: "추가되었습니다.", payload: { dept: dept_json(dept) })
    else
      render_failure(errors: dept.errors.full_messages)
    end
  end

  def update
    dept = find_dept
    attrs = dept_params.to_h
    attrs.delete("dept_code")

    if dept.update(attrs)
      render_success(message: "수정되었습니다.", payload: { dept: dept_json(dept) })
    else
      render_failure(errors: dept.errors.full_messages)
    end
  end

  def destroy
    dept = find_dept
    if dept.children.exists?
      render_failure(errors: [ "하위 부서가 존재하여 삭제할 수 없습니다." ])
      return
    end

    if dept.destroy
      render_success(message: "삭제되었습니다.")
    else
      render_failure(errors: dept.errors.full_messages.presence || [ "삭제에 실패했습니다." ])
    end
  end

  private
    def excel_resource_key
      :dept
    end

    def search_params
      params.fetch(:q, {}).permit(:dept_code, :dept_nm, :use_yn)
    end

    def search_present?
      search_params.values.any?(&:present?)
    end

    def filtered_scope
      AdmDept.search_tree_with_ancestors(search_params)
    end

    def dept_params
      params.require(:adm_dept).permit(
        :dept_code, :dept_nm, :dept_type, :parent_dept_code,
        :description, :dept_order, :use_yn
      )
    end

    def find_dept
      AdmDept.find_by!(dept_code: normalized_code_param(:id))
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
