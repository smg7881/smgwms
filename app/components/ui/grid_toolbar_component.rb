class Ui::GridToolbarComponent < ApplicationComponent
  def initialize(buttons:)
    @buttons = buttons
  end

  private
    attr_reader :buttons
end
