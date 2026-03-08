require "test_helper"

class Std::WorkStepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ensure_work_step_common_codes!
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdWorkStep.create!(
      work_step_cd: "00001",
      work_step_nm: "해송",
      work_step_level1_cd: "10",
      work_step_level2_cd: "10",
      use_yn_cd: "Y"
    )

    get std_work_steps_url
    assert_response :success

    get std_work_steps_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["work_step_cd"] == "00001" }
  end

  test "create update and destroy work with modal endpoints" do
    post std_work_steps_url, params: {
      std_work_step: {
        work_step_cd: "00002",
        work_step_nm: "DOOR운송",
        work_step_level1_cd: "10",
        work_step_level2_cd: "20",
        sort_seq: 2,
        conts_cd: "설명",
        rmk_cd: "비고",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    assert_equal "DOOR운송", StdWorkStep.find_by!(work_step_cd: "00002").work_step_nm

    patch std_work_step_url("00002"), params: {
      std_work_step: {
        work_step_cd: "99999",
        work_step_nm: "DOOR회수",
        work_step_level1_cd: "10",
        work_step_level2_cd: "30",
        sort_seq: 3,
        conts_cd: "변경설명",
        rmk_cd: "변경비고",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    row = StdWorkStep.find_by!(work_step_cd: "00002")
    assert_equal "DOOR회수", row.work_step_nm
    assert_equal "30", row.work_step_level2_cd
    assert_equal 3, row.sort_seq

    delete std_work_step_url("00002"), as: :json
    assert_response :success
    assert_equal "N", row.reload.use_yn_cd
  end

  test "create rejects invalid level2 mapping" do
    post std_work_steps_url, params: {
      std_work_step: {
        work_step_cd: "00003",
        work_step_nm: "오류케이스",
        work_step_level1_cd: "10",
        work_step_level2_cd: "90",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["errors"].join(" "), "매핑"
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_WORK_STEP").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_work_steps_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_WORK_STEP", use_yn: "Y")
    get std_work_steps_url(format: :json)
    assert_response :success
  end

  private
    def ensure_work_step_common_codes!
      header07 = AdmCodeHeader.find_or_create_by!(code: "07") do |row|
        row.code_name = "작업단계Level1"
        row.use_yn = "Y"
      end
      if header07.use_yn != "Y"
        header07.update!(use_yn: "Y")
      end

      header08 = AdmCodeHeader.find_or_create_by!(code: "08") do |row|
        row.code_name = "작업단계Level2"
        row.use_yn = "Y"
      end
      if header08.use_yn != "Y"
        header08.update!(use_yn: "Y")
      end

      AdmCodeDetail.find_or_create_by!(code: "07", detail_code: "10") do |row|
        row.detail_code_name = "운송"
        row.sort_order = 1
        row.use_yn = "Y"
      end
      AdmCodeDetail.find_or_create_by!(code: "07", detail_code: "20") do |row|
        row.detail_code_name = "하역"
        row.sort_order = 2
        row.use_yn = "Y"
      end

      AdmCodeDetail.find_or_create_by!(code: "08", detail_code: "10") do |row|
        row.detail_code_name = "내수운송"
        row.upper_detail_code = "10"
        row.sort_order = 1
        row.use_yn = "Y"
      end
      AdmCodeDetail.find_or_create_by!(code: "08", detail_code: "20") do |row|
        row.detail_code_name = "DOOR운송"
        row.upper_detail_code = "10"
        row.sort_order = 2
        row.use_yn = "Y"
      end
      AdmCodeDetail.find_or_create_by!(code: "08", detail_code: "30") do |row|
        row.detail_code_name = "DOOR회수"
        row.upper_detail_code = "10"
        row.sort_order = 3
        row.use_yn = "Y"
      end
      AdmCodeDetail.find_or_create_by!(code: "08", detail_code: "90") do |row|
        row.detail_code_name = "보관적입"
        row.upper_detail_code = "20"
        row.sort_order = 4
        row.use_yn = "Y"
      end
    end
end
