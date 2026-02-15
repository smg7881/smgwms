class Ui::SearchFormComponent < ApplicationComponent
  def initialize(fields:, url:, turbo_frame: "main-content", cols: 3, enable_collapse: true, collapsed_rows: 1, show_buttons: true, **html_options)
    @fields = fields
    @url = url
    @turbo_frame = turbo_frame
    @cols = cols
    @enable_collapse = enable_collapse
    @collapsed_rows = collapsed_rows
    @show_buttons = show_buttons
    @html_options = html_options
  end

  def call
    helpers.search_form_tag(
      fields: @fields,
      url: @url,
      turbo_frame: @turbo_frame,
      cols: @cols,
      enable_collapse: @enable_collapse,
      collapsed_rows: @collapsed_rows,
      show_buttons: @show_buttons,
      **@html_options
    )
  end
end
