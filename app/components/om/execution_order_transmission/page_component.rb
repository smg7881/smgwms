module Om
  module ExecutionOrderTransmission
    class PageComponent < Om::BasePageComponent
      def initialize(query_params:, search_form: nil)
        super(query_params: query_params)
        @search_form = search_form || OpenStruct.new
      end

      private
        attr_reader :search_form

        def collection_path(**) = helpers.om_execution_order_transmissions_path(**)
        def retransmit_path(**) = helpers.retransmit_om_execution_order_transmissions_path(**)

        def search_fields
          [
            {
              field: "ord_no",
              type: "popup",
              label: "오더번호",
              popup_type: "order",
              code_field: "ord_no",
              value: search_form.respond_to?(:ord_no) ? search_form.ord_no : nil,
              placeholder: "오더 선택",
              display_width: "200px"
            }
          ]
        end

        def columns
          [
            { field: "slc", header_name: "선택", width: 60, checkboxSelection: true, headerCheckboxSelection: true },
            { field: "exce_sctn", header_name: "실행구분", width: 100 },
            { field: "eo_no", header_name: "실행오더번호", width: 150 },
            { field: "dpt_ar_nm", header_name: "출발지", width: 150 },
            { field: "arv_ar_nm", headerName: "도착지", width: 150 },
            { field: "work_pl_nm", headerName: "작업장", width: 150 },
            { field: "trms_seq", header_name: "전송순번", width: 100, header_class: "text-right", cell_class: "text-right", type: "numericColumn" },
            { field: "trms_sctn_nm", header_name: "전송구분", width: 100 },
            { field: "trms_hms", header_name: "전송시간", width: 160 },
            { field: "rcv_hms", header_name: "수신시간", width: 160 },
            {
              field: "trms_yn",
              header_name: "전송여부",
              width: 100,
              cellStyle: "params.value === 'E' ? { color: 'red', fontWeight: 'bold' } : (params.value === 'Y' ? { color: 'blue' } : {})"
            },
            { field: "asign_idct_no", header_name: "배차지시번호", width: 150 },
            { field: "err_msg", header_name: "오류메시지", width: 300, cellStyle: "{ color: 'red' }" }
          ]
        end
    end
  end
end
