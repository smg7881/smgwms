# 시스템 내의 기본 페이지 컴포넌트입니다.
# 모든 페이지 컴포넌트의 상위 클래스 역할을 하며, 공통적인 URL 생성 로직을 포함합니다.
class System::BasePageComponent < ApplicationComponent
  # 컴포넌트 초기화 메서드입니다.
  # @param query_params [Hash] URL 쿼리 파라미터를 받습니다. (주로 검색 조건 유지 등에 사용)
  def initialize(query_params:)
    @query_params = query_params
  end

  private
    # 쿼리 파라미터에 접근하기 위한 getter입니다.
    attr_reader :query_params

    # 생성(Create) 액션을 위한 URL을 반환합니다.
    # 기본적으로 컬렉션 경로(목록 페이지 등)를 사용합니다.
    def create_url = collection_path

    # 수정(Update) 액션을 위한 URL을 반환합니다.
    # :id placeholder를 사용하여 클라이언트 사이드에서 실제 ID로 치환할 수 있도록 합니다.
    def update_url = member_path(":id")

    # 삭제(Delete) 액션을 위한 URL을 반환합니다.
    # 수정 URL과 마찬가지로 :id placeholder를 사용합니다.
    def delete_url = member_path(":id")

    # 그리드(Grid) 데이터를 가져오기 위한 URL을 반환합니다.
    # JSON 형식을 요청하며, 현재 검색 조건(q)을 포함시킵니다.
    def grid_url   = collection_path(format: :json, q: query_params["q"])

    def common_code_options(code, include_all: false, all_label: "전체", value_transform: nil)
      AdmCodeDetail.select_options_for(
        code,
        include_all: include_all,
        all_label: all_label,
        value_transform: value_transform
      )
    end

    def common_code_values(code, value_transform: nil)
      AdmCodeDetail.select_values_for(code, value_transform: value_transform)
    end

    def common_code_map(code, value_transform: nil)
      options = common_code_options(code, include_all: false, value_transform: value_transform)
      options.each_with_object({}) do |opt, hash|
        hash[opt[:value]] = opt[:label]
      end
    end

    # 하위 클래스에서 반드시 구현해야 하는 메서드들입니다. (Template Method Pattern)

    # 목록(Collection) 경로를 반환해야 합니다. (예: users_path)
    def collection_path(**) = raise(NotImplementedError, "Subclasses must implement collection_path")

    # 단일 항목(Member) 경로를 반환해야 합니다. (예: user_path(id))
    def member_path(id, **) = raise(NotImplementedError, "Subclasses must implement member_path")
end
