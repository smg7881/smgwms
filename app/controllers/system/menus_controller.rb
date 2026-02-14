class System::MenusController < ApplicationController
  def index
    @menus = if search_params.values.any?(&:present?)
      scope = AdmMenu.ordered
      scope = scope.where("menu_cd LIKE ?", "%#{search_params[:menu_cd]}%") if search_params[:menu_cd].present?
      scope = scope.where("menu_nm LIKE ?", "%#{search_params[:menu_nm]}%") if search_params[:menu_nm].present?
      scope = scope.where(use_yn: search_params[:use_yn]) if search_params[:use_yn].present?
      scope.to_a
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
      render json: { success: true, message: "추가되었습니다.", menu: menu }
    else
      render json: { success: false, errors: menu.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    menu = AdmMenu.find(params[:id])

    if menu.update(menu_params)
      render json: { success: true, message: "수정되었습니다.", menu: menu }
    else
      render json: { success: false, errors: menu.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    menu = AdmMenu.find(params[:id])
    if menu.children.exists?
      render json: { success: false, errors: [ "하위 메뉴가 존재하여 삭제할 수 없습니다." ] }, status: :unprocessable_entity
    else
      menu.destroy
      render json: { success: true, message: "삭제되었습니다." }
    end
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:menu_cd, :menu_nm, :use_yn)
    end

    def menu_params
      params.require(:menu).permit(
        :menu_cd, :menu_nm, :parent_cd, :menu_url, :menu_icon,
        :sort_order, :menu_level, :menu_type, :use_yn, :tab_id
      )
    end
end
