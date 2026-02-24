class Ui::GridToolbarComponent < ApplicationComponent
  renders_one :left
  renders_one :right

  def initialize(buttons: [])
    @buttons = buttons
  end

  private
    attr_reader :buttons
end
