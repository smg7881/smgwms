class System::MenuLogsController < System::BaseController
  def index
    @menu_logs = filtered_menu_logs_scope

    respond_to do |format|
      format.html
      format.json { render json: @menu_logs.map { |log| menu_log_json(log) } }
    end
  end

  private
    def filtered_menu_logs_scope
      scope = AdmMenuLog.ordered

      if search_params[:user_id].present?
        scope = scope.where("user_id LIKE ?", "%#{search_params[:user_id]}%")
      end
      if search_params[:user_name].present?
        scope = scope.where("user_name LIKE ?", "%#{search_params[:user_name]}%")
      end
      if search_params[:menu_id].present?
        scope = scope.where("menu_id LIKE ?", "%#{search_params[:menu_id]}%")
      end
      if search_params[:menu_name].present?
        scope = scope.where("menu_name LIKE ?", "%#{search_params[:menu_name]}%")
      end
      if search_params[:ip_address].present?
        scope = scope.where("ip_address LIKE ?", "%#{search_params[:ip_address]}%")
      end

      from_time = parsed_time(search_params[:access_time_from])
      to_time = parsed_time(search_params[:access_time_to])

      if from_time.present?
        scope = scope.where("access_time >= ?", from_time)
      end
      if to_time.present?
        scope = scope.where("access_time <= ?", to_time)
      end

      scope
    end

    def search_params
      params.fetch(:q, {}).permit(
        :user_id,
        :user_name,
        :menu_id,
        :menu_name,
        :ip_address,
        :access_time_from,
        :access_time_to
      )
    end

    def parsed_time(value)
      return nil if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError, TypeError
      nil
    end

    def menu_log_json(log)
      {
        id: log.id,
        user_id: log.user_id,
        user_name: log.user_name,
        menu_id: log.menu_id,
        menu_name: log.menu_name,
        menu_path: log.menu_path,
        access_time: log.access_time,
        ip_address: log.ip_address,
        user_agent: log.user_agent,
        session_id: log.session_id,
        referrer: log.referrer
      }
    end
end
