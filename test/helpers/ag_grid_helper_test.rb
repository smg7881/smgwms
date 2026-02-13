require "test_helper"

class AgGridHelperTest < ActionView::TestCase
  test "ag_grid_tag renders with required attributes" do
    html = ag_grid_tag(
      columns: [ { field: "name" } ],
      url: "/items.json"
    )
    assert_includes html, 'data-controller="ag-grid"'
    assert_includes html, 'data-ag-grid-url-value="/items.json"'
    assert_includes html, 'data-ag-grid-target="grid"'
  end

  test "ag_grid_tag supports inline data" do
    html = ag_grid_tag(
      columns: [ { field: "name" } ],
      row_data: [ { name: "Test" } ]
    )
    assert_includes html, "data-ag-grid-row-data-value"
  end

  test "ag_grid_tag includes formatter key in column values" do
    html = ag_grid_tag(
      columns: [ { field: "price", formatter: "currency" } ],
      url: "/items.json"
    )
    # HTML attributes encode quotes as &quot;
    assert_includes html, "formatter"
    assert_includes html, "currency"
  end

  test "ag_grid_tag sanitizes disallowed column keys" do
    html = ag_grid_tag(
      columns: [ { field: "name", valueFormatter: "evil()", cellRenderer: "xss" } ],
      url: "/items.json"
    )
    assert_not_includes html, "valueFormatter"
    assert_not_includes html, "cellRenderer"
    assert_not_includes html, "evil()"
    assert_not_includes html, "xss"
    # 허용된 키는 유지됨
    assert_includes html, "name"
  end
end
