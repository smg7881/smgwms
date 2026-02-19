class System::LoginHistoriesController < System::BaseController
  def index
    respond_to do |format|
      format.html
      format.json do
        scope = filtered_scope
        total = scope.count
        page = [ params.fetch(:page, 1).to_i, 1 ].max
        per_page = [ params.fetch(:per_page, 50).to_i, 100 ].min

        rows = scope.offset((page - 1) * per_page).limit(per_page)

        render json: {
          rows: rows.map { |r| row_json(r) },
          total: total
        }
      end
    end
  end

  private
    def filtered_scope
      scope = AdmLoginHistory.recent_first

      if search_params[:user_id_code].present?
        scope = scope.by_user(search_params[:user_id_code])
      end
      if search_params[:login_success].present?
        scope = scope.by_success(search_params[:login_success] == "true")
      end

      from_time = parsed_time(search_params[:start_date])
      to_time = parsed_time(search_params[:end_date])
      scope = scope.since(from_time) if from_time
      scope = scope.until_time(to_time) if to_time

      scope
    end

    def search_params
      params.fetch(:q, {}).permit(:user_id_code, :start_date, :end_date, :login_success)
    end

    def parsed_time(value)
      return nil if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError, TypeError
      nil
    end

    def row_json(record)
      {
        id: record.id,
        user_id_code: record.user_id_code,
        user_nm: record.user_nm,
        login_time: record.login_time,
        login_success: record.login_success,
        ip_address: record.ip_address,
        browser: record.browser,
        os: record.os,
        failure_reason: record.failure_reason
      }
    end
end
