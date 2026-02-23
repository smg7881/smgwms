class Std::RegionZipcode::PageComponent < Std::BasePageComponent
  def initialize(query_params:, default_corp_code:, default_corp_name:, default_country_code:, default_country_name:)
    super(query_params: query_params)
    @default_corp_code = default_corp_code.to_s.strip.upcase
    @default_corp_name = default_corp_name.to_s.strip
    @default_country_code = default_country_code.to_s.strip.upcase
    @default_country_name = default_country_name.to_s.strip
  end

  private
    attr_reader :default_corp_code, :default_corp_name, :default_country_code, :default_country_name

    def collection_path(**) = helpers.std_region_zipcodes_path(**)
    def member_path(_id, **) = helpers.std_region_zipcodes_path(**)

    def mapped_zipcodes_url
      helpers.mapped_zipcodes_std_region_zipcodes_path
    end

    def unmapped_zipcodes_url
      helpers.unmapped_zipcodes_std_region_zipcodes_path
    end

    def save_mappings_url
      helpers.save_mappings_std_region_zipcodes_path
    end

    def top_search_fields
      [
        {
          field: "regn_nm",
          type: "popup",
          label: "* 권역",
          popup_type: "region",
          code_field: "regn_cd",
          placeholder: "권역 선택",
          span: "24 m:12",
          code_width: "110px",
          button_width: "40px"
        },
        {
          field: "corp_nm",
          type: "popup",
          label: "* 법인",
          popup_type: "corp",
          code_field: "corp_cd",
          placeholder: "법인 선택",
          span: "24 m:12",
          code_width: "110px",
          button_width: "40px"
        }
      ]
    end

    def bottom_search_fields
      [
        {
          field: "ctry_nm",
          type: "popup",
          label: "* 국가",
          popup_type: "country",
          code_field: "ctry_cd",
          placeholder: "국가 선택",
          span: "24 m:12",
          code_width: "100px",
          button_width: "40px"
        },
        {
          field: "zipcd",
          type: "input",
          label: "우편번호",
          placeholder: "우편번호",
          span: "24 m:6"
        },
        {
          field: "zipaddr",
          type: "input",
          label: "우편주소",
          placeholder: "우편주소",
          span: "24 m:6"
        }
      ]
    end

    def mapped_columns
      zip_columns(include_sort: true)
    end

    def unmapped_columns
      zip_columns(include_sort: false)
    end

    def zip_columns(include_sort:)
      columns = []
      if include_sort
        columns << { field: "sort_seq", headerName: "순서", maxWidth: 90, editable: true, cellEditor: "agNumberCellEditor" }
      end

      columns + [
        { field: "ctry_cd", headerName: "국가", maxWidth: 90 },
        { field: "zipcd", headerName: "우편번호", minWidth: 110 },
        { field: "seq_no", headerName: "일련번호", maxWidth: 100 },
        { field: "zipaddr", headerName: "우편주소", minWidth: 230 },
        { field: "sido", headerName: "시도", minWidth: 120 },
        { field: "sgng", headerName: "시군구", minWidth: 120 },
        { field: "eupdiv", headerName: "읍면동", minWidth: 120 }
      ]
    end
end
