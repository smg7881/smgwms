require "test_helper"

class Std::InterfaceInfosControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdInterfaceInfo.create!(
      corp_cd: "CP01",
      if_cd: "V0000000001",
      if_meth_cd: "API",
      if_sctn_cd: "INTERNAL",
      if_nm_cd: "IF A",
      send_sys_cd: "WMS",
      rcv_sys_cd: "ERP",
      use_yn_cd: "Y"
    )

    get std_interface_infos_url
    assert_response :success

    get std_interface_infos_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["if_cd"] == "V0000000001" }
  end

  test "batch_save validates internal interface required fields" do
    post batch_save_std_interface_infos_url, params: {
      rowsToInsert: [
        {
          corp_cd: "CP01",
          if_meth_cd: "API",
          if_sctn_cd: "INTERNAL",
          if_nm_cd: "IF INVALID",
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body["errors"].join(" ").present?
  end

  test "batch_save inserts update and soft delete" do
    StdInterfaceInfo.create!(
      corp_cd: "CP01",
      if_cd: "V0000000002",
      if_meth_cd: "API",
      if_sctn_cd: "INTERNAL",
      if_nm_cd: "Before",
      send_sys_cd: "WMS",
      rcv_sys_cd: "ERP",
      use_yn_cd: "Y"
    )

    post batch_save_std_interface_infos_url, params: {
      rowsToInsert: [
        {
          corp_cd: "CP01",
          if_meth_cd: "FILE",
          if_sctn_cd: "EXTERNAL",
          if_nm_cd: "New IF",
          if_bzac_cd: "BZ01",
          bzac_sys_nm_cd: "EXT",
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          corp_cd: "CP01",
          if_cd: "V0000000002",
          if_meth_cd: "API",
          if_sctn_cd: "INTERNAL",
          if_nm_cd: "After",
          send_sys_cd: "WMS",
          rcv_sys_cd: "ERP",
          use_yn_cd: "Y"
        }
      ],
      rowsToDelete: ["V0000000002"]
    }, as: :json

    assert_response :success
    assert_equal "N", StdInterfaceInfo.find_by!(if_cd: "V0000000002").use_yn_cd
    assert StdInterfaceInfo.exists?(if_nm_cd: "New IF")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_INTERFACE_INFO").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_interface_infos_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_INTERFACE_INFO", use_yn: "Y")
    get std_interface_infos_url(format: :json)
    assert_response :success
  end
end
