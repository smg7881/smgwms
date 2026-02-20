class Tabs::ActivationsController < ApplicationController
  def create
    tab_id = params[:tab_id]

    unless open_tabs.any? { |t| t["id"] == tab_id }
      head :not_found
      return
    end

    session[:active_tab] = tab_id
    active_tab = open_tabs.find { |t| t["id"] == tab_id }
    record_menu_access(tab_id: tab_id, tab: active_tab)

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to TabRegistry.url_for(tab_id) || root_path }
    end
  end

  private
    def open_tabs
      session[:open_tabs]
    end

    def render_tab_update
      active_id    = session[:active_tab]
      active_tab = open_tabs.find { |t| t["id"] == active_id }
      active_url = active_tab&.dig("url") || TabRegistry.url_for(active_id) || "/"

      render turbo_stream: [
        turbo_stream.update("tab-bar",
          partial: "shared/tab_bar",
          locals: { tabs: open_tabs, active: active_id }
        ),
        turbo_stream.replace("main-content",
          helpers.turbo_frame_tag("main-content", src: active_url, loading: :eager) {
            helpers.content_tag(:div, class: "loading-state") {
              helpers.content_tag(:div, "", class: "spinner") +
              helpers.content_tag(:span, "로딩 중...")
            }
          }
        )
      ]
    end

    def record_menu_access(tab_id:, tab:)
      if tab_id == "overview" || tab.blank?
        return
      end

      AdmMenuLog.record_access(
        user: Current.user,
        request: request,
        menu_id: tab_id,
        menu_name: tab["label"],
        menu_path: tab["url"],
        session_token: Current.session&.token
      )
    end
end
