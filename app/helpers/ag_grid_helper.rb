module AgGridHelper
  # ?? ?덉슜??而щ읆 ?띿꽦 紐⑸줉 (White List) ??
  # 蹂댁븞 諛??곗씠??臾닿껐?깆쓣 ?꾪빐, ?대씪?댁뼵??釉뚮씪?곗?)濡??꾨떖??而щ읆 ?뺤쓽(Column Definition) 媛앹껜?먯꽌
  # ?덉슜????Key)?ㅼ쓣 紐낆떆?곸쑝濡??뺤쓽?⑸땲??
  # ?ш린???녿뒗 ?ㅻ뒗 `sanitize_column_defs` 硫붿꽌?쒖뿉???쒓굅?⑸땲??
  ALLOWED_COLUMN_KEYS = %i[
    field headerName
    flex minWidth maxWidth width
    filter sortable resizable editable
    pinned hide cellStyle
    type cellEditor cellEditorParams
    formatter
    cellRenderer cellRendererParams
  ].freeze

  # ?? AG Grid ?앹꽦 ?ы띁 硫붿꽌????
  # 酉?View)?먯꽌 AG Grid瑜??쎄쾶 ?앹꽦?섍린 ?꾪븳 ?ы띁?낅땲??
  # Stimulus 而⑦듃濡ㅻ윭(`ag-grid`)? ?곌껐?섎뒗 HTML 援ъ“瑜??앹꽦?⑸땲??
  #
  # @param columns [Array<Hash>] 而щ읆 ?뺤쓽 諛곗뿴 (?꾩닔)
  # @param url [String, nil] ?곗씠?곕? 鍮꾨룞湲곕줈 濡쒕뱶??API URL (?좏깮)
  # @param row_data [Array<Hash>, nil] ?뺤쟻 ?곗씠??(url???놁쓣 ???ъ슜)
  # @param pagination [Boolean] ?섏씠吏?ㅼ씠???ъ슜 ?щ? (湲곕낯媛? true)
  # @param page_size [Integer] ?섏씠吏??????(湲곕낯媛? 20)
  # @param height [String] 洹몃━???믪씠 (CSS 媛? 湲곕낯媛? "500px")
  # @param row_selection [String, nil] ???좏깮 紐⑤뱶 ("single" | "multiple" | nil)
  # @param html_options [Hash] ?섑띁 div???곸슜??異붽? HTML ?띿꽦 (class, style ??
  #
  # @example ?ъ슜 ?덉떆
  #   <%= ag_grid_tag(
  #     columns: [
  #       { field: "title", headerName: "?쒕ぉ" },
  #       { field: "price", headerName: "媛寃?, formatter: "currency" }
  #     ],
  #     url: posts_path(format: :json),
  #     page_size: 10
  #   ) %>
  def ag_grid_tag(columns:, url: nil, row_data: nil, pagination: true,
                  page_size: 20, height: "500px", row_selection: nil,
                  **html_options)
    # 而щ읆 ?뺤쓽 蹂댁븞 泥섎━ (?덉슜?섏? ?딆? ?띿꽦 ?쒓굅)
    safe_columns = sanitize_column_defs(columns)

    # Stemulus 而⑦듃濡ㅻ윭???꾨떖???곗씠???띿꽦 援ъ꽦
    # data-ag-grid-* ?띿꽦?쇰줈 蹂?섎릺??JS 而⑦듃濡ㅻ윭??values濡??꾨떖?⑸땲??
    stimulus_data = {
      controller: "ag-grid",             # ?곌껐??Stimulus 而⑦듃濡ㅻ윭 ?대쫫
      "ag-grid-columns-value" => safe_columns.to_json, # 而щ읆 ?뺤쓽
      "ag-grid-pagination-value" => pagination,        # ?섏씠吏?ㅼ씠???щ?
      "ag-grid-page-size-value" => page_size,          # ?섏씠吏 ?ш린
      "ag-grid-height-value" => height                 # ?믪씠
    }

    # ?좏깮???띿꽦 異붽?
    stimulus_data["ag-grid-url-value"] = url if url.present?
    stimulus_data["ag-grid-row-data-value"] = row_data.to_json if row_data.present?
    stimulus_data["ag-grid-row-selection-value"] = row_selection if row_selection.present?

    # ?ъ슜?먭? ?꾨떖??html_options? stimulus_data 蹂묓빀
    custom_data = html_options.delete(:data) || {}
    wrapper_attrs = html_options.merge(data: custom_data.merge(stimulus_data))

    # HTML ?앹꽦:
    # <div data-controller="ag-grid" ...>
    #   <div data-ag-grid-target="grid"></div>
    # </div>
    content_tag(:div, wrapper_attrs) do
      # ?ㅼ젣 洹몃━?쒓? ?뚮뜑留곷맆 ?寃??붿냼
      content_tag(:div, "", data: { "ag-grid-target": "grid" })
    end
  end

  private

    # ?? 而щ읆 ?뺤쓽 ?뺤젣 (Sanitization) ??
    # ?낅젰諛쏆? 而щ읆 ?뺤쓽 諛곗뿴???쒗쉶?섎ŉ ?덉슜???ㅻ쭔 ?④린怨??섎㉧吏???쒓굅?⑸땲??
    # 媛쒕컻?먭? ?ㅼ닔濡??좏슚?섏? ?딆? ?ㅻ? ?ｌ뿀????寃쎄퀬 濡쒓렇瑜??④꺼 ?붾쾭源낆쓣 ?뺤뒿?덈떎.
    def sanitize_column_defs(columns)
      columns.map do |col|
        col = col.symbolize_keys
        # ?덉슜???ㅻ쭔 ?щ씪?댁뒪?섏뿬 ?덉쟾??媛앹껜 ?앹꽦
        sanitized = col.slice(*ALLOWED_COLUMN_KEYS)

        # ?쒓굅?????뺤씤 諛?濡쒓렇 異쒕젰
        rejected = col.keys - ALLOWED_COLUMN_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[ag_grid_helper] ?덉슜?섏? ?딆? columnDef ???쒓굅: #{rejected.join(', ')} " \
            "(field: #{col[:field]})"
          )
        end

        sanitized
      end
    end
end

