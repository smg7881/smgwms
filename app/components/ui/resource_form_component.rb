class Ui::ResourceFormComponent < ApplicationComponent
  def initialize(model:, fields:, url: nil, cols: 3, show_buttons: true, submit_label: "저장", cancel_url: nil, form_data: {}, form_html: {}, target_controller: nil, **html_options)
    @model = model
    @fields = fields
    @url = url
    @cols = cols
    @show_buttons = show_buttons
    @submit_label = submit_label
    @cancel_url = cancel_url
    @form_data = form_data
    @form_html = form_html
    @target_controller = target_controller
    @html_options = html_options
  end

  def call
    helpers.resource_form_tag(
      model: @model,
      fields: @fields,
      url: @url,
      cols: @cols,
      show_buttons: @show_buttons,
      submit_label: @submit_label,
      cancel_url: @cancel_url,
      form_data: @form_data,
      form_html: @form_html,
      target_controller: @target_controller,
      **@html_options
    )
  end
end
