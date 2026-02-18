require "test_helper"

class System::ExcelImportTasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds successfully for admin" do
    get system_excel_import_tasks_url
    assert_response :success
  end

  test "non-admin cannot access import task index" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_excel_import_tasks_url(format: :json)
    assert_response :forbidden
  end

  test "downloads error report when attached" do
    task = ExcelImportTask.create!(
      resource_key: "users",
      status: "completed_with_errors",
      total_rows: 1,
      success_rows: 0,
      failed_rows: 1
    )
    task.error_report.attach(
      io: StringIO.new("row_number,error_message,row_data\n2,error,\"{}\"\n"),
      filename: "error_report.csv",
      content_type: "text/csv"
    )

    get error_report_system_excel_import_task_url(task)
    assert_response :success
    assert_match "text/csv", response.media_type
  end
end
