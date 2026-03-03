class Std::CustomerClientsController < Std::ClientsController
  def batch_save
    unauthorized_codes = unauthorized_target_codes
    if unauthorized_codes.any?
      render json: {
        success: false,
        errors: [ "고객거래처 대상만 저장할 수 있습니다: #{unauthorized_codes.join(', ')}" ]
      }, status: :unprocessable_entity
    else
      super
    end
  end

  private
    def menu_code_for_permission
      "SALES_CUST_CLIENT"
    end

    def find_client
      bzac_cd = params[:id].to_s.strip.upcase
      StdBzacMst.find_by!(bzac_cd: bzac_cd, bzac_sctn_grp_cd: customer_section_group_code)
    end

    def clients_scope
      super.where(bzac_sctn_grp_cd: customer_section_group_code)
    end

    def search_sctn_group
      value = super
      if value.present?
        value
      else
        customer_section_group_code
      end
    end

    def client_params_from_row(row)
      super.merge(bzac_sctn_grp_cd: customer_section_group_code)
    end

    def customer_section_group_code
      "CUSTOMER"
    end

    def unauthorized_target_codes
      codes = batch_target_codes
      if codes.empty?
        return []
      end

      allowed = StdBzacMst.where(bzac_cd: codes, bzac_sctn_grp_cd: customer_section_group_code).pluck(:bzac_cd)
      codes - allowed
    end

    def batch_target_codes
      operations = params.permit(rowsToDelete: [], rowsToUpdate: [ :bzac_cd ])
      update_codes = Array(operations[:rowsToUpdate]).map { |row| row[:bzac_cd].to_s.strip.upcase }.reject(&:blank?)
      delete_codes = Array(operations[:rowsToDelete]).map { |code| code.to_s.strip.upcase }.reject(&:blank?)
      (update_codes + delete_codes).uniq
    end
end
