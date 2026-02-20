class Ui::ModalShellComponent < ApplicationComponent
  renders_one :body

  def initialize(controller:, title:, overlay_click_action: nil,
                 cancel_text: "취소", save_text: "저장",
                 save_form_id:, cancel_role: nil, save_role: nil,
                 width: "480px", height: nil)
    @controller = controller
    @title = title
    @overlay_click_action = overlay_click_action
    @cancel_text = cancel_text
    @save_text = save_text
    @save_form_id = save_form_id
    @cancel_role = cancel_role
    @save_role = save_role
    @width = width
    @height = height
  end

  private
    attr_reader :controller, :title, :overlay_click_action,
                :cancel_text, :save_text, :save_form_id, :cancel_role, :save_role,
                :width, :height

    def overlay_action_attr
      return nil if overlay_click_action.blank?

      %(data-action="#{overlay_click_action}")
    end

    def cancel_role_attr
      return nil if cancel_role.blank?

      %(data-#{controller}-role="#{cancel_role}")
    end

    def save_role_attr
      return nil if save_role.blank?

      %(data-#{controller}-role="#{save_role}")
    end

    def modal_style
      declarations = []
      declarations << "width: #{width};" if width.present?
      if height.present?
        declarations << "height: #{height};"
        declarations << "max-height: #{height};"
      end
      declarations.join(" ")
    end
end
