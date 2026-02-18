require "test_helper"
require "tempfile"

class System::UsersControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index json does not expose password_digest" do
    get system_users_url(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_operator json.length, :>=, 1
    assert_not_includes json.first.keys, "password_digest"
  end

  test "show json does not expose password_digest" do
    get system_user_url(users(:one), format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_not_includes json.keys, "password_digest"
  end

  test "non-admin cannot access users endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_users_url(format: :json)
    assert_response :forbidden
  end

  test "excel import rejects unsupported extension" do
    Tempfile.create([ "users-import", ".txt" ]) do |file|
      file.write("invalid")
      file.flush

      post excel_import_system_users_url, params: {
        file: Rack::Test::UploadedFile.new(file.path, "text/plain")
      }
    end

    assert_redirected_to system_users_url
    assert_match("허용되지 않는 파일 형식", flash[:alert])
  end

  test "excel import rejects oversized file" do
    Tempfile.create([ "users-import", ".csv" ]) do |file|
      file.write("a" * (10.megabytes + 1))
      file.flush

      post excel_import_system_users_url, params: {
        file: Rack::Test::UploadedFile.new(file.path, "text/csv")
      }
    end

    assert_redirected_to system_users_url
    assert_match("10MB 이하", flash[:alert])
  end

  test "excel import rejects invalid header and marks task failed" do
    post excel_import_system_users_url, params: {
      file: fixture_file_upload("users_import_invalid_header.csv", "text/csv")
    }

    assert_redirected_to system_users_url
    assert_match("헤더가 템플릿과 일치하지 않습니다", flash[:alert])

    task = ExcelImportTask.recent_first.first
    assert_equal "users", task.resource_key
    assert_equal "failed", task.status
  end

  test "excel import stores error report for failed rows" do
    post excel_import_system_users_url, params: {
      file: fixture_file_upload("users_import_with_error.csv", "text/csv")
    }

    assert_redirected_to system_users_url

    task = ExcelImportTask.recent_first.first
    assert_equal "completed_with_errors", task.status
    assert_equal 2, task.total_rows
    assert_equal 1, task.success_rows
    assert_equal 1, task.failed_rows
    assert task.error_report.attached?
  end

  test "excel import enqueues background job for files larger than 10000 rows" do
    clear_enqueued_jobs

    Tempfile.create([ "users-large-import", ".csv" ]) do |file|
      headers = Excel::HandlerRegistry.fetch(:users).headers
      file.write("#{headers.join(',')}\n")
      10_001.times do |index|
        file.write("bulk#{index},Bulk User #{index},bulk#{index}@example.com,D001,Dept A,USER,STAFF,MEMBER,ACTIVE,2026-01-01,,010-2222-3333,Address,Detail\n")
      end
      file.flush

      assert_enqueued_with(job: ExcelImportJob) do
        post excel_import_system_users_url, params: {
          file: Rack::Test::UploadedFile.new(file.path, "text/csv")
        }
      end
    end

    assert_redirected_to system_users_url

    task = ExcelImportTask.recent_first.first
    assert_equal "queued", task.status
  end
end
