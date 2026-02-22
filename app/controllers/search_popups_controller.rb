require "set"

class SearchPopupsController < ApplicationController
  def show
    @type = params[:type].to_s.strip.downcase
    @frame = params[:frame].presence || "search_popup_frame"
    @keyword = lookup_keyword
    @rows = lookup_rows(@type, @keyword)
    @popup_form = SearchPopupForm.new(
      display: @keyword,
      code: params.dig(:search_popup_form, :code).to_s.strip.upcase
    )

    respond_to do |format|
      format.json do
        render json: @rows.map do |row|
          {
            code: row[:code],
            name: row[:name],
            display: row[:display]
          }
        end
      end
      format.html { render layout: popup_layout? }
    end
  end

  private
    def lookup_keyword
      direct = params[:q].to_s.strip
      if direct.present?
        direct
      else
        params.dig(:search_popup_form, :display).to_s.strip
      end
    end

    def popup_layout?
      if turbo_frame_request? || params[:frame].present?
        false
      else
        "application"
      end
    end

    def lookup_rows(type, keyword)
      rows = case type
      when "corp"
        corp_rows
      when "region", "regn"
        region_rows
      when "country", "ctry"
        country_rows
      when "client", "bzac"
        client_rows
      when "menu"
        menu_rows
      when "user"
        user_rows
      when "workplace"
        workplace_rows
      else
        []
      end

      return rows.first(200) if keyword.blank?

      up_keyword = keyword.upcase
      rows.select do |row|
        row[:code].to_s.upcase.include?(up_keyword) ||
          row[:name].to_s.upcase.include?(up_keyword) ||
          row[:display].to_s.upcase.include?(up_keyword)
      end.first(200)
    end

    def build_row(code:, name:)
      normalized_code = code.to_s.strip.upcase
      normalized_name = name.to_s.strip
      return nil if normalized_code.blank?

      resolved_name = normalized_name.presence || normalized_code
      {
        code: normalized_code,
        name: resolved_name,
        display: resolved_name
      }
    end

    def corp_rows
      rows = []
      code_set = Set.new

      if defined?(StdCorporation) && StdCorporation.table_exists?
        StdCorporation.ordered.each do |corp|
          row = build_row(code: corp.corp_cd, name: corp.corp_nm)
          next unless row

          code_set << row[:code]
          rows << row
        end
      end

      if defined?(StdWorkplace) && StdWorkplace.table_exists?
        StdWorkplace.distinct.pluck(:corp_cd).each do |code|
          normalized = code.to_s.strip.upcase
          code_set << normalized if normalized.present?
        end
      end

      if defined?(StdRegion) && StdRegion.table_exists?
        StdRegion.distinct.pluck(:corp_cd).each do |code|
          normalized = code.to_s.strip.upcase
          code_set << normalized if normalized.present?
        end
      end

      if code_set.empty?
        code_set << "DEFAULT"
      end

      extra_rows = code_set.to_a.sort.filter_map do |code|
        next if rows.any? { |row| row[:code] == code }

        build_row(code: code, name: code)
      end

      rows + extra_rows
    rescue ActiveRecord::StatementInvalid
      []
    end

    def region_rows
      return [] unless defined?(StdRegion) && StdRegion.table_exists?

      StdRegion.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_row(code: row.regn_cd, name: row.regn_nm_cd)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def country_rows
      return [] unless defined?(StdCountry) && StdCountry.table_exists?

      StdCountry.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_row(code: row.ctry_cd, name: row.ctry_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def client_rows
      return [] unless defined?(StdBzacMst) && StdBzacMst.table_exists?

      StdBzacMst.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_row(code: row.bzac_cd, name: row.bzac_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def menu_rows
      return [] unless defined?(AdmMenu) && AdmMenu.table_exists?

      AdmMenu.active.where(menu_type: "MENU").ordered.filter_map do |row|
        build_row(code: row.menu_cd, name: row.menu_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def user_rows
      return [] unless defined?(User) && User.table_exists?

      User.ordered.filter_map do |row|
        build_row(code: row.user_id_code, name: row.user_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def workplace_rows
      return [] unless defined?(StdWorkplace) && StdWorkplace.table_exists?

      StdWorkplace.where(use_yn_cd: "Y").ordered.filter_map do |row|
        build_row(code: row.workpl_cd, name: row.workpl_nm)
      end
    rescue ActiveRecord::StatementInvalid
      []
    end
end
