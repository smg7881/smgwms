class Wm::StockMovesController < Wm::BaseController
  STOCK_ATTR_COLUMNS = Wm::StockMove::STOCK_ATTR_COLUMNS.freeze
  MOVE_ROW_PERMITTED_FIELDS = [
    :corp_cd, :workpl_cd, :cust_cd, :item_cd, :stock_attr_no,
    :loc_cd, :to_loc_cd, :move_qty, :basis_unit_cls, :basis_unit_cd
  ].freeze

  def index
    respond_to do |format|
      format.html
      format.json { render json: stock_rows_json }
    end
  end

  def move
    rows = move_rows
    if rows.empty?
      render json: { success: false, errors: [ "이동할 재고 행이 없습니다." ] }, status: :unprocessable_entity
      return
    end

    result = { moved: 0 }
    errors = []
    actor = current_actor

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        process_move_row(row, index + 1, result, errors, actor)
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "재고이동이 완료되었습니다.", data: result }
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  private
    def menu_code_for_permission
      "WM_STOCK_MOVE"
    end

    def search_params
      params.fetch(:q, {}).permit(
        :workpl_cd, :cust_cd, :item_cd, :area_cd, :zone_cd, :loc_cd
      )
    end

    def stock_rows_json
      rows = stock_scope.limit(2000).to_a
      return [] if rows.empty?

      stock_attr_map = build_stock_attr_map(rows)
      location_map = build_location_map(rows)
      customer_name_map = build_customer_name_map(rows)
      item_name_map = build_item_name_map(rows)

      rows.map do |row|
        stock_attr = stock_attr_map[row.stock_attr_no]
        location = location_map[[ row.workpl_cd, row.loc_cd ]]

        qty = decimal_value(row.qty)
        alloc_qty = decimal_value(row.alloc_qty)
        pick_qty = decimal_value(row.pick_qty)
        move_poss_qty = qty - alloc_qty - pick_qty

        payload = {
          id: [ row.corp_cd, row.workpl_cd, row.stock_attr_no, row.loc_cd ].join("_"),
          corp_cd: row.corp_cd,
          workpl_cd: row.workpl_cd,
          cust_cd: row.cust_cd,
          cust_nm: customer_name_map[row.cust_cd] || row.cust_cd,
          area_cd: location&.area_cd,
          zone_cd: location&.zone_cd,
          loc_cd: row.loc_cd,
          item_cd: row.item_cd,
          item_nm: item_name_map[row.item_cd] || row.item_cd,
          stock_attr_no: row.stock_attr_no,
          basis_unit_cls: row.basis_unit_cls,
          basis_unit_cd: row.basis_unit_cd,
          qty: decimal_to_number(qty),
          assign_qty: decimal_to_number(alloc_qty),
          pick_qty: decimal_to_number(pick_qty),
          move_poss_qty: decimal_to_number(move_poss_qty),
          to_loc_cd: "",
          move_qty: nil
        }

        STOCK_ATTR_COLUMNS.each do |column_name|
          payload[column_name.to_sym] = stock_attr&.public_send(column_name)
        end

        payload
      end
    end

    def stock_scope
      scope = Wm::StockAttrLocQty.order(:workpl_cd, :loc_cd, :stock_attr_no)

      if search_workpl_cd.present?
        scope = scope.where(workpl_cd: search_workpl_cd)
      else
        scope = scope.none
      end

      if search_cust_cd.present?
        scope = scope.where(cust_cd: search_cust_cd)
      end

      if search_item_cd.present?
        scope = scope.where(item_cd: search_item_cd)
      end

      if search_area_cd.present? || search_zone_cd.present?
        loc_scope = WmLocation.where(workpl_cd: search_workpl_cd)

        if search_area_cd.present?
          loc_scope = loc_scope.where(area_cd: search_area_cd)
        end

        if search_zone_cd.present?
          loc_scope = loc_scope.where(zone_cd: search_zone_cd)
        end

        scope = scope.where(loc_cd: loc_scope.select(:loc_cd))
      end

      if search_loc_cd.present?
        scope = scope.where("loc_cd LIKE ?", "%#{search_loc_cd}%")
      end

      scope
    end

    def search_workpl_cd
      search_params[:workpl_cd].to_s.strip.upcase.presence
    end

    def search_cust_cd
      search_params[:cust_cd].to_s.strip.upcase.presence
    end

    def search_item_cd
      search_params[:item_cd].to_s.strip.upcase.presence
    end

    def search_area_cd
      search_params[:area_cd].to_s.strip.upcase.presence
    end

    def search_zone_cd
      search_params[:zone_cd].to_s.strip.upcase.presence
    end

    def search_loc_cd
      search_params[:loc_cd].to_s.strip.upcase.presence
    end

    def build_stock_attr_map(rows)
      stock_attr_nos = rows.map(&:stock_attr_no).uniq
      return {} if stock_attr_nos.empty?

      Wm::StockAttr.where(stock_attr_no: stock_attr_nos).index_by(&:stock_attr_no)
    end

    def build_location_map(rows)
      keys = rows.map { |row| [ row.workpl_cd, row.loc_cd ] }.uniq
      return {} if keys.empty?

      workpl_codes = keys.map(&:first).uniq
      loc_codes = keys.map(&:last).uniq
      rows = WmLocation.where(workpl_cd: workpl_codes, loc_cd: loc_codes).ordered.to_a

      map = {}
      rows.each do |row|
        key = [ row.workpl_cd, row.loc_cd ]
        if !map.key?(key)
          map[key] = row
        end
      end

      map
    end

    def build_customer_name_map(rows)
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return {}
      end

      cust_codes = rows.map(&:cust_cd).map { |code| code.to_s.strip.upcase }.reject(&:blank?).uniq
      return {} if cust_codes.empty?

      StdBzacMst.where(bzac_cd: cust_codes).pluck(:bzac_cd, :bzac_nm).to_h do |code, name|
        [ code.to_s.strip.upcase, name.to_s.strip ]
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def build_item_name_map(rows)
      if !defined?(StdGood) || !StdGood.table_exists?
        return {}
      end

      item_codes = rows.map(&:item_cd).map { |code| code.to_s.strip.upcase }.reject(&:blank?).uniq
      return {} if item_codes.empty?

      StdGood.where(goods_cd: item_codes).pluck(:goods_cd, :goods_nm).to_h do |code, name|
        [ code.to_s.strip.upcase, name.to_s.strip ]
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def move_rows
      permitted = params.permit(rows: MOVE_ROW_PERMITTED_FIELDS)
      rows = permitted[:rows]
      if rows.is_a?(Array)
        rows
      else
        []
      end
    end

    def process_move_row(row, row_no, result, errors, actor)
      corp_cd = row[:corp_cd].to_s.strip.upcase
      workpl_cd = row[:workpl_cd].to_s.strip.upcase
      cust_cd = row[:cust_cd].to_s.strip.upcase
      item_cd = row[:item_cd].to_s.strip.upcase
      stock_attr_no = row[:stock_attr_no].to_s.strip.upcase
      from_loc_cd = row[:loc_cd].to_s.strip.upcase
      to_loc_cd = row[:to_loc_cd].to_s.strip.upcase
      move_qty = decimal_value(row[:move_qty])
      basis_unit_cls = row[:basis_unit_cls].to_s.strip.upcase.presence || "10"
      basis_unit_cd = row[:basis_unit_cd].to_s.strip.upcase.presence || "EA"

      if corp_cd.blank? || workpl_cd.blank? || item_cd.blank? || stock_attr_no.blank? || from_loc_cd.blank?
        errors << "#{row_no}행: 이동 대상 키 값이 누락되었습니다."
        return
      end

      if to_loc_cd.blank?
        errors << "#{row_no}행: TO 로케이션을 입력해주세요."
        return
      end

      if from_loc_cd == to_loc_cd
        errors << "#{row_no}행: TO 로케이션은 FROM 로케이션과 달라야 합니다."
        return
      end

      if move_qty <= 0
        errors << "#{row_no}행: 이동수량은 0보다 커야 합니다."
        return
      end

      from_stock = Wm::StockAttrLocQty.find_by(
        corp_cd: corp_cd,
        workpl_cd: workpl_cd,
        stock_attr_no: stock_attr_no,
        loc_cd: from_loc_cd
      )
      if from_stock.nil?
        errors << "#{row_no}행: FROM 로케이션 재고를 찾을 수 없습니다."
        return
      end

      available_qty = decimal_value(from_stock.qty) - decimal_value(from_stock.alloc_qty) - decimal_value(from_stock.pick_qty)
      if move_qty > available_qty
        errors << "#{row_no}행: 이동수량이 이동가능물량을 초과했습니다."
        return
      end

      if !WmLocation.where(workpl_cd: workpl_cd, loc_cd: to_loc_cd, use_yn: "Y").exists?
        errors << "#{row_no}행: TO 로케이션이 존재하지 않거나 사용 불가 상태입니다."
        return
      end

      from_loc_qty = Wm::LocQty.find_by(
        corp_cd: corp_cd,
        workpl_cd: workpl_cd,
        cust_cd: cust_cd,
        loc_cd: from_loc_cd,
        item_cd: item_cd
      )
      if from_loc_qty.nil?
        errors << "#{row_no}행: FROM 로케이션 집계 재고를 찾을 수 없습니다."
        return
      end

      if move_qty > decimal_value(from_loc_qty.qty)
        errors << "#{row_no}행: FROM 로케이션 집계 재고가 부족합니다."
        return
      end

      now = Time.current
      Wm::StockAttrLocQty.where(
        corp_cd: corp_cd,
        workpl_cd: workpl_cd,
        stock_attr_no: stock_attr_no,
        loc_cd: from_loc_cd
      ).update_all(
        qty: decimal_value(from_stock.qty) - move_qty,
        update_by: actor,
        update_time: now
      )

      to_stock = Wm::StockAttrLocQty.find_by(
        corp_cd: corp_cd,
        workpl_cd: workpl_cd,
        stock_attr_no: stock_attr_no,
        loc_cd: to_loc_cd
      )

      if to_stock
        Wm::StockAttrLocQty.where(
          corp_cd: corp_cd,
          workpl_cd: workpl_cd,
          stock_attr_no: stock_attr_no,
          loc_cd: to_loc_cd
        ).update_all(
          qty: decimal_value(to_stock.qty) + move_qty,
          update_by: actor,
          update_time: now
        )
      else
        Wm::StockAttrLocQty.create!(
          corp_cd: corp_cd,
          workpl_cd: workpl_cd,
          stock_attr_no: stock_attr_no,
          loc_cd: to_loc_cd,
          cust_cd: cust_cd,
          item_cd: item_cd,
          basis_unit_cls: basis_unit_cls,
          basis_unit_cd: basis_unit_cd,
          qty: move_qty,
          alloc_qty: 0,
          pick_qty: 0,
          hold_qty: 0,
          create_by: actor,
          create_time: now,
          update_by: actor,
          update_time: now
        )
      end

      Wm::LocQty.where(
        corp_cd: corp_cd,
        workpl_cd: workpl_cd,
        cust_cd: cust_cd,
        loc_cd: from_loc_cd,
        item_cd: item_cd
      ).update_all(
        qty: decimal_value(from_loc_qty.qty) - move_qty,
        update_by: actor,
        update_time: now
      )

      to_loc_qty = Wm::LocQty.find_by(
        corp_cd: corp_cd,
        workpl_cd: workpl_cd,
        cust_cd: cust_cd,
        loc_cd: to_loc_cd,
        item_cd: item_cd
      )

      if to_loc_qty
        Wm::LocQty.where(
          corp_cd: corp_cd,
          workpl_cd: workpl_cd,
          cust_cd: cust_cd,
          loc_cd: to_loc_cd,
          item_cd: item_cd
        ).update_all(
          qty: decimal_value(to_loc_qty.qty) + move_qty,
          update_by: actor,
          update_time: now
        )
      else
        Wm::LocQty.create!(
          corp_cd: corp_cd,
          workpl_cd: workpl_cd,
          cust_cd: cust_cd,
          loc_cd: to_loc_cd,
          item_cd: item_cd,
          basis_unit_cls: basis_unit_cls,
          basis_unit_cd: basis_unit_cd,
          qty: move_qty,
          alloc_qty: 0,
          pick_qty: 0,
          hold_qty: 0,
          create_by: actor,
          create_time: now,
          update_by: actor,
          update_time: now
        )
      end

      stock_attr = Wm::StockAttr.find_by(stock_attr_no: stock_attr_no)
      Wm::StockMove.create!(
        corp_cd: corp_cd,
        workpl_cd: workpl_cd,
        cust_cd: cust_cd,
        item_cd: item_cd,
        stock_attr_no: stock_attr_no,
        from_loc_cd: from_loc_cd,
        to_loc_cd: to_loc_cd,
        move_qty: move_qty,
        basis_unit_cls: basis_unit_cls,
        basis_unit_cd: basis_unit_cd,
        move_type: "MV",
        move_ymd: now.strftime("%Y%m%d"),
        move_hms: now.strftime("%H%M%S"),
        **stock_attr_snapshot(stock_attr)
      )

      sync_location_stock_flag(workpl_cd, from_loc_cd, actor)
      sync_location_stock_flag(workpl_cd, to_loc_cd, actor)

      result[:moved] += 1
    end

    def sync_location_stock_flag(workpl_cd, loc_cd, actor)
      locations = WmLocation.where(workpl_cd: workpl_cd, loc_cd: loc_cd)
      return if locations.none?

      total_qty = Wm::StockAttrLocQty.where(workpl_cd: workpl_cd, loc_cd: loc_cd).sum(:qty)
      has_stock = if decimal_value(total_qty) > 0
        "Y"
      else
        "N"
      end

      locations.update_all(has_stock: has_stock, update_by: actor, update_time: Time.current)
    end

    def stock_attr_snapshot(stock_attr)
      snapshot = {}

      STOCK_ATTR_COLUMNS.each do |column_name|
        snapshot[column_name.to_sym] = stock_attr&.public_send(column_name)
      end

      snapshot
    end

    def decimal_value(value)
      BigDecimal(value.to_s.presence || "0")
    end

    def decimal_to_number(value)
      decimal_value(value).round(3).to_f
    end

    def current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
