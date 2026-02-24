class Ui::GridHeaderComponent < ApplicationComponent
  renders_one :subtitle
  renders_one :inline_subtitle
  renders_one :actions

  def initialize(icon:, title:, grid_id:, excel_action: nil, buttons: [], class: nil, title_class: nil, icon_class: nil)
    @icon = icon
    @title = title
    @grid_id = grid_id
    @excel_action = excel_action
    @buttons = buttons
    @custom_class = binding.local_variable_get(:class)
    @title_class = title_class
    @icon_class = icon_class
  end

  private
    attr_reader :icon, :title, :grid_id, :excel_action, :buttons,
                :custom_class, :title_class, :icon_class

    def wrapper_class
      custom_class || "flex items-center justify-between gap-3 mb-3 mt-2"
    end

    def resolved_title_class
      title_class || "inline-flex items-center gap-2 text-[15px] font-semibold text-text-primary whitespace-nowrap shrink-0"
    end

    def resolved_icon_class
      icon_class || "w-4 h-4 text-text-secondary"
    end

    def render_toolbar?
      buttons.present? || actions?
    end
end
