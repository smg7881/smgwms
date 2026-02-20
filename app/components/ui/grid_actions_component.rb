class Ui::GridActionsComponent < ApplicationComponent
  def initialize(grid_id:, excel_action: nil)
    @grid_id = grid_id
    @excel_action = excel_action
  end

  private
    attr_reader :grid_id, :excel_action

    def csv_fallback_action
      "click->grid-actions#exportCsv"
    end

    def resolved_excel_action
      excel_action.presence || csv_fallback_action
    end
end
