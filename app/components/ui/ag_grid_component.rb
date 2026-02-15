class Ui::AgGridComponent < ApplicationComponent
  def initialize(columns:, url: nil, row_data: nil, pagination: true, page_size: 20, height: "500px", row_selection: nil, **html_options)
    @columns = columns
    @url = url
    @row_data = row_data
    @pagination = pagination
    @page_size = page_size
    @height = height
    @row_selection = row_selection
    @html_options = html_options
  end

  def call
    helpers.ag_grid_tag(
      columns: @columns,
      url: @url,
      row_data: @row_data,
      pagination: @pagination,
      page_size: @page_size,
      height: @height,
      row_selection: @row_selection,
      **@html_options
    )
  end
end
