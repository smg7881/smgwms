require "set"

class SearchPopupsController < ApplicationController
  def show
    @type = params[:type].to_s.strip.downcase
    @keyword = params[:q].to_s.strip
    @rows = lookup_rows(@type, @keyword)

    respond_to do |format|
      format.json { render json: @rows.map { |row| { code: row[:code], display: row[:display] } } }
      format.html { render layout: popup_layout? }
    end
  end

  private
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
      when "menu"
        menu_rows
      when "user"
        user_rows
      when "workplace"
        workplace_rows
      else
        []
      end

      if keyword.blank?
        rows.first(200)
      else
        up_keyword = keyword.upcase
        rows.select do |row|
          row[:code].to_s.upcase.include?(up_keyword) || row[:display].to_s.upcase.include?(up_keyword)
        end.first(200)
      end
    end

    def corp_rows
      code_set = Set.new

      if defined?(StdWorkplace) && StdWorkplace.table_exists?
        StdWorkplace.distinct.pluck(:corp_cd).each do |code|
          normalized = code.to_s.strip.upcase
          if normalized.present?
            code_set << normalized
          end
        end
      end

      if defined?(StdRegion) && StdRegion.table_exists?
        StdRegion.distinct.pluck(:corp_cd).each do |code|
          normalized = code.to_s.strip.upcase
          if normalized.present?
            code_set << normalized
          end
        end
      end

      if code_set.empty?
        code_set << "DEFAULT"
      end

      code_set.to_a.sort.map do |code|
        {
          code: code,
          display: code
        }
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def region_rows
      if defined?(StdRegion) && StdRegion.table_exists?
        StdRegion.where(use_yn_cd: "Y").ordered.map do |row|
          {
            code: row.regn_cd,
            display: "#{row.regn_nm_cd} (#{row.regn_cd})"
          }
        end
      else
        []
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def country_rows
      if defined?(StdCountry) && StdCountry.table_exists?
        StdCountry.where(use_yn_cd: "Y").ordered.map do |row|
          {
            code: row.ctry_cd,
            display: "#{row.ctry_nm} (#{row.ctry_cd})"
          }
        end
      else
        []
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def menu_rows
      if defined?(AdmMenu) && AdmMenu.table_exists?
        AdmMenu.active.where(menu_type: "MENU").ordered.map do |row|
          {
            code: row.menu_cd,
            display: "#{row.menu_nm} (#{row.menu_cd})"
          }
        end
      else
        []
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def user_rows
      if defined?(User) && User.table_exists?
        User.ordered.map do |row|
          code = row.user_id_code.to_s.strip.upcase
          if code.blank?
            nil
          else
            {
              code: code,
              display: "#{row.user_nm} (#{code})"
            }
          end
        end.compact
      else
        []
      end
    rescue ActiveRecord::StatementInvalid
      []
    end

    def workplace_rows
      if defined?(StdWorkplace) && StdWorkplace.table_exists?
        StdWorkplace.where(use_yn_cd: "Y").ordered.map do |row|
          {
            code: row.workpl_cd,
            display: "#{row.workpl_nm} (#{row.workpl_cd})"
          }
        end
      else
        []
      end
    rescue ActiveRecord::StatementInvalid
      []
    end
end
