require "test_helper"

class Std::WorkRoutingStepDetailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    StdWorkRoutingStep.delete_all
    StdWorkRouting.delete_all
    @work_routing = StdWorkRouting.create!(
      wrk_rt_cd: "00001",
      wrk_rt_nm: "벌크수입본선당사",
      hwajong_cd: "20",
      wrk_type1_cd: "20",
      wrk_type2_cd: "10",
      use_yn_cd: "Y"
    )
  end

  test "index responds to json" do
    get std_work_routing_step_details_url(@work_routing.wrk_rt_cd, format: :json)
    assert_response :success
  end

  test "index normalizes parent code param" do
    get std_work_routing_step_details_url(@work_routing.wrk_rt_cd.downcase, format: :json)
    assert_response :success
  end

  test "batch_save inserts updates and soft deletes details" do
    StdWorkRoutingStep.create!(
      wrk_rt_cd: @work_routing.wrk_rt_cd,
      seq_no: 1,
      work_step_cd: "10",
      work_step_level1_cd: "10",
      work_step_level2_cd: "10",
      use_yn_cd: "Y"
    )
    StdWorkRoutingStep.create!(
      wrk_rt_cd: @work_routing.wrk_rt_cd,
      seq_no: 2,
      work_step_cd: "20",
      work_step_level1_cd: "20",
      work_step_level2_cd: "60",
      use_yn_cd: "Y"
    )

    post batch_save_std_work_routing_step_details_url(@work_routing.wrk_rt_cd), params: {
      rowsToInsert: [
        {
          seq_no: 3,
          work_step_cd: "30",
          work_step_level1_cd: "30",
          work_step_level2_cd: "100",
          use_yn_cd: "Y",
          rmk_cd: "inserted"
        }
      ],
      rowsToUpdate: [
        {
          seq_no: 1,
          work_step_cd: "40",
          work_step_level1_cd: "20",
          work_step_level2_cd: "70",
          use_yn_cd: "Y",
          rmk_cd: "updated"
        }
      ],
      rowsToDelete: [ 2 ]
    }, as: :json

    assert_response :success
    updated = StdWorkRoutingStep.find_by!(wrk_rt_cd: @work_routing.wrk_rt_cd, seq_no: 1)
    inserted = StdWorkRoutingStep.find_by!(wrk_rt_cd: @work_routing.wrk_rt_cd, seq_no: 3)
    deleted = StdWorkRoutingStep.find_by!(wrk_rt_cd: @work_routing.wrk_rt_cd, seq_no: 2)

    assert_equal "40", updated.work_step_cd
    assert_equal "updated", updated.rmk_cd
    assert_equal "inserted", inserted.rmk_cd
    assert_equal "N", deleted.use_yn_cd
  end

  test "non-admin without permission cannot access endpoints" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_WRK_RTING_STEP").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_work_routing_step_details_url(@work_routing.wrk_rt_cd, format: :json)
    assert_response :forbidden
  end
end
