require "test_helper"

class AdmLoginHistoryTest < ActiveSupport::TestCase
  MockRequest = Data.define(:remote_ip, :user_agent)

  setup do
    @admin = users(:admin)
    @mock_request = MockRequest.new(
      remote_ip: "127.0.0.1",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
  end

  test "record_success creates a success entry" do
    assert_difference "AdmLoginHistory.count", 1 do
      AdmLoginHistory.record_success(user: @admin, request: @mock_request)
    end

    record = AdmLoginHistory.last
    assert_equal @admin.user_id_code, record.user_id_code
    assert_equal @admin.user_nm, record.user_nm
    assert record.login_success
    assert_equal "127.0.0.1", record.ip_address
    assert_not_nil record.browser
    assert_not_nil record.os
    assert_nil record.failure_reason
  end

  test "record_failure creates a failure entry with known user" do
    assert_difference "AdmLoginHistory.count", 1 do
      AdmLoginHistory.record_failure(
        email_input: @admin.email_address,
        request: @mock_request,
        reason: "잘못된 비밀번호"
      )
    end

    record = AdmLoginHistory.last
    assert_equal @admin.user_id_code, record.user_id_code
    assert_equal @admin.user_nm, record.user_nm
    assert_not record.login_success
    assert_equal "잘못된 비밀번호", record.failure_reason
  end

  test "record_failure with unknown email stores email as user_id_code" do
    AdmLoginHistory.record_failure(
      email_input: "unknown@test.com",
      request: @mock_request,
      reason: "사용자 없음"
    )

    record = AdmLoginHistory.last
    assert_equal "unknown@test.com", record.user_id_code
    assert_nil record.user_nm
    assert_not record.login_success
  end

  test "scopes filter correctly" do
    before_count = AdmLoginHistory.count
    AdmLoginHistory.record_success(user: @admin, request: @mock_request)
    AdmLoginHistory.record_failure(email_input: "test@test.com", request: @mock_request, reason: "test")

    assert_equal before_count + 2, AdmLoginHistory.count
    assert AdmLoginHistory.by_success(true).count >= 1
    assert AdmLoginHistory.by_success(false).count >= 1
    assert AdmLoginHistory.by_user(@admin.user_id_code).count >= 1
  end

  test "since and until_time scopes" do
    AdmLoginHistory.record_success(user: @admin, request: @mock_request)
    created = AdmLoginHistory.order(:id).last

    assert AdmLoginHistory.where(id: created.id).since(1.hour.ago).exists?
    assert_not AdmLoginHistory.where(id: created.id).since(1.hour.from_now).exists?
    assert AdmLoginHistory.where(id: created.id).until_time(1.hour.from_now).exists?
    assert_not AdmLoginHistory.where(id: created.id).until_time(1.hour.ago).exists?
  end

  test "parse_user_agent extracts browser and os" do
    AdmLoginHistory.record_success(user: @admin, request: @mock_request)

    record = AdmLoginHistory.last
    assert_includes record.browser.downcase, "chrome"
    assert_includes record.os.downcase, "windows"
  end
end
