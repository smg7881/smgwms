class Wm::GiPrarsController < Wm::BaseController
  def index
    if params[:gi_prar_id].present?
      gi_prar = Wm::GiPrar.find_by!(gi_prar_no: params[:gi_prar_id])
      rows = gi_prar.details.ordered
      render json: rows.map { |row| detail_json(row) }
    else
      respond_to do |format|
        format.html
        format.json { render json: records_scope.map { |row| header_json(row) } }
      end
    end
  end

  def picks
    gi_prar = Wm::GiPrar.find_by!(gi_prar_no: params[:id])
    ensure_pick_rows!(gi_prar)
    render json: gi_prar.picks.ordered.map { |row| pick_json(row) }
  end

  def batch_save
    if params[:gi_prar_id].present?
      batch_save_detail_rows
    else
      batch_save_master_rows
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  def assign
    gi_prar = Wm::GiPrar.find_by!(gi_prar_no: params[:id])
    errors = []
    result = { updated: 0 }
    actor = current_actor

    if !gi_prar.instructed?
      render json: { success: false, errors: [ "할당은 출고지시(10) 상태에서만 가능합니다." ] }, status: :unprocessable_entity
      return
    end

    rows = normalize_pick_rows(params[:rows])
    ActiveRecord::Base.transaction do
      rows.each do |attrs|
        pick = gi_prar.picks.find_by(pick_no: attrs[:pick_no].to_s.strip)
        if pick.nil?
          errors << "피킹정보를 찾을 수 없습니다."
          next
        end

        desired_assign_qty = attrs[:assign_qty].to_f
        if desired_assign_qty < 0
          errors << "할당수량은 음수일 수 없습니다."
          next
        end

        delta_assign_qty = desired_assign_qty - pick.assign_qty.to_f
        if delta_assign_qty != 0
          apply_stock_adjustment_for_pick!(
            gi_prar: gi_prar,
            pick: pick,
            delta_qty: 0,
            delta_alloc_qty: delta_assign_qty,
            delta_pick_qty: 0,
            actor: actor,
            errors: errors
          )
        end

        next if errors.any?

        pick.assign_qty = desired_assign_qty
        pick.pick_stat_cd = if pick.pick_qty.to_f > 0
          Wm::GiPick::PICK_STAT_PICKED
        elsif pick.assign_qty.to_f > 0
          Wm::GiPick::PICK_STAT_ASSIGNED
        else
          Wm::GiPick::PICK_STAT_INSTRUCTED
        end
        pick.update_by = actor
        pick.update_time = Time.current
        pick.save!
        refresh_pick_stock_snapshot!(pick, gi_prar, actor)
        result[:updated] += 1
      end

      refresh_header_detail_from_picks!(gi_prar, actor)
      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "할당 처리가 완료되었습니다.", data: result }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  def pick
    gi_prar = Wm::GiPrar.find_by!(gi_prar_no: params[:id])
    errors = []
    result = { updated: 0 }
    actor = current_actor

    if !(gi_prar.assigned? || gi_prar.picked?)
      render json: { success: false, errors: [ "피킹은 할당(20) 상태에서만 가능합니다." ] }, status: :unprocessable_entity
      return
    end

    rows = normalize_pick_rows(params[:rows])
    ActiveRecord::Base.transaction do
      rows.each do |attrs|
        pick = gi_prar.picks.find_by(pick_no: attrs[:pick_no].to_s.strip)
        if pick.nil?
          errors << "피킹정보를 찾을 수 없습니다."
          next
        end

        desired_pick_qty = attrs[:pick_qty].to_f
        if desired_pick_qty < 0
          errors << "피킹수량은 음수일 수 없습니다."
          next
        end

        delta_pick_qty = desired_pick_qty - pick.pick_qty.to_f
        if delta_pick_qty > 0 && pick.assign_qty.to_f < delta_pick_qty
          errors << "피킹수량이 할당잔량보다 큽니다. (피킹번호: #{pick.pick_no})"
          next
        end

        if delta_pick_qty != 0
          apply_stock_adjustment_for_pick!(
            gi_prar: gi_prar,
            pick: pick,
            delta_qty: 0,
            delta_alloc_qty: delta_pick_qty * -1,
            delta_pick_qty: delta_pick_qty,
            actor: actor,
            errors: errors
          )
        end

        next if errors.any?

        pick.assign_qty = pick.assign_qty.to_f - delta_pick_qty
        pick.pick_qty = desired_pick_qty
        pick.pick_stat_cd = if pick.pick_qty.to_f > 0
          Wm::GiPick::PICK_STAT_PICKED
        elsif pick.assign_qty.to_f > 0
          Wm::GiPick::PICK_STAT_ASSIGNED
        else
          Wm::GiPick::PICK_STAT_INSTRUCTED
        end

        if pick.pick_qty.to_f > 0
          now = Time.current
          pick.pick_ymd = now.strftime("%Y%m%d")
          pick.pick_hms = now.strftime("%H%M%S")
        end

        pick.update_by = actor
        pick.update_time = Time.current
        pick.save!
        refresh_pick_stock_snapshot!(pick, gi_prar, actor)
        result[:updated] += 1
      end

      refresh_header_detail_from_picks!(gi_prar, actor)
      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "피킹 처리가 완료되었습니다.", data: result }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  def confirm
    gi_prar = Wm::GiPrar.find_by!(gi_prar_no: params[:id])
    errors = []
    actor = current_actor
    confirmed_qty_by_line = Hash.new(0.0)

    if !gi_prar.picked?
      render json: { success: false, errors: [ "출고확정은 피킹(30) 상태에서만 가능합니다." ] }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      gi_prar.picks.ordered.each do |pick|
        remaining_assign_qty = pick.assign_qty.to_f
        if remaining_assign_qty > 0
          apply_stock_adjustment_for_pick!(
            gi_prar: gi_prar,
            pick: pick,
            delta_qty: 0,
            delta_alloc_qty: remaining_assign_qty * -1,
            delta_pick_qty: 0,
            actor: actor,
            errors: errors
          )
          pick.assign_qty = 0
        end

        next if errors.any?

        confirmed_pick_qty = pick.pick_qty.to_f
        if confirmed_pick_qty > 0
          apply_stock_adjustment_for_pick!(
            gi_prar: gi_prar,
            pick: pick,
            delta_qty: confirmed_pick_qty * -1,
            delta_alloc_qty: 0,
            delta_pick_qty: confirmed_pick_qty * -1,
            actor: actor,
            errors: errors
          )
          confirmed_qty_by_line[pick.lineno] += confirmed_pick_qty
        end

        next if errors.any?

        pick.pick_stat_cd = Wm::GiPick::PICK_STAT_CONFIRMED
        pick.update_by = actor
        pick.update_time = Time.current
        pick.save!
        refresh_pick_stock_snapshot!(pick, gi_prar, actor)
      end

      now = Time.current
      gi_prar.details.ordered.each do |detail|
        confirmed_qty = confirmed_qty_by_line[detail.lineno].to_f
        detail.gi_rslt_qty = detail.gi_rslt_qty.to_f + confirmed_qty
        detail.assign_qty = 0
        detail.pick_qty = 0
        detail.gi_stat_cd = Wm::GiPrar::GI_STAT_CONFIRMED
        detail.update_by = actor
        detail.update_time = now
        detail.save!
      end

      gi_prar.update!(
        gi_stat_cd: Wm::GiPrar::GI_STAT_CONFIRMED,
        gi_ymd: now.strftime("%Y%m%d"),
        gi_hms: now.strftime("%H%M%S"),
        update_by: actor,
        update_time: now
      )

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "출고확정 처리가 완료되었습니다." }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  def cancel
    gi_prar = Wm::GiPrar.find_by!(gi_prar_no: params[:id])
    errors = []
    actor = current_actor

    if gi_prar.confirmed?
      render json: { success: false, errors: [ "출고확정(40) 상태는 취소할 수 없습니다." ] }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      gi_prar.picks.ordered.each do |pick|
        current_assign_qty = pick.assign_qty.to_f
        current_pick_qty = pick.pick_qty.to_f

        if current_assign_qty != 0 || current_pick_qty != 0
          apply_stock_adjustment_for_pick!(
            gi_prar: gi_prar,
            pick: pick,
            delta_qty: 0,
            delta_alloc_qty: current_assign_qty * -1,
            delta_pick_qty: current_pick_qty * -1,
            actor: actor,
            errors: errors
          )
        end

        next if errors.any?

        pick.assign_qty = 0
        pick.pick_qty = 0
        pick.pick_stat_cd = Wm::GiPick::PICK_STAT_INSTRUCTED
        pick.pick_ymd = nil
        pick.pick_hms = nil
        pick.update_by = actor
        pick.update_time = Time.current
        pick.save!
        refresh_pick_stock_snapshot!(pick, gi_prar, actor)
      end

      gi_prar.details.ordered.each do |detail|
        detail.assign_qty = 0
        detail.pick_qty = 0
        detail.gi_stat_cd = Wm::GiPrar::GI_STAT_INSTRUCTED
        detail.update_by = actor
        detail.update_time = Time.current
        detail.save!
      end

      gi_prar.update!(
        gi_stat_cd: Wm::GiPrar::GI_STAT_INSTRUCTED,
        update_by: actor,
        update_time: Time.current
      )

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "출고취소 처리가 완료되었습니다." }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, errors: [ e.message ] }, status: :not_found
  rescue => e
    render json: { success: false, errors: [ e.message ] }, status: :unprocessable_entity
  end

  private
    def menu_code_for_permission
      "WM_GI_PRAR"
    end

    def search_params
      params.fetch(:q, {}).permit(
        :workpl_cd, :cust_cd, :gi_type_cd, :gi_stat_cd,
        :idct_ymd_from, :idct_ymd_to, :gi_ymd,
        :item_cd, :ord_no, :asign_no, :car_no
      )
    end

    def records_scope
      scope = Wm::GiPrar.ordered

      if search_params[:workpl_cd].present?
        scope = scope.where(workpl_cd: search_params[:workpl_cd])
      end
      if search_params[:cust_cd].present?
        scope = scope.where(cust_cd: search_params[:cust_cd])
      end
      if search_params[:gi_type_cd].present?
        scope = scope.where(gi_type_cd: search_params[:gi_type_cd])
      end
      if search_params[:gi_stat_cd].present?
        scope = scope.where(gi_stat_cd: search_params[:gi_stat_cd])
      end
      if search_params[:idct_ymd_from].present?
        scope = scope.where("idct_ymd >= ?", search_params[:idct_ymd_from].delete("-"))
      end
      if search_params[:idct_ymd_to].present?
        scope = scope.where("idct_ymd <= ?", search_params[:idct_ymd_to].delete("-"))
      end
      if search_params[:gi_ymd].present?
        scope = scope.where(gi_ymd: search_params[:gi_ymd].delete("-"))
      end
      if search_params[:ord_no].present?
        scope = scope.where("ord_no LIKE ?", "%#{search_params[:ord_no]}%")
      end
      if search_params[:asign_no].present?
        scope = scope.where("asign_no LIKE ?", "%#{search_params[:asign_no]}%")
      end
      if search_params[:car_no].present?
        scope = scope.where("car_no LIKE ?", "%#{search_params[:car_no]}%")
      end
      if search_params[:item_cd].present?
        scope = scope.joins(:details)
                     .where("wm_gi_prar_details.item_cd = ?", search_params[:item_cd])
                     .distinct
      end

      scope
    end

    def header_json(row)
      {
        id: row.gi_prar_no,
        gi_prar_no: row.gi_prar_no,
        workpl_cd: row.workpl_cd,
        corp_cd: row.corp_cd,
        cust_cd: row.cust_cd,
        gi_type_cd: row.gi_type_cd,
        gi_stat_cd: row.gi_stat_cd,
        idct_ymd: row.idct_ymd,
        gi_ymd: row.gi_ymd,
        gi_hms: row.gi_hms,
        ord_no: row.ord_no,
        exec_ord_no: row.exec_ord_no,
        asign_no: row.asign_no,
        dlv_prar_ymd: row.dlv_prar_ymd,
        dlv_prar_hms: row.dlv_prar_hms,
        car_no: row.car_no,
        driver_nm: row.driver_nm,
        driver_telno: row.driver_telno,
        transco_cd: row.transco_cd,
        rmk: row.rmk
      }
    end

    def detail_json(row)
      {
        id: "#{row.gi_prar_no}_#{row.lineno}",
        gi_prar_no: row.gi_prar_no,
        lineno: row.lineno,
        item_cd: row.item_cd,
        item_nm: row.item_nm,
        unit_cd: row.unit_cd,
        gi_idct_qty: row.gi_idct_qty,
        gi_rslt_qty: row.gi_rslt_qty,
        assign_qty: row.assign_qty,
        pick_qty: row.pick_qty,
        gi_stat_cd: row.gi_stat_cd,
        stock_attr_col01: row.stock_attr_col01,
        stock_attr_col02: row.stock_attr_col02,
        stock_attr_col03: row.stock_attr_col03,
        stock_attr_col04: row.stock_attr_col04,
        stock_attr_col05: row.stock_attr_col05,
        stock_attr_col06: row.stock_attr_col06,
        stock_attr_col07: row.stock_attr_col07,
        stock_attr_col08: row.stock_attr_col08,
        stock_attr_col09: row.stock_attr_col09,
        stock_attr_col10: row.stock_attr_col10,
        rmk: row.rmk
      }
    end

    def pick_json(row)
      {
        id: row.pick_no,
        pick_no: row.pick_no,
        gi_prar_no: row.gi_prar_no,
        lineno: row.lineno,
        item_cd: row.item_cd,
        item_nm: row.item_nm,
        unit_cd: row.unit_cd,
        loc_cd: row.loc_cd,
        stock_attr_no: row.stock_attr_no,
        stock_qty: row.stock_qty,
        assign_qty: row.assign_qty,
        pick_qty: row.pick_qty,
        pick_stat_cd: row.pick_stat_cd,
        pick_ymd: row.pick_ymd,
        pick_hms: row.pick_hms,
        stock_attr_col01: row.stock_attr_col01,
        stock_attr_col02: row.stock_attr_col02,
        stock_attr_col03: row.stock_attr_col03,
        stock_attr_col04: row.stock_attr_col04,
        stock_attr_col05: row.stock_attr_col05,
        stock_attr_col06: row.stock_attr_col06,
        stock_attr_col07: row.stock_attr_col07,
        stock_attr_col08: row.stock_attr_col08,
        stock_attr_col09: row.stock_attr_col09,
        stock_attr_col10: row.stock_attr_col10,
        rmk: row.rmk
      }
    end

    def master_batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :gi_prar_no, :car_no, :driver_telno, :rmk ],
        rowsToUpdate: [ :gi_prar_no, :car_no, :driver_telno, :rmk ]
      )
    end

    def detail_batch_save_params
      stock_attr_fields = Wm::GiPrarDetail::STOCK_ATTR_COLS.map(&:to_sym)
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :lineno, :rmk, *stock_attr_fields ],
        rowsToUpdate: [ :lineno, :rmk, *stock_attr_fields ]
      )
    end

    def batch_save_master_rows
      operations = master_batch_save_params
      result = { inserted: 0, updated: 0, deleted: 0 }
      errors = []

      ActiveRecord::Base.transaction do
        if Array(operations[:rowsToInsert]).any?
          errors << "출고지시 신규등록은 지원하지 않습니다."
        end
        if Array(operations[:rowsToDelete]).any?
          errors << "출고지시 삭제는 지원하지 않습니다."
        end

        Array(operations[:rowsToUpdate]).each do |attrs|
          gi_prar = Wm::GiPrar.find_by(gi_prar_no: attrs[:gi_prar_no].to_s.strip)
          if gi_prar.nil?
            errors << "출고지시를 찾을 수 없습니다."
            next
          end

          if gi_prar.confirmed?
            errors << "출고확정 상태는 수정할 수 없습니다. (#{gi_prar.gi_prar_no})"
            next
          end

          if gi_prar.update(attrs.permit(:car_no, :driver_telno, :rmk))
            result[:updated] += 1
          else
            errors.concat(gi_prar.errors.full_messages)
          end
        end

        raise ActiveRecord::Rollback if errors.any?
      end

      if errors.any?
        render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
      else
        render json: { success: true, message: "출고지시가 저장되었습니다.", data: result }
      end
    end

    def batch_save_detail_rows
      gi_prar = Wm::GiPrar.find_by!(gi_prar_no: params[:gi_prar_id])
      operations = detail_batch_save_params
      result = { inserted: 0, updated: 0, deleted: 0 }
      errors = []

      ActiveRecord::Base.transaction do
        if gi_prar.confirmed?
          errors << "출고확정 상태는 상세를 수정할 수 없습니다."
        end
        if Array(operations[:rowsToInsert]).any?
          errors << "출고지시 상세 신규등록은 지원하지 않습니다."
        end
        if Array(operations[:rowsToDelete]).any?
          errors << "출고지시 상세 삭제는 지원하지 않습니다."
        end

        stock_attr_fields = Wm::GiPrarDetail::STOCK_ATTR_COLS.map(&:to_sym)
        Array(operations[:rowsToUpdate]).each do |attrs|
          lineno = attrs[:lineno].to_i
          detail = gi_prar.details.find_by(lineno: lineno)
          if detail.nil?
            errors << "출고지시 상세를 찾을 수 없습니다. (라인 #{lineno})"
            next
          end

          permitted = attrs.permit(:rmk, *stock_attr_fields)
          if detail.update(permitted)
            result[:updated] += 1
          else
            errors.concat(detail.errors.full_messages)
          end
        end

        raise ActiveRecord::Rollback if errors.any?
      end

      if errors.any?
        render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
      else
        render json: { success: true, message: "출고지시상세가 저장되었습니다.", data: result }
      end
    end

    def ensure_pick_rows!(gi_prar)
      if gi_prar.picks.exists?
        return
      end

      actor = current_actor
      now = Time.current
      gi_prar.details.ordered.each do |detail|
        stock_rows = Wm::StockAttrLocQty.where(
          corp_cd: gi_prar.corp_cd,
          workpl_cd: gi_prar.workpl_cd,
          cust_cd: gi_prar.cust_cd,
          item_cd: detail.item_cd
        ).order(:loc_cd, :stock_attr_no)

        stock_rows.each do |stock|
          stock_attr = Wm::StockAttr.find_by(stock_attr_no: stock.stock_attr_no)
          Wm::GiPick.create!(
            pick_no: Wm::GiPick.generate_no,
            gi_prar_no: gi_prar.gi_prar_no,
            lineno: detail.lineno,
            item_cd: detail.item_cd,
            item_nm: detail.item_nm,
            unit_cd: detail.unit_cd,
            loc_cd: stock.loc_cd,
            stock_attr_no: stock.stock_attr_no,
            stock_qty: stock.qty.to_f,
            assign_qty: 0,
            pick_qty: 0,
            pick_stat_cd: Wm::GiPick::PICK_STAT_INSTRUCTED,
            stock_attr_col01: stock_attr&.stock_attr_col01,
            stock_attr_col02: stock_attr&.stock_attr_col02,
            stock_attr_col03: stock_attr&.stock_attr_col03,
            stock_attr_col04: stock_attr&.stock_attr_col04,
            stock_attr_col05: stock_attr&.stock_attr_col05,
            stock_attr_col06: stock_attr&.stock_attr_col06,
            stock_attr_col07: stock_attr&.stock_attr_col07,
            stock_attr_col08: stock_attr&.stock_attr_col08,
            stock_attr_col09: stock_attr&.stock_attr_col09,
            stock_attr_col10: stock_attr&.stock_attr_col10,
            create_by: actor,
            create_time: now,
            update_by: actor,
            update_time: now
          )
        end
      end
    end

    def refresh_header_detail_from_picks!(gi_prar, actor)
      assign_sum_by_line = gi_prar.picks.group(:lineno).sum(:assign_qty)
      pick_sum_by_line = gi_prar.picks.group(:lineno).sum(:pick_qty)

      any_assigned = false
      any_picked = false
      now = Time.current
      gi_prar.details.ordered.each do |detail|
        assign_qty = assign_sum_by_line[detail.lineno].to_f
        pick_qty = pick_sum_by_line[detail.lineno].to_f
        line_status = if pick_qty > 0
          Wm::GiPrar::GI_STAT_PICKED
        elsif assign_qty > 0
          Wm::GiPrar::GI_STAT_ASSIGNED
        else
          Wm::GiPrar::GI_STAT_INSTRUCTED
        end

        detail.assign_qty = assign_qty
        detail.pick_qty = pick_qty
        detail.gi_stat_cd = line_status
        detail.update_by = actor
        detail.update_time = now
        detail.save!

        any_assigned ||= assign_qty > 0
        any_picked ||= pick_qty > 0
      end

      header_status = if any_picked
        Wm::GiPrar::GI_STAT_PICKED
      elsif any_assigned
        Wm::GiPrar::GI_STAT_ASSIGNED
      else
        Wm::GiPrar::GI_STAT_INSTRUCTED
      end

      gi_prar.update!(
        gi_stat_cd: header_status,
        update_by: actor,
        update_time: now
      )
    end

    def normalize_pick_rows(raw_rows)
      Array(raw_rows).map do |row|
        if row.respond_to?(:permit)
          row.permit(:pick_no, :assign_qty, :pick_qty, :rmk).to_h.symbolize_keys
        else
          row.to_h.symbolize_keys.slice(:pick_no, :assign_qty, :pick_qty, :rmk)
        end
      end
    end

    def apply_stock_adjustment_for_pick!(gi_prar:, pick:, delta_qty:, delta_alloc_qty:, delta_pick_qty:, actor:, errors:)
      if pick.stock_attr_no.blank? || pick.loc_cd.blank?
        errors << "재고속성/로케이션 정보가 없는 피킹행은 처리할 수 없습니다. (#{pick.pick_no})"
        return
      end

      stock_attr_qty = Wm::StockAttrQty.find_by(
        corp_cd: gi_prar.corp_cd,
        workpl_cd: gi_prar.workpl_cd,
        stock_attr_no: pick.stock_attr_no
      )
      stock_attr_loc_qty = Wm::StockAttrLocQty.find_by(
        corp_cd: gi_prar.corp_cd,
        workpl_cd: gi_prar.workpl_cd,
        stock_attr_no: pick.stock_attr_no,
        loc_cd: pick.loc_cd
      )
      loc_qty = Wm::LocQty.find_by(
        corp_cd: gi_prar.corp_cd,
        workpl_cd: gi_prar.workpl_cd,
        cust_cd: gi_prar.cust_cd,
        loc_cd: pick.loc_cd,
        item_cd: pick.item_cd
      )

      if stock_attr_qty.nil? || stock_attr_loc_qty.nil? || loc_qty.nil?
        errors << "재고정보를 찾을 수 없습니다. (#{pick.pick_no})"
        return
      end

      candidates = [
        [ stock_attr_qty, stock_attr_qty.qty.to_f + delta_qty, stock_attr_qty.alloc_qty.to_f + delta_alloc_qty, stock_attr_qty.pick_qty.to_f + delta_pick_qty ],
        [ stock_attr_loc_qty, stock_attr_loc_qty.qty.to_f + delta_qty, stock_attr_loc_qty.alloc_qty.to_f + delta_alloc_qty, stock_attr_loc_qty.pick_qty.to_f + delta_pick_qty ],
        [ loc_qty, loc_qty.qty.to_f + delta_qty, loc_qty.alloc_qty.to_f + delta_alloc_qty, loc_qty.pick_qty.to_f + delta_pick_qty ]
      ]
      has_negative_value = candidates.any? do |(_row, qty, alloc_qty, pick_qty)|
        qty < 0 || alloc_qty < 0 || pick_qty < 0
      end

      if has_negative_value
        errors << "재고수량이 부족합니다. (#{pick.item_cd}/#{pick.loc_cd})"
        return
      end

      now = Time.current
      candidates.each do |row, qty, alloc_qty, pick_qty|
        row.update!(
          qty: qty,
          alloc_qty: alloc_qty,
          pick_qty: pick_qty,
          update_by: actor,
          update_time: now
        )
      end
    end

    def refresh_pick_stock_snapshot!(pick, gi_prar, actor)
      stock_attr_loc_qty = Wm::StockAttrLocQty.find_by(
        corp_cd: gi_prar.corp_cd,
        workpl_cd: gi_prar.workpl_cd,
        stock_attr_no: pick.stock_attr_no,
        loc_cd: pick.loc_cd
      )
      if stock_attr_loc_qty
        pick.stock_qty = stock_attr_loc_qty.qty.to_f
      end
      pick.update_by = actor
      pick.update_time = Time.current
      pick.save!
    end

    def current_actor
      Current.user&.user_id_code || Current.user&.email_address || "system"
    end
end
