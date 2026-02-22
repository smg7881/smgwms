require "test_helper"

class Std::ReservedJobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdReservedJob.create!(
      sys_sctn_cd: "WMS",
      rsv_work_no: "RW000001",
      rsv_work_nm_cd: "Job A",
      rsv_work_desc_cd: "Desc",
      rsv_work_cycle_cd: "DAILY",
      use_yn_cd: "Y"
    )

    get std_reserved_jobs_url
    assert_response :success

    get std_reserved_jobs_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["rsv_work_no"] == "RW000001" }
  end

  test "batch_save inserts update and soft delete" do
    StdReservedJob.create!(
      sys_sctn_cd: "WMS",
      rsv_work_no: "RW000010",
      rsv_work_nm_cd: "Before",
      rsv_work_desc_cd: "Desc",
      rsv_work_cycle_cd: "DAILY",
      use_yn_cd: "Y"
    )
    StdReservedJob.create!(
      sys_sctn_cd: "WMS",
      rsv_work_no: "RW000011",
      rsv_work_nm_cd: "Delete",
      rsv_work_desc_cd: "Desc",
      rsv_work_cycle_cd: "DAILY",
      use_yn_cd: "Y"
    )

    post batch_save_std_reserved_jobs_url, params: {
      rowsToInsert: [{ sys_sctn_cd: "WMS", rsv_work_nm_cd: "New Job", rsv_work_desc_cd: "Desc", rsv_work_cycle_cd: "DAILY", use_yn_cd: "Y" }],
      rowsToUpdate: [{ sys_sctn_cd: "WMS", rsv_work_no: "RW000010", rsv_work_nm_cd: "After", rsv_work_desc_cd: "Desc", rsv_work_cycle_cd: "DAILY", use_yn_cd: "Y" }],
      rowsToDelete: ["RW000011"]
    }, as: :json

    assert_response :success
    assert_equal "After", StdReservedJob.find_by!(rsv_work_no: "RW000010").rsv_work_nm_cd
    assert_equal "N", StdReservedJob.find_by!(rsv_work_no: "RW000011").use_yn_cd
    assert StdReservedJob.exists?(rsv_work_nm_cd: "New Job")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_RESERVED_JOB").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_reserved_jobs_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_RESERVED_JOB", use_yn: "Y")
    get std_reserved_jobs_url(format: :json)
    assert_response :success
  end
end
