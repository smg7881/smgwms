module AgGridHelper
  # ── 허용된 컬럼 속성 목록 (White List) ──
  # 보안 및 데이터 무결성을 위해, 클라이언트(브라우저)로 전달될 컬럼 정의(Column Definition) 객체에서
  # 허용할 키(Key)들을 명시적으로 정의합니다.
  # 여기에 없는 키는 `sanitize_column_defs` 메서드에서 제거됩니다.
  ALLOWED_COLUMN_KEYS = %i[
    field headerName # 데이터 필드명, 헤더 표시명
    flex minWidth maxWidth width # 컬럼 크기 관련
    filter sortable resizable editable # 기능 활성화 여부
    pinned hide cellStyle # 고정, 숨김, 스타일
    formatter # 클라이언트 측 포맷터 함수 이름 (controller.js의 FORMATTER_REGISTRY 키)
    cellRenderer cellRendererParams # 셀 렌더러 및 파라미터
  ].freeze

  # ── AG Grid 생성 헬퍼 메서드 ──
  # 뷰(View)에서 AG Grid를 쉽게 생성하기 위한 헬퍼입니다.
  # Stimulus 컨트롤러(`ag-grid`)와 연결되는 HTML 구조를 생성합니다.
  #
  # @param columns [Array<Hash>] 컬럼 정의 배열 (필수)
  # @param url [String, nil] 데이터를 비동기로 로드할 API URL (선택)
  # @param row_data [Array<Hash>, nil] 정적 데이터 (url이 없을 때 사용)
  # @param pagination [Boolean] 페이지네이션 사용 여부 (기본값: true)
  # @param page_size [Integer] 페이지당 행 수 (기본값: 20)
  # @param height [String] 그리드 높이 (CSS 값, 기본값: "500px")
  # @param row_selection [String, nil] 행 선택 모드 ("single" | "multiple" | nil)
  # @param html_options [Hash] 래퍼 div에 적용할 추가 HTML 속성 (class, style 등)
  #
  # @example 사용 예시
  #   <%= ag_grid_tag(
  #     columns: [
  #       { field: "title", headerName: "제목" },
  #       { field: "price", headerName: "가격", formatter: "currency" }
  #     ],
  #     url: posts_path(format: :json),
  #     page_size: 10
  #   ) %>
  def ag_grid_tag(columns:, url: nil, row_data: nil, pagination: true,
                  page_size: 20, height: "500px", row_selection: nil,
                  **html_options)
    # 컬럼 정의 보안 처리 (허용되지 않은 속성 제거)
    safe_columns = sanitize_column_defs(columns)

    # Stemulus 컨트롤러에 전달할 데이터 속성 구성
    # data-ag-grid-* 속성으로 변환되어 JS 컨트롤러의 values로 전달됩니다.
    stimulus_data = {
      controller: "ag-grid",             # 연결할 Stimulus 컨트롤러 이름
      "ag-grid-columns-value" => safe_columns.to_json, # 컬럼 정의
      "ag-grid-pagination-value" => pagination,        # 페이지네이션 여부
      "ag-grid-page-size-value" => page_size,          # 페이지 크기
      "ag-grid-height-value" => height                 # 높이
    }

    # 선택적 속성 추가
    stimulus_data["ag-grid-url-value"] = url if url.present?
    stimulus_data["ag-grid-row-data-value"] = row_data.to_json if row_data.present?
    stimulus_data["ag-grid-row-selection-value"] = row_selection if row_selection.present?

    # 사용자가 전달한 html_options와 stimulus_data 병합
    wrapper_attrs = html_options.merge(data: stimulus_data)

    # HTML 생성:
    # <div data-controller="ag-grid" ...>
    #   <div data-ag-grid-target="grid"></div>
    # </div>
    content_tag(:div, wrapper_attrs) do
      # 실제 그리드가 렌더링될 타겟 요소
      content_tag(:div, "", data: { "ag-grid-target": "grid" })
    end
  end

  private

    # ── 컬럼 정의 정제 (Sanitization) ──
    # 입력받은 컬럼 정의 배열을 순회하며 허용된 키만 남기고 나머지는 제거합니다.
    # 개발자가 실수로 유효하지 않은 키를 넣었을 때 경고 로그를 남겨 디버깅을 돕습니다.
    def sanitize_column_defs(columns)
      columns.map do |col|
        col = col.symbolize_keys
        # 허용된 키만 슬라이스하여 안전한 객체 생성
        sanitized = col.slice(*ALLOWED_COLUMN_KEYS)

        # 제거된 키 확인 및 로그 출력
        rejected = col.keys - ALLOWED_COLUMN_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[ag_grid_helper] 허용되지 않은 columnDef 키 제거: #{rejected.join(', ')} " \
            "(field: #{col[:field]})"
          )
        end

        sanitized
      end
    end
end
