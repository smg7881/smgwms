require "test_helper"

class Wm::StockMovesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    WmWorkplace.create!(workpl_cd: "WP1", workpl_nm: "센터1", use_yn: "Y")
    WmArea.create!(workpl_cd: "WP1", area_cd: "A01", area_nm: "영역1", use_yn: "Y")
    WmZone.create!(workpl_cd: "WP1", area_cd: "A01", zone_cd: "Z01", zone_nm: "구역1", use_yn: "Y")

    WmLocation.create!(workpl_cd: "WP1", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_FROM", loc_nm: "FROM", use_yn: "Y", has_stock: "Y")
    WmLocation.create!(workpl_cd: "WP1", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_TO", loc_nm: "TO", use_yn: "Y", has_stock: "N")

    Wm::StockAttr.create!(
      stock_attr_no: "SA00000001",
      corp_cd: "C1",
      cust_cd: "CUST1",
      item_cd: "ITEM1",
      stock_attr_col01: "ATTR1"
    )

    Wm::StockAttrLocQty.create!(
      corp_cd: "C1",
      workpl_cd: "WP1",
      stock_attr_no: "SA00000001",
      loc_cd: "L_FROM",
      cust_cd: "CUST1",
      item_cd: "ITEM1",
      basis_unit_cls: "10",
      basis_unit_cd: "EA",
      qty: 100,
      alloc_qty: 10,
      pick_qty: 20,
      hold_qty: 0,
      create_by: "seed",
      create_time: Time.current,
      update_by: "seed",
      update_time: Time.current
    )

    Wm::StockAttrLocQty.create!(
      corp_cd: "C1",
      workpl_cd: "WP1",
      stock_attr_no: "SA00000001",
      loc_cd: "L_TO",
      cust_cd: "CUST1",
      item_cd: "ITEM1",
      basis_unit_cls: "10",
      basis_unit_cd: "EA",
      qty: 5,
      alloc_qty: 0,
      pick_qty: 0,
      hold_qty: 0,
      create_by: "seed",
      create_time: Time.current,
      update_by: "seed",
      update_time: Time.current
    )

    Wm::LocQty.create!(
      corp_cd: "C1",
      workpl_cd: "WP1",
      cust_cd: "CUST1",
      loc_cd: "L_FROM",
      item_cd: "ITEM1",
      basis_unit_cls: "10",
      basis_unit_cd: "EA",
      qty: 100,
      alloc_qty: 0,
      pick_qty: 0,
      hold_qty: 0,
      create_by: "seed",
      create_time: Time.current,
      update_by: "seed",
      update_time: Time.current
    )

    Wm::LocQty.create!(
      corp_cd: "C1",
      workpl_cd: "WP1",
      cust_cd: "CUST1",
      loc_cd: "L_TO",
      item_cd: "ITEM1",
      basis_unit_cls: "10",
      basis_unit_cd: "EA",
      qty: 5,
      alloc_qty: 0,
      pick_qty: 0,
      hold_qty: 0,
      create_by: "seed",
      create_time: Time.current,
      update_by: "seed",
      update_time: Time.current
    )
  end

  test "index responds with stock rows in json" do
    get wm_stock_moves_url(format: :json), params: { q: { workpl_cd: "WP1" } }
    assert_response :success

    rows = JSON.parse(response.body)
    from_row = rows.find { |row| row["loc_cd"] == "L_FROM" }
    assert_not_nil from_row
    assert_equal "SA00000001", from_row["stock_attr_no"]
    assert_equal 70.0, from_row["move_poss_qty"]
  end

  test "move transfers stock and writes movement history" do
    assert_difference "Wm::StockMove.count", 1 do
      post move_wm_stock_moves_url, params: {
        rows: [
          {
            corp_cd: "C1",
            workpl_cd: "WP1",
            cust_cd: "CUST1",
            item_cd: "ITEM1",
            stock_attr_no: "SA00000001",
            loc_cd: "L_FROM",
            to_loc_cd: "L_TO",
            move_qty: 30,
            basis_unit_cls: "10",
            basis_unit_cd: "EA"
          }
        ]
      }, as: :json
    end

    assert_response :success
    assert_equal 70.0, Wm::StockAttrLocQty.find_by!(corp_cd: "C1", workpl_cd: "WP1", stock_attr_no: "SA00000001", loc_cd: "L_FROM").qty.to_f
    assert_equal 35.0, Wm::StockAttrLocQty.find_by!(corp_cd: "C1", workpl_cd: "WP1", stock_attr_no: "SA00000001", loc_cd: "L_TO").qty.to_f
    assert_equal 70.0, Wm::LocQty.find_by!(corp_cd: "C1", workpl_cd: "WP1", cust_cd: "CUST1", loc_cd: "L_FROM", item_cd: "ITEM1").qty.to_f
    assert_equal 35.0, Wm::LocQty.find_by!(corp_cd: "C1", workpl_cd: "WP1", cust_cd: "CUST1", loc_cd: "L_TO", item_cd: "ITEM1").qty.to_f
  end

  test "move rejects quantity larger than available quantity" do
    post move_wm_stock_moves_url, params: {
      rows: [
        {
          corp_cd: "C1",
          workpl_cd: "WP1",
          cust_cd: "CUST1",
          item_cd: "ITEM1",
          stock_attr_no: "SA00000001",
          loc_cd: "L_FROM",
          to_loc_cd: "L_TO",
          move_qty: 80,
          basis_unit_cls: "10",
          basis_unit_cd: "EA"
        }
      ]
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal 100.0, Wm::StockAttrLocQty.find_by!(corp_cd: "C1", workpl_cd: "WP1", stock_attr_no: "SA00000001", loc_cd: "L_FROM").qty.to_f
    assert_equal 5.0, Wm::StockAttrLocQty.find_by!(corp_cd: "C1", workpl_cd: "WP1", stock_attr_no: "SA00000001", loc_cd: "L_TO").qty.to_f
  end

  test "move rejects missing target location" do
    post move_wm_stock_moves_url, params: {
      rows: [
        {
          corp_cd: "C1",
          workpl_cd: "WP1",
          cust_cd: "CUST1",
          item_cd: "ITEM1",
          stock_attr_no: "SA00000001",
          loc_cd: "L_FROM",
          to_loc_cd: "L_UNKNOWN",
          move_qty: 10,
          basis_unit_cls: "10",
          basis_unit_cd: "EA"
        }
      ]
    }, as: :json

    assert_response :unprocessable_entity
  end

  test "non-admin without permission cannot access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    permission = AdmUserMenuPermission.find_or_initialize_by(user: user, menu_cd: "WM_STOCK_MOVE")
    permission.use_yn = "N"
    permission.save!

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_stock_moves_url(format: :json), params: { q: { workpl_cd: "WP1" } }
    assert_response :forbidden
  end

  test "non-admin with permission can access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    permission = AdmUserMenuPermission.find_or_initialize_by(user: user, menu_cd: "WM_STOCK_MOVE")
    permission.use_yn = "Y"
    permission.save!

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_stock_moves_url(format: :json), params: { q: { workpl_cd: "WP1" } }
    assert_response :success
  end
end
