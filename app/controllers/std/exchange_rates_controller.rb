class Std::ExchangeRatesController < Std::BaseController
  def index
    if request.format.html? && params[:q].blank?
      redirect_to std_exchange_rates_path(q: default_search_query) and return
    end

    respond_to do |format|
      format.html
      format.json { render json: exchange_rates_scope.map { |row| exchange_rate_json(row) } }
    end
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if attrs[:mon_cd].to_s.strip.blank?
          next
        end

        row = StdExchangeRate.new(exchange_rate_params_from_row(attrs))
        if row.save
          result[:inserted] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        row = find_exchange_rate_row(attrs)
        if row.nil?
          errors << "Exchange rate row not found: #{exchange_rate_key(attrs)}"
          next
        end

        update_attrs = exchange_rate_params_from_row(attrs)
        update_attrs.delete(:ctry_cd)
        update_attrs.delete(:fnc_or_cd)
        update_attrs.delete(:std_ymd)
        update_attrs.delete(:anno_dgrcnt)
        update_attrs.delete(:mon_cd)

        if row.update(update_attrs)
          result[:updated] += 1
        else
          errors.concat(row.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |attrs|
        row = find_exchange_rate_row(attrs)
        if row.nil?
          next
        end

        if row.update(use_yn_cd: "N")
          result[:deleted] += 1
        else
          errors.concat(row.errors.full_messages.presence || [ "Exchange rate deactivation failed: #{exchange_rate_key(attrs)}" ])
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "Exchange rate data saved.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "STD_EXCHANGE_RATE"
    end

    def search_params
      params.fetch(:q, {}).permit(:ctry_cd, :fnc_or_cd, :std_ymd, :anno_dgrcnt, :use_yn_cd)
    end

    def default_search_query
      {
        ctry_cd: default_country_code,
        std_ymd: Date.yesterday.iso8601,
        anno_dgrcnt: "FIRST"
      }
    end

    def default_country_code
      "KR"
    end

    def exchange_rates_scope
      scope = StdExchangeRate.ordered
      if search_ctry_cd.present?
        scope = scope.where(ctry_cd: search_ctry_cd)
      end
      if search_fnc_or_cd.present?
        scope = scope.where(fnc_or_cd: search_fnc_or_cd)
      end
      if search_std_ymd.present?
        scope = scope.where(std_ymd: search_std_ymd)
      end
      if search_anno_dgrcnt.present?
        scope = scope.where(anno_dgrcnt: search_anno_dgrcnt)
      end
      if search_use_yn_cd.present?
        scope = scope.where(use_yn_cd: search_use_yn_cd)
      end
      scope
    end

    def search_ctry_cd
      search_params[:ctry_cd].to_s.strip.upcase.presence
    end

    def search_fnc_or_cd
      search_params[:fnc_or_cd].to_s.strip.upcase.presence
    end

    def search_std_ymd
      value = search_params[:std_ymd].to_s.strip
      if value.blank?
        nil
      else
        Date.parse(value)
      end
    rescue ArgumentError
      nil
    end

    def search_anno_dgrcnt
      search_params[:anno_dgrcnt].to_s.strip.upcase.presence
    end

    def search_use_yn_cd
      search_params[:use_yn_cd].to_s.strip.upcase.presence
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [ :ctry_cd, :fnc_or_cd, :std_ymd, :anno_dgrcnt, :mon_cd ],
        rowsToInsert: [
          :ctry_cd, :fnc_or_cd, :std_ymd, :anno_dgrcnt, :mon_cd, :cash_buy, :cash_sell,
          :sendmoney_sndg, :sendmoney_rcvng, :tc_buy, :fcur_check_sell, :tradg_std_rt,
          :convmoney_rt, :usd_conv_rt, :if_yn_cd, :use_yn_cd
        ],
        rowsToUpdate: [
          :ctry_cd, :fnc_or_cd, :std_ymd, :anno_dgrcnt, :mon_cd, :cash_buy, :cash_sell,
          :sendmoney_sndg, :sendmoney_rcvng, :tc_buy, :fcur_check_sell, :tradg_std_rt,
          :convmoney_rt, :usd_conv_rt, :if_yn_cd, :use_yn_cd
        ]
      )
    end

    def exchange_rate_params_from_row(row)
      row.permit(
        :ctry_cd, :fnc_or_cd, :std_ymd, :anno_dgrcnt, :mon_cd, :cash_buy, :cash_sell,
        :sendmoney_sndg, :sendmoney_rcvng, :tc_buy, :fcur_check_sell, :tradg_std_rt,
        :convmoney_rt, :usd_conv_rt, :if_yn_cd, :use_yn_cd
      ).to_h.symbolize_keys
    end

    def find_exchange_rate_row(attrs)
      ctry_cd = attrs[:ctry_cd].to_s.strip.upcase
      fnc_or_cd = attrs[:fnc_or_cd].to_s.strip.upcase
      std_ymd = parse_date(attrs[:std_ymd])
      anno_dgrcnt = attrs[:anno_dgrcnt].to_s.strip.upcase
      mon_cd = attrs[:mon_cd].to_s.strip.upcase

      if ctry_cd.blank? || fnc_or_cd.blank? || std_ymd.blank? || anno_dgrcnt.blank? || mon_cd.blank?
        return nil
      end

      StdExchangeRate.find_by(
        ctry_cd: ctry_cd,
        fnc_or_cd: fnc_or_cd,
        std_ymd: std_ymd,
        anno_dgrcnt: anno_dgrcnt,
        mon_cd: mon_cd
      )
    end

    def exchange_rate_key(attrs)
      [
        attrs[:ctry_cd],
        attrs[:fnc_or_cd],
        attrs[:std_ymd],
        attrs[:anno_dgrcnt],
        attrs[:mon_cd]
      ].join("/")
    end

    def parse_date(value)
      source = value.to_s.strip
      if source.blank?
        nil
      else
        Date.parse(source)
      end
    rescue ArgumentError
      nil
    end

    def exchange_rate_json(row)
      {
        id: "#{row.ctry_cd}::#{row.fnc_or_cd}::#{row.std_ymd}::#{row.anno_dgrcnt}::#{row.mon_cd}",
        ctry_cd: row.ctry_cd,
        fnc_or_cd: row.fnc_or_cd,
        std_ymd: row.std_ymd,
        anno_dgrcnt: row.anno_dgrcnt,
        mon_cd: row.mon_cd,
        cash_buy: row.cash_buy,
        cash_sell: row.cash_sell,
        sendmoney_sndg: row.sendmoney_sndg,
        sendmoney_rcvng: row.sendmoney_rcvng,
        tc_buy: row.tc_buy,
        fcur_check_sell: row.fcur_check_sell,
        tradg_std_rt: row.tradg_std_rt,
        convmoney_rt: row.convmoney_rt,
        usd_conv_rt: row.usd_conv_rt,
        if_yn_cd: row.if_yn_cd,
        use_yn_cd: row.use_yn_cd,
        create_by: row.create_by,
        create_time: row.create_time,
        update_by: row.update_by,
        update_time: row.update_time
      }
    end
end
