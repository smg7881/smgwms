class Om::PreOrderFileUpload::PageComponent < Om::BasePageComponent
  def initialize(query_params:, form:)
    super(query_params: query_params)
    @form = form
  end

  private
    attr_reader :form

    def collection_path(**) = helpers.om_pre_order_file_uploads_path(**)
    def member_path(_id, **) = helpers.om_pre_order_file_uploads_path(**)

    def preview_url
      helpers.preview_om_pre_order_file_uploads_path
    end

    def validate_url
      helpers.validate_rows_om_pre_order_file_uploads_path
    end

    def save_url
      helpers.save_om_pre_order_file_uploads_path
    end

    def template_url
      helpers.download_template_om_pre_order_file_uploads_path
    end

    def upload_fields
      [
        {
          field: "upload_file",
          type: "input",
          input_type: "file",
          label: "업로드 파일",
          required: true,
          accept: ".xls,.xlsx,.csv",
          help: "사전오더 업로드 파일을 선택해주세요.",
          target: "uploadFileInput"
        }
      ]
    end

    def upload_result_columns
      [
        { field: "succ_yn", headerName: "성공여부", minWidth: 90, maxWidth: 95, editable: false },
        { field: "err_msg", headerName: "오류메시지", minWidth: 260, editable: false },
        { field: "seq", headerName: "순번", minWidth: 70, maxWidth: 80, editable: false },
        { field: "bef_ord_no", headerName: "사전오더번호", minWidth: 150, editable: false },
        { field: "ord_no", headerName: "오더번호", minWidth: 140, editable: false },
        { field: "cust_cd", headerName: "고객코드", minWidth: 110, editable: false },
        { field: "cust_ord_no", headerName: "고객오더번호", minWidth: 150, editable: false },
        { field: "ord_req_cust_cd", headerName: "오더요청고객코드", minWidth: 150, editable: false },
        { field: "bilg_cust_cd", headerName: "청구고객코드", minWidth: 130, editable: false },
        { field: "cust_ofcr_nm", headerName: "고객담당자명", minWidth: 120, editable: false },
        { field: "cust_ofcr_tel_no", headerName: "고객담당자전화번호", minWidth: 150, editable: false },
        { field: "ord_type_cd", headerName: "오더유형코드", minWidth: 120, editable: false },
        { field: "cust_expr_yn", headerName: "고객긴급여부", minWidth: 110, editable: false },
        { field: "retrngd_yn", headerName: "반품여부", minWidth: 90, editable: false },
        { field: "cargo_form_cd", headerName: "벌크형태코드", minWidth: 120, editable: false },
        { field: "cust_bzac_cd", headerName: "고객거래처코드", minWidth: 130, editable: false },
        { field: "dpt_ar_cd", headerName: "출발지코드", minWidth: 110, editable: false },
        { field: "dpt_ar_type_cd", headerName: "출발지유형코드", minWidth: 130, editable: false },
        { field: "dpt_ar_zip_cd", headerName: "출발지우편번호", minWidth: 120, editable: false },
        { field: "strt_req_ymd", headerName: "시작요청일자", minWidth: 120, editable: false },
        { field: "aptd_req_ymd", headerName: "납기요청일자", minWidth: 120, editable: false },
        { field: "arv_ar_cd", headerName: "도착지코드", minWidth: 110, editable: false },
        { field: "arv_ar_type_cd", headerName: "도착지유형코드", minWidth: 130, editable: false },
        { field: "arv_ar_zip_cd", headerName: "도착지우편번호", minWidth: 120, editable: false },
        { field: "line_no", headerName: "라인번호", minWidth: 90, maxWidth: 100, editable: false },
        { field: "item_cd", headerName: "아이템코드", minWidth: 120, editable: false },
        { field: "item_nm", headerName: "아이템명", minWidth: 140, editable: false },
        { field: "qty", headerName: "수량", minWidth: 90, editable: false, cellClass: "text-right" },
        { field: "qty_unit_cd", headerName: "수량단위코드", minWidth: 120, editable: false },
        { field: "wgt", headerName: "중량", minWidth: 90, editable: false, cellClass: "text-right" },
        { field: "wgt_unit_cd", headerName: "중량단위코드", minWidth: 120, editable: false },
        { field: "vol", headerName: "부피", minWidth: 90, editable: false, cellClass: "text-right" },
        { field: "vol_unit_cd", headerName: "부피단위코드", minWidth: 120, editable: false }
      ]
    end
end
