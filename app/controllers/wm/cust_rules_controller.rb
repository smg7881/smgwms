class Wm::CustRulesController < Wm::BaseController
  def index
    respond_to do |format|
      format.html
      format.json { render json: filter_scope.map { |r| record_json(r) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:inout_sctn].to_s.strip.blank? || attrs[:inout_type].to_s.strip.blank?
          next
        end

        rule = Wm::CustRule.new(attrs.permit(:workpl_cd, :cust_cd, :inout_sctn, :inout_type, :rule_sctn, :aply_yn, :remark))
        if rule.save
          result[:inserted] += 1
        else
          errors.concat(rule.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        # Finding by ID is generally safer if it's sent.
        rule = Wm::CustRule.find_by(id: attrs[:id])
        if rule.nil?
          errors << "규칙을 찾을 수 없습니다: ID #{attrs[:id]}"
          next
        end

        if rule.update(attrs.permit(:workpl_cd, :cust_cd, :inout_sctn, :inout_type, :rule_sctn, :aply_yn, :remark))
          result[:updated] += 1
        else
          errors.concat(rule.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |id|
        rule = Wm::CustRule.find_by(id: id)
        next if rule.nil?

        if rule.destroy
          result[:deleted] += 1
        else
          errors.concat(rule.errors.full_messages.presence || [ "규칙 삭제에 실패했습니다: ID #{id}" ])
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "고객 RULE 저장이 완료되었습니다.", data: result }
    end
  end

  private
    def search_params
      params.fetch(:q, {}).permit(:workpl_cd, :cust_cd, :inout_sctn, :inout_type, :rule_sctn, :aply_yn)
    end

    def filter_scope
      scope = Wm::CustRule.ordered

      if search_params[:workpl_cd].present?
        scope = scope.where("workpl_cd LIKE ?", "%#{search_params[:workpl_cd]}%")
      end
      if search_params[:cust_cd].present?
        scope = scope.where("cust_cd LIKE ?", "%#{search_params[:cust_cd]}%")
      end
      if search_params[:inout_sctn].present?
        scope = scope.where(inout_sctn: search_params[:inout_sctn])
      end
      if search_params[:inout_type].present?
        scope = scope.where(inout_type: search_params[:inout_type])
      end
      if search_params[:rule_sctn].present?
        scope = scope.where(rule_sctn: search_params[:rule_sctn])
      end
      if search_params[:aply_yn].present?
        scope = scope.where(aply_yn: search_params[:aply_yn])
      end

      scope
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [ :workpl_cd, :cust_cd, :inout_sctn, :inout_type, :rule_sctn, :aply_yn, :remark ],
        rowsToUpdate: [ :id, :workpl_cd, :cust_cd, :inout_sctn, :inout_type, :rule_sctn, :aply_yn, :remark ]
      )
    end

    def record_json(record)
      {
        id: record.id,
        workpl_cd: record.workpl_cd,
        cust_cd: record.cust_cd,
        inout_sctn: record.inout_sctn,
        inout_type: record.inout_type,
        rule_sctn: record.rule_sctn,
        aply_yn: record.aply_yn,
        remark: record.remark,
        update_by: record.update_by,
        update_time: record.update_time,
        create_by: record.create_by,
        create_time: record.create_time
      }
    end
end
