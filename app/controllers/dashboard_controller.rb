class DashboardController < ApplicationController
  def show
    @active_content_url = active_content_url
    if @active_content_url.present?
      return
    end

    @total_notices      = AdmNotice.count
    @notices_today      = AdmNotice.where(create_time: Time.current.beginning_of_day..).count
    @notices_this_week  = AdmNotice.where(create_time: Time.current.beginning_of_week..).count
    @notices_this_month = AdmNotice.where(create_time: Time.current.beginning_of_month..).count
    @recent_notices     = AdmNotice.ordered.limit(5)

    last_week_count   = AdmNotice.where(create_time: 1.week.ago.beginning_of_week...Time.current.beginning_of_week).count
    if last_week_count > 0
      @week_change_pct = ((@notices_this_week - last_week_count).to_f / last_week_count * 100).round(1)
    else
      @week_change_pct = nil
    end
  end

  private
    def active_content_url
      active_id = session[:active_tab].to_s
      if active_id.blank? || active_id == "overview"
        return nil
      end

      active_tab = (session[:open_tabs] || []).find { |tab| tab["id"] == active_id }
      url = active_tab&.dig("url").presence || TabRegistry.url_for(active_id)
      url.presence
    end
end
