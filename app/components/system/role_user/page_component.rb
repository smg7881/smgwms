class System::RoleUser::PageComponent < System::BasePageComponent
  def initialize(query_params:, roles:)
    super(query_params: query_params)
    @roles = roles
  end

  private
    attr_reader :roles

    def collection_path(**) = helpers.system_role_user_index_path(**)
    def member_path(_id, **) = helpers.system_role_user_index_path(**)

    def role_options
      roles.map do |role|
        {
          label: "#{role.role_nm} (#{role.role_cd})",
          value: role.role_cd
        }
      end
    end

    def selected_role_cd
      params_role = query_params.dig("q", "role_cd").to_s.strip.upcase
      if params_role.present?
        params_role
      else
        roles.first&.role_cd.to_s
      end
    end

    def user_columns
      [
        { field: "user_id_code", headerName: "사용자ID", minWidth: 100 },
        { field: "user_nm", headerName: "사용자명", minWidth: 100 },
        { field: "dept_nm", headerName: "부서명", minWidth: 120 },
        { field: "position_cd", headerName: "직급", minWidth: 90 },
        { field: "job_title_cd", headerName: "직책", minWidth: 90 }
      ]
    end
end
