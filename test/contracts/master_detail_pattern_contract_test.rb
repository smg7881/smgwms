require "test_helper"
require "yaml"

class MasterDetailPatternContractTest < ActiveSupport::TestCase
  SCREEN_CONFIG_PATH = Rails.root.join("config/master_detail_screen_contracts.yml")

  test "등록된 화면은 master-detail 표준 계약을 만족한다" do
    screens = load_screen_contracts
    routes = normalized_routes

    screens.each do |screen|
      assert_file_contracts(screen)
      assert_page_component_contracts(screen)
      assert_page_view_contracts(screen)
      assert_stimulus_contracts(screen)
      assert_controller_contracts(screen)
      assert_route_contracts(screen, routes)
    end
  end

  private
    def load_screen_contracts
      raw = YAML.safe_load(File.read(SCREEN_CONFIG_PATH), aliases: true)
      Array(raw["screens"])
    end

    def normalized_routes
      Rails.application.routes.routes.map do |route|
        {
          controller: route.defaults[:controller].to_s,
          action: route.defaults[:action].to_s,
          path: route.path.spec.to_s,
          verb: route.verb.to_s
        }
      end
    end

    def assert_file_contracts(screen)
      key = screen.fetch("key")
      required_paths = [
        "page_component_path",
        "page_view_path",
        "js_controller_path",
        "master_controller_path",
        "detail_controller_path"
      ]

      required_paths.each do |path_key|
        relative_path = screen.fetch(path_key)
        absolute_path = Rails.root.join(relative_path)
        assert File.exist?(absolute_path), "#{key}: 파일이 없습니다 (#{relative_path})"
      end
    end

    def assert_page_component_contracts(screen)
      key = screen.fetch("key")
      source = read_source(screen.fetch("page_component_path"))
      required_tokens = [
        "def detail_collection_path",
        "def detail_grid_url",
        "def master_batch_save_url",
        "def detail_batch_save_url_template"
      ]

      required_tokens.each do |token|
        assert_includes source, token, "#{key}: PageComponent 계약 누락 (#{token})"
      end
    end

    def assert_page_view_contracts(screen)
      key = screen.fetch("key")
      source = read_source(screen.fetch("page_view_path"))
      data_controller = screen.fetch("data_controller")
      required_tokens = [
        "data-controller=\"#{data_controller}\"",
        "ag-grid:ready->#{data_controller}#registerGrid",
        "data-#{data_controller}-master-batch-url-value=",
        "data-#{data_controller}-detail-batch-url-template-value=",
        "data-#{data_controller}-detail-list-url-template-value=",
        "masterGrid",
        "detailGrid"
      ]

      required_tokens.each do |token|
        assert_includes source, token, "#{key}: page_component.html.erb 계약 누락 (#{token})"
      end
    end

    def assert_stimulus_contracts(screen)
      key = screen.fetch("key")
      source = read_source(screen.fetch("js_controller_path"))
      required_tokens = [
        "extends BaseGridController",
        "gridRoles()",
        "target: \"masterGrid\"",
        "target: \"detailGrid\"",
        "parentGrid: \"master\"",
        "detailLoader: async",
        "saveMasterRows()",
        "saveDetailRows()"
      ]

      required_tokens.each do |token|
        assert_includes source, token, "#{key}: Stimulus 계약 누락 (#{token})"
      end
    end

    def assert_controller_contracts(screen)
      key = screen.fetch("key")
      master_source = read_source(screen.fetch("master_controller_path"))
      detail_source = read_source(screen.fetch("detail_controller_path"))

      assert_includes master_source, "def index", "#{key}: master controller index 누락"
      assert_includes master_source, "def batch_save", "#{key}: master controller batch_save 누락"
      assert_includes master_source, "format.html", "#{key}: master controller format.html 누락"
      assert_includes master_source, "format.json", "#{key}: master controller format.json 누락"
      assert_includes detail_source, "def index", "#{key}: detail controller index 누락"
      assert_includes detail_source, "def batch_save", "#{key}: detail controller batch_save 누락"
    end

    def assert_route_contracts(screen, routes)
      key = screen.fetch("key")
      master_controller = screen.fetch("route_master_controller")
      detail_controller = screen.fetch("route_detail_controller")
      parent_param = screen.fetch("route_detail_parent_param")

      assert_route_exists!(
        routes: routes,
        key: key,
        controller: master_controller,
        action: "batch_save",
        path_pattern: "/batch_save"
      )

      assert_route_exists!(
        routes: routes,
        key: key,
        controller: detail_controller,
        action: "index",
        path_pattern: "/:#{parent_param}/details"
      )

      assert_route_exists!(
        routes: routes,
        key: key,
        controller: detail_controller,
        action: "batch_save",
        path_pattern: "/:#{parent_param}/details/batch_save"
      )
    end

    def assert_route_exists!(routes:, key:, controller:, action:, path_pattern:)
      matches = routes.select do |route|
        route[:controller] == controller &&
          route[:action] == action &&
          route[:path].include?(path_pattern)
      end

      assert matches.any?, "#{key}: route 누락 (#{controller}##{action}, #{path_pattern})"
    end

    def read_source(relative_path)
      Rails.root.join(relative_path).read
    end
end
