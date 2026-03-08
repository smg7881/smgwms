module Wm
  # 작업장 > AREA > ZONE 연계형 SELECT 옵션을 제공하는 공통 Concern.
  # 동일 패턴이 필요한 PageComponent에서 include 하여 사용합니다.
  #
  # 사용법
  #   class Wm::SomePage::PageComponent < Wm::BasePageComponent
  #     include Wm::CascadingWorkplaceSelect
  #     ...
  #     def search_fields
  #       [
  #         { field: "workpl_cd", type: "select", label: "작업장", options: workplace_search_options, include_blank: false },
  #         { field: "area_cd",   type: "select", label: "AREA", options: area_search_options },
  #         { field: "zone_cd",   type: "select", label: "ZONE", options: zone_search_options }
  #       ]
  #     end
  #   end
  module CascadingWorkplaceSelect
    def workplace_search_options
      workplace_records.map do |workplace|
        { label: "#{workplace.workpl_cd} - #{workplace.workpl_nm}", value: workplace.workpl_cd }
      end
    end

    def area_search_options
      options = [{ label: "전체", value: "" }]
      return options if selected_workpl_cd.blank?

      options + WmArea.where(workpl_cd: selected_workpl_cd, use_yn: "Y").ordered.map do |area|
        { label: "#{area.area_cd} - #{area.area_nm}", value: area.area_cd }
      end
    end

    def zone_search_options
      options = [{ label: "전체", value: "" }]
      return options if selected_workpl_cd.blank? || selected_area_cd.blank?

      options + WmZone.where(workpl_cd: selected_workpl_cd, area_cd: selected_area_cd, use_yn: "Y").ordered.map do |zone|
        { label: "#{zone.zone_cd} - #{zone.zone_nm}", value: zone.zone_cd }
      end
    end

    def selected_workpl_cd
      @selected_workpl_cd ||= begin
        value = query_params.dig("q", "workpl_cd").to_s.strip.upcase
        value.presence || workplace_records.first&.workpl_cd
      end
    end

    def selected_area_cd
      @selected_area_cd ||= query_params.dig("q", "area_cd").to_s.strip.upcase.presence
    end

    def selected_zone_cd
      @selected_zone_cd ||= query_params.dig("q", "zone_cd").to_s.strip.upcase.presence
    end

    private
      def workplace_records
        @workplace_records ||= WmWorkplace.where(use_yn: "Y").ordered.to_a
      end
  end
end
