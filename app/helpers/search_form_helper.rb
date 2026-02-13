module SearchFormHelper
  # ── 허용된 필드 속성 목록 (White List) ──
  # 보안 및 데이터 무결성을 위해, 클라이언트로 전달될 필드 정의 객체에서
  # 허용할 키(Key)들을 명시적으로 정의합니다.
  ALLOWED_FIELD_KEYS = %i[
    field type label label_key placeholder placeholder_key
    span options required clearable disabled
    pattern minlength maxlength inputmode autocomplete
    date_type date_format min max
    popup_type code_field
    include_blank help
  ].freeze

  # 필드 이름 검증용 정규식 (영문, 숫자, 언더스코어만 허용)
  VALID_FIELD_NAME = /\A[a-zA-Z0-9_]+\z/

  # 지원하는 필드 타입 목록
  FIELD_TYPES = %w[input select date_picker date_range popup].freeze

  # ── 메인 헬퍼 메서드 ──
  # 뷰에서 검색 폼을 선언적으로 생성하기 위한 헬퍼입니다.
  #
  # @param fields [Array<Hash>] 필드 정의 배열 (필수)
  # @param url [String] 폼 action URL (필수)
  # @param turbo_frame [String] Turbo Frame ID (기본값: "main-content")
  # @param cols [Integer] 그리드 컬럼 수 (기본값: 3)
  # @param enable_collapse [Boolean] 접기/펼치기 활성화 여부 (기본값: true)
  # @param collapsed_rows [Integer] 접힌 상태에서 보이는 행 수 (기본값: 1)
  # @param show_buttons [Boolean] 버튼 표시 여부 (기본값: true)
  # @param html_options [Hash] 래퍼 div에 적용할 추가 HTML 속성
  #
  # @example 사용 예시
  #   <%= search_form_tag(
  #     url: posts_path,
  #     fields: [
  #       { field: "title", type: "input", label: "제목", placeholder: "제목 검색..." },
  #       { field: "created_at", type: "date_range", label: "작성일" }
  #     ],
  #     cols: 3,
  #     enable_collapse: false
  #   ) %>
  def search_form_tag(fields:, url:, turbo_frame: "main-content",
                      cols: 3, enable_collapse: true, collapsed_rows: 1,
                      show_buttons: true, **html_options)
    safe_fields = sanitize_field_defs(fields)

    render partial: "shared/search_form/form", locals: {
      fields: safe_fields,
      url: url,
      turbo_frame: turbo_frame,
      cols: cols,
      enable_collapse: enable_collapse,
      collapsed_rows: collapsed_rows,
      show_buttons: show_buttons,
      html_options: html_options
    }
  end

  # ── params 접근 헬퍼 ──
  # 검색 쿼리 파라미터(`q`) 전체를 반환합니다.
  def q_params
    params.fetch(:q, {})
  end

  # 특정 검색 필드의 현재 값을 반환합니다.
  def q_value(name)
    q_params[name.to_s]
  end

  # ── i18n 해석 ──
  # label 우선순위: label > label_key(I18n.t) > field.humanize
  def resolve_label(field)
    if field[:label].present?
      field[:label]
    elsif field[:label_key].present?
      I18n.t(field[:label_key])
    else
      field[:field].to_s.humanize
    end
  end

  # placeholder 우선순위: placeholder > placeholder_key(I18n.t) > nil
  def resolve_placeholder(field)
    if field[:placeholder].present?
      field[:placeholder]
    elsif field[:placeholder_key].present?
      I18n.t(field[:placeholder_key])
    end
  end

  # ── span → CSS 클래스 변환 ──
  # 필드의 span 설정을 CSS Grid 클래스로 변환합니다.
  #
  # span이 없으면 cols 기반으로 기본값 생성:
  #   cols: 3 → "sf-span-24 sf-span-sm-12 sf-span-md-8"
  #   cols: 4 → "sf-span-24 sf-span-sm-12 sf-span-md-6"
  #
  # span 문자열 형식: "24 s:12 m:8 l:6"
  def span_classes_for(field, cols:)
    if field[:span].present?
      parse_span_string(field[:span])
    else
      default_span_classes(cols)
    end
  end

  private
    # ── 필드 정의 정제 (Sanitization) ──
    # 입력받은 필드 정의 배열을 순회하며 허용된 키만 남기고 나머지는 제거합니다.
    def sanitize_field_defs(fields)
      fields.map do |field|
        field = field.symbolize_keys
        validate_field_name!(field[:field])

        sanitized = field.slice(*ALLOWED_FIELD_KEYS)
        sanitized[:type] = normalize_field_type(sanitized[:type])

        # validate code_field for popup type
        if sanitized[:type] == "popup"
          if sanitized[:code_field].blank?
            raise ArgumentError, "popup 필드에는 code_field가 필요합니다 (field: #{field[:field]})"
          end
          validate_field_name!(sanitized[:code_field])
        end

        rejected = field.keys - ALLOWED_FIELD_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[search_form_helper] 허용되지 않은 필드 키 제거: #{rejected.join(', ')} " \
            "(field: #{field[:field]})"
          )
        end

        sanitized
      end
    end

    # 필드 이름 검증 — 안전하지 않은 이름은 ArgumentError 발생
    def validate_field_name!(name)
      unless name.present? && name.to_s.match?(VALID_FIELD_NAME)
        raise ArgumentError, "유효하지 않은 필드 이름: #{name.inspect}"
      end
    end

    # 필드 타입 정규화 — 하이픈을 언더스코어로 변환
    def normalize_field_type(type)
      normalized = type.to_s.tr("-", "_")
      unless FIELD_TYPES.include?(normalized)
        raise ArgumentError, "지원하지 않는 필드 타입: #{type.inspect}"
      end
      normalized
    end

    # span 문자열 파싱: "24 s:12 m:8 l:6" → CSS 클래스 문자열
    def parse_span_string(span_str)
      classes = []
      prefix_map = { "" => "sf-span", "s" => "sf-span-sm", "m" => "sf-span-md", "l" => "sf-span-lg" }

      span_str.to_s.split.each do |token|
        if token.include?(":")
          prefix, value = token.split(":", 2)
          css_prefix = prefix_map[prefix]
          classes << "#{css_prefix}-#{value}" if css_prefix
        else
          classes << "sf-span-#{token}"
        end
      end

      classes.join(" ")
    end

    # cols 기반 기본 span 클래스 생성
    def default_span_classes(cols)
      case cols
      when 4
        "sf-span-24 sf-span-sm-12 sf-span-md-6"
      when 2
        "sf-span-24 sf-span-sm-12"
      else # 3 (기본)
        "sf-span-24 sf-span-sm-12 sf-span-md-8"
      end
    end
end
