class TabsController < ApplicationController
  def create
    tab_id = tab_params[:id].to_s
    label = tab_params[:label].to_s
    url = tab_params[:url].to_s
    if tab_id.blank? || label.blank? || url.blank?
      head :unprocessable_entity
      return
    end

    entry = TabRegistry.find(tab_id)
    effective_label = entry&.label || label
    effective_url = entry&.url || url

    unless open_tabs.any? { |t| t["id"] == tab_id }
      open_tabs << { "id" => tab_id, "label" => effective_label, "url" => effective_url }
    end
    session[:active_tab] = tab_id
    record_menu_access(tab_id: tab_id, label: effective_label, url: effective_url)

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to effective_url }
    end
  end

  def destroy
    tab_id = params[:id]

    if tab_id == "overview"
      head :unprocessable_entity
      return
    end

    open_tabs.reject! { |t| t["id"] == tab_id }

    if session[:active_tab] == tab_id
      session[:active_tab] = open_tabs.last&.dig("id") || "overview"
    end

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to TabRegistry.url_for(session[:active_tab]) || root_path }
    end
  end

  private
    def open_tabs
      session[:open_tabs]
    end

    def tab_params
      params.require(:tab).permit(:id, :label, :url)
    end

    def render_tab_update
      active_id    = session[:active_tab]
      active_tab = open_tabs.find { |t| t["id"] == active_id }
      active_url = active_tab&.dig("url") || TabRegistry.url_for(active_id) || "/"
      active_label = active_tab&.dig("label") || TabRegistry.find(active_id)&.label || "개요"

      render turbo_stream: [
        turbo_stream.update("tab-bar",
          partial: "shared/tab_bar",
          locals: { tabs: open_tabs, active: active_id }
        ),
        turbo_stream.update("breadcrumb-current", active_label),
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

    def record_menu_access(tab_id:, label:, url:)
      if tab_id == "overview"
        return
      end

      AdmMenuLog.record_access(
        user: Current.user,
        request: request,
        menu_id: tab_id,
        menu_name: label,
        menu_path: url,
        session_token: Current.session&.token
      )
    end
end
