class Std::FavoritesController < Std::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: favorites_scope.map { |row| favorite_json(row) } }
    end
  end

  def groups
    user_code = search_user_id_code || current_user_id_code
    rows = StdUserFavoriteGroup.ordered.where(user_id_code: user_code).map do |row|
      {
        id: "#{row.user_id_code}_#{row.group_nm}",
        user_id_code: row.user_id_code,
        group_nm: row.group_nm,
        use_yn: row.use_yn,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
    render json: rows
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:menu_cd].to_s.strip.blank?
          next
        end

        row = StdUserFavorite.new(favorite_params_from_row(attrs))
        if row.user_id_code.blank?
          row.user_id_code = current_user_id_code
        end
        if row.menu_nm.blank?
          row.menu_nm = find_menu_name(row.menu_cd)
        end

        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        user_id_code = attrs[:user_id_code].to_s.strip.upcase
        menu_cd = attrs[:menu_cd].to_s.strip.upcase
        row = StdUserFavorite.find_by(user_id_code: user_id_code, menu_cd: menu_cd)
        if row.nil?
          errors << "즐겨찾기 정보를 찾을 수 없습니다: #{user_id_code}/#{menu_cd}"
          next
        end

        update_attrs = favorite_params_from_row(attrs)
        update_attrs.delete(:user_id_code)
        update_attrs.delete(:menu_cd)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |delete_key|
        if !delete_key.respond_to?(:to_h)
          next
        end

        key_hash = delete_key.to_h.symbolize_keys
        user_id_code = key_hash[:user_id_code].to_s.strip.upcase
        menu_cd = key_hash[:menu_cd].to_s.strip.upcase
        if user_id_code.blank? || menu_cd.blank?
          next
        end

        row = StdUserFavorite.find_by(user_id_code: user_id_code, menu_cd: menu_cd)
        if row.nil?
          next
        end

        if row.update(use_yn: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "즐겨찾기 비활성화에 실패했습니다: #{user_id_code}/#{menu_cd}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "즐겨찾기 정보가 저장되었습니다.", data: result }
    end
  end

  def batch_save_groups
    operations = group_batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:group_nm].to_s.strip.blank?
          next
        end

        row = StdUserFavoriteGroup.new(group_params_from_row(attrs))
        if row.user_id_code.blank?
          row.user_id_code = current_user_id_code
        end

        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        user_id_code = attrs[:user_id_code].to_s.strip.upcase
        group_nm = attrs[:group_nm].to_s.strip
        row = StdUserFavoriteGroup.find_by(user_id_code: user_id_code, group_nm: group_nm)
        if row.nil?
          errors << "즐겨찾기 그룹 정보를 찾을 수 없습니다: #{user_id_code}/#{group_nm}"
          next
        end

        update_attrs = group_params_from_row(attrs)
        update_attrs.delete(:user_id_code)
        update_attrs.delete(:group_nm)
        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |delete_key|
        if !delete_key.respond_to?(:to_h)
          next
        end

        key_hash = delete_key.to_h.symbolize_keys
        user_id_code = key_hash[:user_id_code].to_s.strip.upcase
        group_nm = key_hash[:group_nm].to_s.strip
        if user_id_code.blank? || group_nm.blank?
          next
        end

        row = StdUserFavoriteGroup.find_by(user_id_code: user_id_code, group_nm: group_nm)
        if row.nil?
          next
        end

        if row.update(use_yn: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "즐겨찾기 그룹 비활성화에 실패했습니다: #{user_id_code}/#{group_nm}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "즐겨찾기 그룹 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_FAVORITE"
    end

    def search_params
      params.fetch(:q, {}).permit(:user_id_code, :user_nm, :menu_nm, :user_favor_menu_grp, :use_yn)
    end

    def favorites_scope
      scope = StdUserFavorite.ordered
      target_user = search_user_id_code || current_user_id_code
      scope = scope.where(user_id_code: target_user)

      if search_menu_nm.present?
        scope = scope.where("menu_nm LIKE ?", "%#{search_menu_nm}%")
      end
      if search_group.present?
        scope = scope.where("user_favor_menu_grp LIKE ?", "%#{search_group}%")
      end
      if search_use_yn.present?
        scope = scope.where(use_yn: search_use_yn)
      end

      scope
    end

    def search_user_id_code
      search_params[:user_id_code].to_s.strip.upcase.presence
    end

    def search_menu_nm
      search_params[:menu_nm].to_s.strip.presence
    end

    def search_group
      search_params[:user_favor_menu_grp].to_s.strip.presence
    end

    def search_use_yn
      search_params[:use_yn].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [ :user_id_code, :menu_cd ],
        rowsToInsert: [ :user_id_code, :menu_cd, :menu_nm, :user_favor_menu_grp, :sort_seq, :use_yn ],
        rowsToUpdate: [ :user_id_code, :menu_cd, :menu_nm, :user_favor_menu_grp, :sort_seq, :use_yn ]
      )
    end

    def group_batch_save_params
      params.permit(
        rowsToDelete: [ :user_id_code, :group_nm ],
        rowsToInsert: [ :user_id_code, :group_nm, :use_yn ],
        rowsToUpdate: [ :user_id_code, :group_nm, :use_yn ]
      )
    end

    def favorite_params_from_row(row)
      row.permit(
        :user_id_code, :menu_cd, :menu_nm, :user_favor_menu_grp, :sort_seq, :use_yn
      ).to_h.symbolize_keys
    end

    def group_params_from_row(row)
      row.permit(
        :user_id_code, :group_nm, :use_yn
      ).to_h.symbolize_keys
    end

    def favorite_json(row)
      {
        id: "#{row.user_id_code}::#{row.menu_cd}",
        user_id_code: row.user_id_code,
        menu_cd: row.menu_cd,
        menu_nm: row.menu_nm,
        user_favor_menu_grp: row.user_favor_menu_grp,
        sort_seq: row.sort_seq,
        use_yn: row.use_yn,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end

    def find_menu_name(menu_cd)
      normalized = menu_cd.to_s.strip.upcase
      if normalized.blank?
        return nil
      end

      AdmMenu.find_by(menu_cd: normalized)&.menu_nm
    end

    def current_user_id_code
      if Current.user&.user_id_code.present?
        Current.user.user_id_code.to_s.strip.upcase
      else
        "SYSTEM"
      end
    end
end
