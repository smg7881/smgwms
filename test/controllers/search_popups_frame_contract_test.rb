require "test_helper"

class SearchPopupsFrameContractTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "uses Turbo-Frame header as frame id when frame param is missing" do
    get search_popup_path("menu"), headers: { "Turbo-Frame" => "popup-frame" }

    assert_response :success
    assert_includes response.body, '<turbo-frame id="popup-frame">'
  end

  test "frame param still controls frame id" do
    get search_popup_path("menu"), params: { frame: "custom-frame" }

    assert_response :success
    assert_includes response.body, '<turbo-frame id="custom-frame">'
  end
end
