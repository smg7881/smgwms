require "rails/generators"
require "rails/generators/named_base"

module Wm
  class MasterDetailGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    argument :master_key, type: :string, desc: "마스터 PK 필드명"
    argument :detail_key, type: :string, desc: "디테일 PK 필드명"

    class_option :namespace,
      type: :string,
      required: true,
      desc: "네임스페이스 (wm/std/system)"

    class_option :menu_code,
      type: :string,
      default: "TODO_MENU_CODE",
      desc: "권한 메뉴 코드"

    def create_master_detail_scaffold
      empty_directory component_dir
      empty_directory javascript_dir
      empty_directory controller_dir

      template "page_component.rb.tt", File.join(component_dir, "page_component.rb")
      template "page_component.html.erb.tt", File.join(component_dir, "page_component.html.erb")
      template "grid_controller.js.tt", File.join(javascript_dir, "#{controller_base_name}_grid_controller.js")
      template "master_controller.rb.tt", File.join(controller_dir, "#{resource_name}_controller.rb")
      template "detail_controller.rb.tt", File.join(controller_dir, "#{detail_controller_file_name}_controller.rb")
    end

    def show_next_steps
      say ""
      say "[다음 단계]", :green
      say "1) config/routes.rb 에 nested details + batch_save 라우트를 추가하세요."
      say "2) config/master_detail_screen_contracts.yml 에 화면 계약을 등록하세요."
      say "3) 모델/조회/검증 도메인 로직을 컨트롤러에 채우세요."
      say "4) ruby bin/rails test test/contracts/master_detail_pattern_contract_test.rb 를 실행하세요."
    end

    private
      def namespace_name
        options.fetch(:namespace).to_s.underscore
      end

      def namespace_module
        namespace_name.camelize
      end

      def resource_name
        file_name.pluralize
      end

      def resource_module_name
        file_name.camelize
      end

      def resource_singular_name
        resource_name.singularize
      end

      def component_dir
        File.join("app/components", namespace_name, file_name)
      end

      def javascript_dir
        File.join("app/javascript/controllers", namespace_name)
      end

      def controller_dir
        File.join("app/controllers", namespace_name)
      end

      def controller_base_name
        file_name
      end

      def data_controller_name
        "#{namespace_name}-#{file_name.dasherize}-grid"
      end

      def target_prefix
        "#{namespace_name}_#{file_name}_grid"
      end

      def detail_controller_file_name
        "#{resource_singular_name}_details"
      end

      def detail_param_name
        "#{resource_singular_name}_id"
      end

      def master_path_helper
        "#{namespace_name}_#{resource_name}_path"
      end

      def member_path_helper
        "#{namespace_name}_#{resource_singular_name}_path"
      end

      def detail_path_helper
        "#{namespace_name}_#{resource_singular_name}_details_path"
      end

      def master_batch_save_helper
        "batch_save_#{namespace_name}_#{resource_name}_path"
      end
  end
end
