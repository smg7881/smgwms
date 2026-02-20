class TabsController < ApplicationController
  MAX_OPEN_TABS = 10

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
      if tab_limit_reached?
        head :unprocessable_entity
        return
      end

      open_tabs << { "id" => tab_id, "label" => effective_label, "url" => effective_url }
      session[:open_tabs] = open_tabs
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
    session[:open_tabs] = open_tabs

    if session[:active_tab] == tab_id
      session[:active_tab] = open_tabs.last&.dig("id") || "overview"
    end

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to TabRegistry.url_for(session[:active_tab]) || root_path }
    end
  end

  def close_all
    open_tabs.select! { |tab| tab["id"] == "overview" }
    session[:open_tabs] = open_tabs
    session[:active_tab] = "overview"

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to root_path }
    end
  end

  def close_others
    tab_id = params[:id].presence || session[:active_tab].to_s

    unless open_tabs.any? { |tab| tab["id"] == tab_id }
      head :unprocessable_entity
      return
    end

    open_tabs.select! { |tab| tab["id"] == "overview" || tab["id"] == tab_id }
    session[:open_tabs] = open_tabs
    session[:active_tab] = tab_id

    respond_to do |format|
      format.turbo_stream { render_tab_update }
      format.html { redirect_to TabRegistry.url_for(tab_id) || root_path }
    end
  end

  def move_left
    move_tab!(:left)
  end

  def move_right
    move_tab!(:right)
  end

  private
    def open_tabs
      session[:open_tabs] ||= []
    end

    def tab_params
      params.require(:tab).permit(:id, :label, :url)
    end

    def render_tab_update
      active_id    = session[:active_tab]
      active_tab = open_tabs.find { |t| t["id"] == active_id }
      active_url = active_tab&.dig("url") || TabRegistry.url_for(active_id) || "/"
      active_label = active_tab&.dig("label") || TabRegistry.find(active_id)&.label || "대시보드"

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

    def move_tab!(direction)
      tab_id = params[:id].to_s
      if tab_id == "overview"
        head :unprocessable_entity
        return
      end

      index = open_tabs.find_index { |tab| tab["id"] == tab_id }
      if index.nil?
        head :not_found
        return
      end

      if direction == :left && index <= 1
        head :unprocessable_entity
        return
      end

      target_index = direction == :left ? index - 1 : index + 1
      if direction == :right && target_index >= open_tabs.size
        head :unprocessable_entity
        return
      end

      open_tabs[index], open_tabs[target_index] = open_tabs[target_index], open_tabs[index]
      session[:open_tabs] = open_tabs

      respond_to do |format|
        format.turbo_stream { render_tab_update }
        format.html { redirect_to TabRegistry.url_for(session[:active_tab]) || root_path }
      end
    end

    def tab_limit_reached?
      open_tabs.size >= MAX_OPEN_TABS
    end
end
