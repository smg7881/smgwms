class System::UsersController < ApplicationController
  def index
    @users = if search_params.values.any?(&:present?)
      scope = User.ordered
      scope = scope.where("user_nm LIKE ?", "%#{search_params[:user_nm]}%") if search_params[:user_nm].present?
      scope = scope.where("dept_nm LIKE ?", "%#{search_params[:dept_nm]}%") if search_params[:dept_nm].present?
      scope = scope.where(work_status: search_params[:work_status]) if search_params[:work_status].present?
      scope
    else
      User.ordered
    end

    respond_to do |format|
      format.html
      format.json { render json: @users.map { |u| user_json(u) } }
    end
  end

  def show
    user = User.find(params[:id])
    render json: user_json(user)
  end

  def create
    user = User.new(user_params)
    user.password = SecureRandom.hex(8) unless user_params[:password].present?

    if user.save
      render json: { success: true, message: "추가되었습니다.", user: user_json(user) }
    else
      render json: { success: false, errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    user = User.find(params[:id])

    update_attrs = user_params.to_h
    update_attrs.delete("password") if update_attrs["password"].blank?

    if user.update(update_attrs)
      render json: { success: true, message: "수정되었습니다.", user: user_json(user) }
    else
      render json: { success: false, errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    render json: { success: true, message: "삭제되었습니다." }
  end

  def check_id
    exists = User.where(user_id_code: params[:code]).exists?
    render json: { exists: exists }
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:user_nm, :dept_nm, :work_status)
    end

    def user_params
      params.require(:user).permit(
        :user_id_code, :user_nm, :email_address, :password,
        :dept_cd, :dept_nm, :role_cd, :position_cd, :job_title_cd,
        :work_status, :hire_date, :resign_date,
        :phone, :address, :detail_address, :photo
      )
    end

    def user_json(user)
      json = user.as_json
      if user.photo.attached?
        json["photo_url"] = Rails.application.routes.url_helpers.rails_blob_path(user.photo, only_path: true)
      end
      json
    end
end
