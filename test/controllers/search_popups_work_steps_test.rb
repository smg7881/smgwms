require "test_helper"

class SearchPopupsWorkStepsTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    AdmCodeHeader.find_or_create_by!(code: "07") do |row|
      row.code_name = "작업단계 Level1"
      row.use_yn = "Y"
    end
    AdmCodeHeader.find_or_create_by!(code: "08") do |row|
      row.code_name = "작업단계 Level2"
      row.use_yn = "Y"
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
    AdmCodeDetail.find_or_create_by!(code: "08", detail_code: "100") do |row|
      row.detail_code_name = "해송"
      row.upper_detail_code = "10"
      row.sort_order = 1
      row.use_yn = "Y"
    end
    AdmCodeDetail.find_or_create_by!(code: "08", detail_code: "200") do |row|
      row.detail_code_name = "도어운송"
      row.upper_detail_code = "20"
      row.sort_order = 2
      row.use_yn = "Y"
    end

    StdWorkStep.create!(
      work_step_cd: "WS001",
      work_step_nm: "해상운송",
      work_step_level1_cd: "10",
      work_step_level2_cd: "100",
      sort_seq: 1,
      use_yn_cd: "Y"
    )
    StdWorkStep.create!(
      work_step_cd: "WS999",
      work_step_nm: "미사용단계",
      work_step_level1_cd: "20",
      work_step_level2_cd: "200",
      sort_seq: 2,
      use_yn_cd: "N"
    )
  end

  test "work_step popup html renders search fields" do
    get search_popup_path("work_step")

    assert_response :success
    assert_includes response.body, 'name="q[work_step_cd]"'
    assert_includes response.body, 'name="q[work_step_nm]"'
    assert_includes response.body, 'name="q[work_step_level1_cd]"'
    assert_includes response.body, 'name="q[work_step_level2_cd]"'
    assert_includes response.body, 'name="q[use_yn]"'
    assert_includes response.body, "작업단계코드"
    assert_includes response.body, "작업단계 Level2 명"
  end

  test "work_step popup json defaults use_yn to Y" do
    get search_popup_path("work_step"), params: { format: :json }

    assert_response :success
    rows = JSON.parse(response.body)
    codes = rows.map { |row| row["work_step_cd"] || row["code"] }

    assert_includes codes, "WS001"
    assert_not_includes codes, "WS999"
  end

  test "work_step popup json includes related level fields" do
    get search_popup_path("work_step"), params: {
      format: :json,
      q: {
        work_step_cd: "WS0",
        work_step_nm: "해상",
        work_step_level1_cd: "10",
        work_step_level2_cd: "100",
        use_yn: "Y"
      }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length

    row = rows.first
    assert_equal "WS001", row["work_step_cd"]
    assert_equal "해상운송", row["work_step_nm"]
    assert_equal "10", row["work_step_level1_cd"]
    assert_equal "운송", row["work_step_level1_nm"]
    assert_equal "100", row["work_step_level2_cd"]
    assert_equal "해송", row["work_step_level2_nm"]
    assert_equal "Y", row["use_yn"]
  end
end
