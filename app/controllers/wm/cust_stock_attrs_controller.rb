class Wm::CustStockAttrsController < Wm::BaseController
    def index
      respond_to do |format|
        format.html
        format.json { render json: attrs_scope.map { |a| attr_json(a) } }
      end
    end

    def batch_save
      operations = batch_save_params
      result = { inserted: 0, updated: 0, deleted: 0 }
      errors = []

      ActiveRecord::Base.transaction do
        # Insert
        Array(operations[:rowsToInsert]).each do |attrs|
          next if attrs[:cust_cd].to_s.strip.blank? || attrs[:inout_sctn].to_s.strip.blank? || attrs[:stock_attr_sctn].to_s.strip.blank?

          attr_record = Wm::CustStockAttr.new(attrs.permit(:cust_cd, :inout_sctn, :stock_attr_sctn, :attr_desc, :rel_tbl, :rel_col, :use_yn))
          if attr_record.save
            result[:inserted] += 1
          else
            errors.concat(attr_record.errors.full_messages)
          end
        end

        # Update
        Array(operations[:rowsToUpdate]).each do |attrs|
          attr_record = Wm::CustStockAttr.find_by(
            cust_cd: attrs[:cust_cd].to_s,
            inout_sctn: attrs[:inout_sctn].to_s,
            stock_attr_sctn: attrs[:stock_attr_sctn].to_s
          )

          if attr_record.nil?
            errors << "해당 속성을 찾을 수 없습니다: #{attrs[:cust_cd]} - #{attrs[:inout_sctn]} - #{attrs[:stock_attr_sctn]}"
            next
          end

          if attr_record.update(attrs.permit(:attr_desc, :rel_tbl, :rel_col, :use_yn))
            result[:updated] += 1
          else
            errors.concat(attr_record.errors.full_messages)
          end
        end

        # Delete
        Array(operations[:rowsToDelete]).each do |pk_str|
          # PK가 콤마로 구분되어 올 수 있도록 프런트엔드와 맞춤 (예: "CUST_A,IN,SCTN_1")
          pks = pk_str.to_s.split(",")
          if pks.length == 3
            attr_record = Wm::CustStockAttr.find_by(cust_cd: pks[0], inout_sctn: pks[1], stock_attr_sctn: pks[2])
            next if attr_record.nil?

            if attr_record.destroy
              result[:deleted] += 1
            else
              errors.concat(attr_record.errors.full_messages.presence || [ "속성 삭제에 실패했습니다: #{pk_str}" ])
            end
          else
            errors << "잘못된 삭제 식별자입니다: #{pk_str}"
          end
        end

        raise ActiveRecord::Rollback if errors.any?
      end

      if errors.any?
        render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
      else
        render json: { success: true, message: "고객재고속성 저장이 완료되었습니다.", data: result }
      end
    end

    private
      def menu_code_for_permission = "WM_CUST_STOCK_ATTR"

      def search_params
        params.fetch(:q, {}).permit(:cust_cd, :inout_sctn)
      end

      def attrs_scope
        scope = Wm::CustStockAttr.ordered

        if search_params[:cust_cd].present?
          scope = scope.where(cust_cd: search_params[:cust_cd])
        end
        if search_params[:inout_sctn].present?
          scope = scope.where(inout_sctn: search_params[:inout_sctn])
        end

        scope
      end

      def batch_save_params
        params.permit(
          rowsToDelete: [],
          rowsToInsert: [ :cust_cd, :inout_sctn, :stock_attr_sctn, :attr_desc, :rel_tbl, :rel_col, :use_yn ],
          rowsToUpdate: [ :cust_cd, :inout_sctn, :stock_attr_sctn, :attr_desc, :rel_tbl, :rel_col, :use_yn ]
        )
      end

      def attr_json(attr)
        {
          id: [ attr.cust_cd, attr.inout_sctn, attr.stock_attr_sctn ].join(","),
          cust_cd: attr.cust_cd,
          inout_sctn: attr.inout_sctn,
          stock_attr_sctn: attr.stock_attr_sctn,
          attr_desc: attr.attr_desc,
          rel_tbl: attr.rel_tbl,
          rel_col: attr.rel_col,
          use_yn: attr.use_yn,
          update_by: attr.update_by,
          update_time: attr.update_time,
          create_by: attr.create_by,
          create_time: attr.create_time
        }
      end
end
