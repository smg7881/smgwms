class Std::HolidaysController < Std::BaseController
  def index
    if request.format.html? && params[:q].blank?
      redirect_to std_holidays_path(
        q: {
          ctry_cd: "KR",
          year: Date.current.year.to_s,
          month: Date.current.month.to_s.rjust(2, "0")
        }
      )
      return
    end

    respond_to do |format|
      format.html
      format.json { render json: holidays_scope.map { |row| holiday_json(row) } }
    end
  end

  def generate_weekends
    ctry_cd = params[:ctry_cd].to_s.strip.upcase
    year = params[:year].to_i
    month = params[:month].to_i

    if ctry_cd.blank? || year <= 0 || month <= 0
      render json: { success: false, errors: [ "국가코드/년도/월은 필수입니다." ] }, status: :unprocessable_entity
      return
    end

    begin
      first_day = Date.new(year, month, 1)
    rescue ArgumentError
      render json: { success: false, errors: [ "유효한 년/월이 아닙니다." ] }, status: :unprocessable_entity
      return
    end

    last_day = first_day.end_of_month
    processed_count = 0

    ActiveRecord::Base.transaction do
      (first_day..last_day).each do |current_day|
        next unless current_day.saturday? || current_day.sunday?

        holiday = StdHoliday.find_or_initialize_by(ctry_cd: ctry_cd, ymd: current_day)
        if current_day.saturday?
          holiday.holiday_nm_cd = "토요일"
          holiday.sat_yn_cd = "Y"
          holiday.sunday_yn_cd = "N"
        else
          holiday.holiday_nm_cd = "일요일"
          holiday.sat_yn_cd = "N"
          holiday.sunday_yn_cd = "Y"
        end
        holiday.clsdy_yn_cd = "Y"
        holiday.asmt_holday_yn_cd = "N"
        holiday.event_day_yn_cd = "N"
        holiday.use_yn_cd = "Y"
        holiday.save!
        processed_count += 1
      end
    end

    render json: { success: true, message: "토/일 생성이 완료되었습니다.", data: { count: processed_count } }
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:ctry_cd].to_s.strip.blank? || attrs[:ymd].to_s.strip.blank?
          next
        end

        row = StdHoliday.new(holiday_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        ctry_cd = attrs[:ctry_cd].to_s.strip.upcase
        ymd = parse_ymd(attrs[:ymd])
        row = StdHoliday.find_by(ctry_cd: ctry_cd, ymd: ymd)
        if row.nil?
          errors << "공휴일 정보를 찾을 수 없습니다: #{ctry_cd}/#{attrs[:ymd]}"
          next
        end

        if row.update(holiday_params_from_row(attrs))
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |key|
        ctry_cd = key[:ctry_cd].to_s.strip.upcase
        ymd = parse_ymd(key[:ymd])
        row = StdHoliday.find_by(ctry_cd: ctry_cd, ymd: ymd)
        if row.nil?
          next
        end

        if row.destroy
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "공휴일 삭제에 실패했습니다: #{ctry_cd}/#{key[:ymd]}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "공휴일 데이터가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_HOLIDAY"
    end

    def search_params
      params.fetch(:q, {}).permit(:ctry_cd, :year, :month)
    end

    def holidays_scope
      scope = StdHoliday.ordered
      if search_ctry_cd.present?
        scope = scope.where(ctry_cd: search_ctry_cd)
      end

      if search_year.present? && search_month.present?
        first_day = Date.new(search_year, search_month, 1)
        last_day = first_day.end_of_month
        scope = scope.where(ymd: first_day..last_day)
      end

      scope
    rescue ArgumentError
      StdHoliday.none
    end

    def search_ctry_cd
      search_params[:ctry_cd].to_s.strip.upcase.presence
    end

    def search_year
      value = search_params[:year].to_i
      if value.positive?
        value
      end
    end

    def search_month
      value = search_params[:month].to_i
      if value.positive?
        value
      end
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [ :ctry_cd, :ymd ],
        rowsToInsert: [
          :ctry_cd, :ymd, :holiday_nm_cd, :sat_yn_cd, :sunday_yn_cd, :clsdy_yn_cd,
          :asmt_holday_yn_cd, :event_day_yn_cd, :rmk_cd, :use_yn_cd
        ],
        rowsToUpdate: [
          :ctry_cd, :ymd, :holiday_nm_cd, :sat_yn_cd, :sunday_yn_cd, :clsdy_yn_cd,
          :asmt_holday_yn_cd, :event_day_yn_cd, :rmk_cd, :use_yn_cd
        ]
      )
    end

    def holiday_params_from_row(row)
      permitted = row.permit(
        :ctry_cd, :ymd, :holiday_nm_cd, :sat_yn_cd, :sunday_yn_cd, :clsdy_yn_cd,
        :asmt_holday_yn_cd, :event_day_yn_cd, :rmk_cd, :use_yn_cd
      ).to_h.symbolize_keys
      permitted[:ymd] = parse_ymd(permitted[:ymd])
      permitted
    end

    def parse_ymd(value)
      if value.is_a?(Date)
        value
      else
        Date.parse(value.to_s)
      end
    end

    def holiday_json(row)
      {
        id: "#{row.ctry_cd}_#{row.ymd}",
        ctry_cd: row.ctry_cd,
        ymd: row.ymd,
        holiday_nm_cd: row.holiday_nm_cd,
        sat_yn_cd: row.sat_yn_cd,
        sunday_yn_cd: row.sunday_yn_cd,
        clsdy_yn_cd: row.clsdy_yn_cd,
        asmt_holday_yn_cd: row.asmt_holday_yn_cd,
        event_day_yn_cd: row.event_day_yn_cd,
        rmk_cd: row.rmk_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
