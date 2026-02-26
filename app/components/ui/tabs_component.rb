# frozen_string_literal: true

module Ui
  class TabsComponent < ViewComponent::Base
    def initialize(tabs:, target_controller:, active_tab: nil, action: "switchTab", target_name: "tabButton", container_class: "std-client-tabs", tab_class: "std-client-tab")
      @tabs = tabs
      @target_controller = target_controller
      @active_tab = active_tab || tabs.first&.dig(:id)
      @action = action
      @target_name = target_name
      @container_class = container_class
      @tab_class = tab_class
    end
  end
end
