require "test_helper"

class Ui::AgGridComponentTest < ViewComponent::TestCase
  test "renders with required attributes" do
    render_inline(Ui::AgGridComponent.new(
      columns: [ { field: "name" } ],
      url: "/items.json"
    ))

    assert_selector '[data-controller="ag-grid"]'
    assert_selector '[data-ag-grid-url-value="/items.json"]'
    assert_selector "[data-ag-grid-target='grid']"
  end

  test "supports inline row data" do
    render_inline(Ui::AgGridComponent.new(
      columns: [ { field: "name" } ],
      row_data: [ { name: "Test" } ]
    ))

    assert_selector "[data-ag-grid-row-data-value]"
  end

  test "includes formatter key in column values" do
    render_inline(Ui::AgGridComponent.new(
      columns: [ { field: "price", formatter: "currency" } ],
      url: "/items.json"
    ))

    html = rendered_content
    assert_includes html, "formatter"
    assert_includes html, "currency"
  end

  test "sanitizes disallowed column keys" do
    render_inline(Ui::AgGridComponent.new(
      columns: [ { field: "name", valueFormatter: "evil()", cellRenderer: "link" } ],
      url: "/items.json"
    ))

    html = rendered_content
    assert_not_includes html, "valueFormatter"
    assert_not_includes html, "evil()"
    assert_includes html, "cellRenderer"
    assert_includes html, "link"
    assert_includes html, "name"
  end

  test "merges custom data attributes" do
    render_inline(Ui::AgGridComponent.new(
      columns: [ { field: "name" } ],
      url: "/items.json",
      data: { my_target: "grid" }
    ))

    assert_selector "[data-my-target='grid']"
    assert_selector '[data-controller="ag-grid"]'
  end

  test "applies default values" do
    render_inline(Ui::AgGridComponent.new(
      columns: [ { field: "name" } ],
      url: "/items.json"
    ))

    assert_selector '[data-ag-grid-pagination-value="true"]'
    assert_selector '[data-ag-grid-page-size-value="20"]'
    assert_selector '[data-ag-grid-height-value="500px"]'
  end
end
