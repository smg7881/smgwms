class Std::RegionZipcode::PageComponent < Std::BasePageComponent
  private
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
