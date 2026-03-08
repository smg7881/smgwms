class System::MenusController < System::BaseController
  def index
    @menus = if search_params.values.any?(&:present?)
      AdmMenu.search_tree_with_ancestors(search_params)
    else
      AdmMenu.tree_ordered
    end

    respond_to do |format|
      format.html
      format.json { render json: @menus }
    end
  end

  def create
    menu = AdmMenu.new(menu_params)

    if menu.save
      render_success(message: "추가되었습니다.", payload: { menu: menu })
    else
      render_failure(errors: menu.errors.full_messages)
    end
  end

  def update
    menu = AdmMenu.find(params[:id])

    if menu.update(menu_params)
      render_success(message: "수정되었습니다.", payload: { menu: menu })
    else
      render_failure(errors: menu.errors.full_messages)
    end
  end

  def destroy
    menu = AdmMenu.find(params[:id])
    if menu.children.exists?
      render_failure(errors: [ "하위 메뉴가 존재하여 삭제할 수 없습니다." ])
      return
    end

    if menu.destroy
      render_success(message: "삭제되었습니다.")
    else
      render_failure(errors: menu.errors.full_messages.presence || [ "삭제에 실패했습니다." ])
    end
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:menu_cd, :menu_nm, :use_yn)
    end

    def menu_params
      params.require(:adm_menu).permit(
        :menu_cd, :menu_nm, :parent_cd, :menu_url, :menu_icon,
        :sort_order, :menu_level, :menu_type, :use_yn, :tab_id
      )
    end
end
