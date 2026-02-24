require "roo"
require "securerandom"

module Om
  class PreOrderFileUploadService
    FIELD_DEFINITIONS = [
      { key: :bef_ord_no, header: "사전오더번호", required: true, aliases: %w[bef_ord_no befordno 사전오더번호] },
      { key: :ord_no, header: "오더번호", required: false, aliases: %w[ord_no ordno 오더번호] },
      { key: :cust_cd, header: "고객코드", required: true, aliases: %w[cust_cd custcd customercode 고객코드] },
      { key: :cust_ord_no, header: "고객오더번호", required: true, aliases: %w[cust_ord_no custordno customerordernumber 고객오더번호] },
      { key: :ord_req_cust_cd, header: "오더요청고객코드", required: false, aliases: %w[ord_req_cust_cd orderrequestcustomercode 오더요청고객코드] },
      { key: :bilg_cust_cd, header: "청구고객코드", required: false, aliases: %w[bilg_cust_cd billingcustomercode 청구고객코드] },
      { key: :cust_ofcr_nm, header: "고객담당자명", required: false, aliases: %w[cust_ofcr_nm customerofficername 고객담당자명] },
      { key: :cust_ofcr_tel_no, header: "고객담당자전화번호", required: false, aliases: %w[cust_ofcr_tel_no customerofficertelephonenumber 고객담당자전화번호] },
      { key: :ord_type_cd, header: "오더유형코드", required: false, aliases: %w[ord_type_cd ordertypecode 오더유형코드] },
      { key: :cust_expr_yn, header: "고객긴급여부", required: false, aliases: %w[cust_expr_yn customerexpressyesorno 고객긴급여부] },
      { key: :retrngd_yn, header: "반품여부", required: false, aliases: %w[retrngd_yn returngoodsyesorno 반품여부] },
      { key: :cargo_form_cd, header: "벌크형태코드", required: false, aliases: %w[cargo_form_cd cargoformcode 벌크형태코드] },
      { key: :cust_bzac_cd, header: "고객거래처코드", required: false, aliases: %w[cust_bzac_cd customerbusinessacquaintancecode 고객거래처코드] },
      { key: :dpt_ar_cd, header: "출발지코드", required: true, aliases: %w[dpt_ar_cd departureareacode 출발지코드] },
      { key: :dpt_ar_type_cd, header: "출발지유형코드", required: false, aliases: %w[dpt_ar_type_cd departureareatypecode 출발지유형코드] },
      { key: :dpt_ar_zip_cd, header: "출발지우편번호", required: false, aliases: %w[dpt_ar_zip_cd departureareazipcode 출발지우편번호] },
      { key: :strt_req_ymd, header: "시작요청일자", required: true, aliases: %w[strt_req_ymd startrequestyyyymmdd 시작요청일자] },
      { key: :aptd_req_ymd, header: "납기요청일자", required: true, aliases: %w[aptd_req_ymd appointeddatetimefordeliveryrequestyyyymmdd 납기요청일자] },
      { key: :arv_ar_cd, header: "도착지코드", required: true, aliases: %w[arv_ar_cd arrivalareacode 도착지코드] },
      { key: :arv_ar_type_cd, header: "도착지유형코드", required: false, aliases: %w[arv_ar_type_cd arrivalareatypecode 도착지유형코드] },
      { key: :arv_ar_zip_cd, header: "도착지우편번호", required: false, aliases: %w[arv_ar_zip_cd arrivalareazipcode 도착지우편번호] },
      { key: :line_no, header: "라인번호", required: false, aliases: %w[line_no linenumber 라인번호] },
      { key: :item_cd, header: "아이템코드", required: true, aliases: %w[item_cd itemcode 아이템코드] },
      { key: :item_nm, header: "아이템명", required: false, aliases: %w[item_nm itemname 아이템명] },
      { key: :qty, header: "수량", required: true, aliases: %w[qty quantity 수량] },
      { key: :qty_unit_cd, header: "수량단위코드", required: false, aliases: %w[qty_unit_cd quantityunitcode 수량단위코드] },
      { key: :wgt, header: "중량", required: false, aliases: %w[wgt weight 중량] },
      { key: :wgt_unit_cd, header: "중량단위코드", required: false, aliases: %w[wgt_unit_cd weightunitcode 중량단위코드] },
      { key: :vol, header: "부피", required: false, aliases: %w[vol volume 부피] },
      { key: :vol_unit_cd, header: "부피단위코드", required: false, aliases: %w[vol_unit_cd volumnunitcode 부피단위코드] }
    ].freeze

    REQUIRED_FIELDS = FIELD_DEFINITIONS.select { |field| field[:required] }.map { |field| field[:key] }.freeze
    TEMPLATE_HEADERS = FIELD_DEFINITIONS.map { |field| field[:header] }.freeze

    def initialize(file:, actor:)
      @file = file
      @actor = actor.to_s.strip.presence || "system"
    end

    def preview
      build_preview_result
    end

    def validate_rows
      build_preview_result
    end

    def save
      parsed = parse_file
      if parsed[:rows].blank?
        return failure_result(parsed, "업로드 파일에서 처리할 데이터가 없습니다.")
      end

      if parsed[:error_count].positive?
        batch_no = persist_failed_batch(parsed)
        return failure_result(parsed, "필수항목 체크 결과 오류가 존재합니다. 오류를 수정한 후 다시 저장해주세요.", batch_no: batch_no)
      end

      persist_success_batch(parsed)
    end

    private
      attr_reader :file, :actor

      def build_preview_result
        parsed = parse_file
        {
          success: parsed[:error_count].zero?,
          message: build_preview_message(parsed),
          rows: parsed[:rows],
          summary: summary_hash(parsed),
          can_save: parsed[:rows].any? && parsed[:error_count].zero?
        }
      end

      def parse_file
        sheet = workbook.sheet(0)
        header_row = Array(sheet.row(1))
        header_map = build_header_map(header_row)
        missing_headers = REQUIRED_FIELDS.select do |field_key|
          !header_map.key?(field_key)
        end

        rows = []
        seq = 0
        line_start = 2
        line_end = sheet.last_row.to_i

        if line_end >= line_start
          (line_start..line_end).each do |line_no|
            raw_row = Array(sheet.row(line_no))
            if row_blank?(raw_row)
              next
            end

            seq += 1
            mapped_row = map_row(raw_row, header_map, line_no, seq)
            errors = validate_row(mapped_row)
            if missing_headers.any?
              errors << "필수 컬럼 누락: #{human_headers(missing_headers).join(', ')}"
            end

            mapped_row[:succ_yn] = if errors.empty?
              "Y"
            else
              "N"
            end
            mapped_row[:err_msg] = errors.uniq.join(" | ")

            rows << mapped_row
          end
        end

        if rows.empty? && missing_headers.any?
          rows << {
            succ_yn: "N",
            err_msg: "필수 컬럼 누락: #{human_headers(missing_headers).join(', ')}",
            seq: 1,
            line_no: 1
          }
        end

        formatted_rows = rows.map { |row| format_row_for_grid(row) }
        error_count = rows.count { |row| row[:succ_yn] == "N" }

        {
          rows: formatted_rows,
          raw_rows: rows,
          total_count: rows.size,
          success_count: rows.size - error_count,
          error_count: error_count,
          missing_headers: missing_headers
        }
      rescue StandardError => e
        {
          rows: [ {
            succ_yn: "N",
            err_msg: "파일 형식을 읽을 수 없습니다: #{e.message}",
            seq: 1,
            line_no: 1
          } ],
          raw_rows: [],
          total_count: 1,
          success_count: 0,
          error_count: 1,
          missing_headers: []
        }
      end

      def workbook
        Roo::Spreadsheet.open(tempfile_path, extension: file_extension)
      end

      def tempfile_path
        file.tempfile.path
      end

      def file_extension
        extension = File.extname(original_filename).to_s.delete(".").downcase
        if extension.present?
          extension.to_sym
        else
          :xlsx
        end
      end

      def original_filename
        file.original_filename.to_s
      end

      def build_header_map(header_row)
        normalized_headers = header_row.map { |value| normalize_header(value) }
        map = {}

        FIELD_DEFINITIONS.each do |definition|
          aliases = definition[:aliases].map { |alias_name| normalize_header(alias_name) } + [ normalize_header(definition[:header]) ]
          index = normalized_headers.find_index do |header_name|
            aliases.include?(header_name)
          end

          if index.present?
            map[definition[:key]] = index
          end
        end

        map
      end

      def normalize_header(value)
        value.to_s.gsub(/[[:space:]_\-()]/, "").downcase
      end

      def row_blank?(row)
        row.all? do |value|
          value.to_s.strip.blank?
        end
      end

      def map_row(raw_row, header_map, line_no, seq)
        mapped = {
          seq: seq,
          line_no: line_no
        }

        FIELD_DEFINITIONS.each do |definition|
          key = definition[:key]
          index = header_map[key]
          value = if index.present?
            raw_row[index]
          else
            nil
          end
          mapped[key] = normalize_field_value(key, value)
        end

        mapped
      end

      def normalize_field_value(key, value)
        if %i[strt_req_ymd aptd_req_ymd].include?(key)
          return parse_date(value)
        end

        if %i[qty wgt vol].include?(key)
          return parse_number(value)
        end

        if %i[cust_expr_yn retrngd_yn].include?(key)
          return normalize_yes_no(value)
        end

        upcase_fields = %i[
          bef_ord_no ord_no cust_cd cust_ord_no ord_req_cust_cd bilg_cust_cd ord_type_cd
          cargo_form_cd cust_bzac_cd dpt_ar_cd dpt_ar_type_cd dpt_ar_zip_cd
          arv_ar_cd arv_ar_type_cd arv_ar_zip_cd item_cd qty_unit_cd wgt_unit_cd vol_unit_cd
        ]
        normalize_string(value, upcase: upcase_fields.include?(key))
      end

      def parse_date(value)
        if value.is_a?(Date)
          return value
        end
        if value.is_a?(Time) || value.is_a?(DateTime)
          return value.to_date
        end

        text = value.to_s.strip
        if text.blank?
          return nil
        end

        if text.match?(/\A\d{8}\z/)
          return Date.strptime(text, "%Y%m%d")
        end

        Date.parse(text)
      rescue ArgumentError
        nil
      end

      def parse_number(value)
        text = value.to_s.strip
        if text.blank?
          return nil
        end
        BigDecimal(text.to_s)
      rescue ArgumentError
        nil
      end

      def normalize_yes_no(value)
        normalized = value.to_s.strip.upcase
        if normalized.blank?
          return nil
        end
        if %w[Y YES 1 TRUE].include?(normalized)
          return "Y"
        end
        if %w[N NO 0 FALSE].include?(normalized)
          return "N"
        end
        normalized
      end

      def normalize_string(value, upcase: false)
        text = value.to_s.strip
        if text.blank?
          return nil
        end

        if upcase
          text.upcase
        else
          text
        end
      end

      def validate_row(row)
        errors = []

        REQUIRED_FIELDS.each do |required_field|
          if row[required_field].blank?
            errors << "#{human_header(required_field)}는 필수입니다."
          end
        end

        if row[:qty].present? && row[:qty] <= 0
          errors << "수량은 0보다 커야 합니다."
        end
        if row[:wgt].present? && row[:wgt] < 0
          errors << "중량은 0 이상이어야 합니다."
        end
        if row[:vol].present? && row[:vol] < 0
          errors << "부피는 0 이상이어야 합니다."
        end

        if row[:strt_req_ymd].present? && row[:aptd_req_ymd].present?
          if row[:aptd_req_ymd] < row[:strt_req_ymd]
            errors << "납기요청일자는 시작요청일자보다 빠를 수 없습니다."
          end
        end

        errors
      end

      def format_row_for_grid(row)
        {
          succ_yn: row[:succ_yn],
          err_msg: row[:err_msg],
          seq: row[:seq],
          bef_ord_no: row[:bef_ord_no],
          ord_no: row[:ord_no],
          cust_cd: row[:cust_cd],
          cust_ord_no: row[:cust_ord_no],
          ord_req_cust_cd: row[:ord_req_cust_cd],
          bilg_cust_cd: row[:bilg_cust_cd],
          cust_ofcr_nm: row[:cust_ofcr_nm],
          cust_ofcr_tel_no: row[:cust_ofcr_tel_no],
          ord_type_cd: row[:ord_type_cd],
          cust_expr_yn: row[:cust_expr_yn],
          retrngd_yn: row[:retrngd_yn],
          cargo_form_cd: row[:cargo_form_cd],
          cust_bzac_cd: row[:cust_bzac_cd],
          dpt_ar_cd: row[:dpt_ar_cd],
          dpt_ar_type_cd: row[:dpt_ar_type_cd],
          dpt_ar_zip_cd: row[:dpt_ar_zip_cd],
          strt_req_ymd: row[:strt_req_ymd]&.strftime("%Y-%m-%d"),
          aptd_req_ymd: row[:aptd_req_ymd]&.strftime("%Y-%m-%d"),
          arv_ar_cd: row[:arv_ar_cd],
          arv_ar_type_cd: row[:arv_ar_type_cd],
          arv_ar_zip_cd: row[:arv_ar_zip_cd],
          line_no: row[:line_no],
          item_cd: row[:item_cd],
          item_nm: row[:item_nm],
          qty: row[:qty]&.to_f,
          qty_unit_cd: row[:qty_unit_cd],
          wgt: row[:wgt]&.to_f,
          wgt_unit_cd: row[:wgt_unit_cd],
          vol: row[:vol]&.to_f,
          vol_unit_cd: row[:vol_unit_cd]
        }
      end

      def human_header(field_key)
        definition = FIELD_DEFINITIONS.find do |field|
          field[:key] == field_key
        end
        if definition.present?
          definition[:header]
        else
          field_key.to_s
        end
      end

      def human_headers(field_keys)
        field_keys.map do |key|
          human_header(key)
        end
      end

      def build_preview_message(parsed)
        "총 #{parsed[:total_count]}건, 성공 #{parsed[:success_count]}건, 오류 #{parsed[:error_count]}건"
      end

      def summary_hash(parsed)
        {
          total_count: parsed[:total_count],
          success_count: parsed[:success_count],
          error_count: parsed[:error_count]
        }
      end

      def failure_result(parsed, message, batch_no: nil)
        {
          success: false,
          message: message,
          batch_no: batch_no,
          rows: parsed[:rows],
          summary: summary_hash(parsed),
          can_save: false
        }
      end

      def persist_failed_batch(parsed)
        batch_no = build_batch_no
        first_valid = parsed[:raw_rows].find { |row| row[:cust_cd].present? }

        batch = OmPreOrderUploadBatch.new(
          upload_batch_no: batch_no,
          file_nm: original_filename,
          upload_stat_cd: "FAILED",
          error_cnt: parsed[:error_count],
          cust_cd: first_valid&.dig(:cust_cd),
          cust_nm: customer_name_for(first_valid&.dig(:cust_cd)),
          use_yn: "Y"
        )
        batch.save!

        parsed[:raw_rows].each do |row|
          if row[:succ_yn] == "Y"
            next
          end
          OmPreOrderError.create!(
            upload_batch_no: batch_no,
            line_no: row[:line_no].to_i,
            err_type_cd: "VALIDATION",
            err_msg: row[:err_msg],
            cust_ord_no: row[:cust_ord_no],
            item_cd: row[:item_cd],
            resolved_yn: "N",
            use_yn: "Y"
          )
        end

        batch_no
      end

      def persist_success_batch(parsed)
        batch_no = build_batch_no
        created_order_count = 0
        updated_order_count = 0

        ActiveRecord::Base.transaction do
          first_row = parsed[:raw_rows].first
          batch = OmPreOrderUploadBatch.new(
            upload_batch_no: batch_no,
            file_nm: original_filename,
            upload_stat_cd: "SUCCESS",
            error_cnt: 0,
            cust_cd: first_row[:cust_cd],
            cust_nm: customer_name_for(first_row[:cust_cd]),
            use_yn: "Y"
          )
          batch.save!

          parsed[:raw_rows].each do |row|
            reception = upsert_pre_order_reception(row)
            order, was_new = upsert_order(row, reception)
            if was_new
              created_order_count += 1
            else
              updated_order_count += 1
            end

            reception.update!(status_cd: OmPreOrderReception::STATUS_ORDER_CREATED)
          end
        end

        {
          success: true,
          message: "사전오더 파일 업로드 저장이 완료되었습니다.",
          batch_no: batch_no,
          rows: parsed[:rows],
          summary: summary_hash(parsed),
          can_save: false,
          data: {
            created_order_count: created_order_count,
            updated_order_count: updated_order_count
          }
        }
      end

      def upsert_pre_order_reception(row)
        reception = OmPreOrderReception.find_or_initialize_by(bef_ord_no: row[:bef_ord_no])
        reception.assign_attributes(
          cust_cd: row[:cust_cd],
          cust_nm: customer_name_for(row[:cust_cd]),
          cust_ord_no: row[:cust_ord_no],
          item_cd: row[:item_cd],
          item_nm: row[:item_nm],
          qty: row[:qty],
          wgt: row[:wgt],
          vol: row[:vol],
          use_yn: "Y",
          status_cd: OmPreOrderReception::STATUS_RECEIVED
        )
        reception.save!
        reception
      end

      def upsert_order(row, _reception)
        order = find_order(row)
        was_new = order.new_record?

        if order.ord_no.blank?
          order.ord_no = next_order_number
        end

        order.assign_attributes(
          cust_cd: row[:cust_cd],
          cust_nm: customer_name_for(row[:cust_cd]),
          cust_ord_no: row[:cust_ord_no],
          item_cd: row[:item_cd],
          item_nm: row[:item_nm],
          ord_qty: row[:qty],
          ord_wgt: row[:wgt],
          ord_vol: row[:vol],
          dpt_ar_cd: row[:dpt_ar_cd],
          arv_ar_cd: row[:arv_ar_cd],
          aptd_req_ymd: row[:aptd_req_ymd],
          billing_cust_cd: row[:bilg_cust_cd],
          contract_cust_cd: row[:ord_req_cust_cd],
          ord_stat_cd: OmPreOrderReception::STATUS_ORDER_CREATED,
          ord_type_cd: row[:ord_type_cd].presence || "PRE_ORDER",
          ord_type_nm: "Pre Order Upload",
          work_stat_cd: "WAITING",
          use_yn: "Y"
        )
        order.save!

        [ order, was_new ]
      end

      def find_order(row)
        if row[:ord_no].present?
          return OmOrder.find_or_initialize_by(ord_no: row[:ord_no])
        end

        existing = OmOrder.active.where(cust_ord_no: row[:cust_ord_no], item_cd: row[:item_cd]).ordered_recent.first
        if existing.present?
          existing
        else
          OmOrder.new
        end
      end

      def next_order_number
        10.times do
          candidate = "PO#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.random_number(10_000).to_s.rjust(4, '0')}"
          if OmOrder.exists?(ord_no: candidate)
            next
          end
          return candidate
        end

        "PO#{SecureRandom.hex(8).upcase}"
      end

      def build_batch_no
        "BATCH#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.random_number(10_000).to_s.rjust(4, '0')}"
      end

      def customer_name_for(cust_cd)
        if cust_cd.blank?
          return nil
        end
        if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
          return cust_cd
        end

        StdBzacMst.find_by(bzac_cd: cust_cd.to_s.strip.upcase)&.bzac_nm.to_s.strip.presence || cust_cd
      rescue ActiveRecord::StatementInvalid
        cust_cd
      end
  end
end
