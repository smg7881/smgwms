require "test_helper"

class Std::WorkRoutingStepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    StdWorkRoutingStep.delete_all
    StdWorkRouting.delete_all
  end

  test "index responds to html and json" do
    StdWorkRouting.create!(
      wrk_rt_cd: "00001",
      wrk_rt_nm: "벌크수입본선당사",
      hwajong_cd: "20",
      wrk_type1_cd: "20",
      wrk_type2_cd: "10",
      use_yn_cd: "Y"
    )

    get std_work_routing_steps_url
    assert_response :success

    get std_work_routing_steps_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["wrk_rt_cd"] == "00001" }
  end

  test "batch_save inserts updates and soft deletes" do
    StdWorkRouting.create!(
      wrk_rt_cd: "00010",
      wrk_rt_nm: "Before",
      hwajong_cd: "10",
      wrk_type1_cd: "10",
      wrk_type2_cd: "10",
      use_yn_cd: "Y"
    )
    deleted_row = StdWorkRouting.create!(
      wrk_rt_cd: "00011",
      wrk_rt_nm: "Delete",
      hwajong_cd: "10",
      wrk_type1_cd: "10",
      wrk_type2_cd: "10",
      use_yn_cd: "Y"
    )
    StdWorkRoutingStep.create!(
      wrk_rt_cd: deleted_row.wrk_rt_cd,
      seq_no: 1,
      work_step_cd: "10",
      work_step_level1_cd: "10",
      work_step_level2_cd: "10",
      use_yn_cd: "Y"
    )

    post batch_save_std_work_routing_steps_url, params: {
      rowsToInsert: [
        {
          wrk_rt_cd: "00012",
          wrk_rt_nm: "Inserted",
          hwajong_cd: "20",
          wrk_type1_cd: "30",
          wrk_type2_cd: "20",
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          wrk_rt_cd: "00010",
          wrk_rt_nm: "After",
          hwajong_cd: "10",
          wrk_type1_cd: "20",
          wrk_type2_cd: "30",
          use_yn_cd: "Y"
        }
      ],
      rowsToDelete: [ "00011" ]
    }, as: :json

    assert_response :success
    assert_equal "After", StdWorkRouting.find_by!(wrk_rt_cd: "00010").wrk_rt_nm
    assert_equal "N", StdWorkRouting.find_by!(wrk_rt_cd: "00011").use_yn_cd
    assert_equal "N", StdWorkRoutingStep.find_by!(wrk_rt_cd: "00011", seq_no: 1).use_yn_cd
    assert StdWorkRouting.exists?(wrk_rt_cd: "00012")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_WRK_RTING_STEP").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_work_routing_steps_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_WRK_RTING_STEP", use_yn: "Y")
    get std_work_routing_steps_url(format: :json)
    assert_response :success
  end
end
