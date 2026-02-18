module SearchFormHelper
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

  # ── span → Tailwind CSS 클래스 변환 ──
  # 필드의 span 설정을 Tailwind Grid 클래스로 변환합니다.
  #
  # span이 없으면 cols 기반으로 기본값 생성:
  #   cols: 3 → "col-span-24 sm:col-span-12 md:col-span-8"
  #   cols: 4 → "col-span-24 sm:col-span-12 md:col-span-6"
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
    # span 문자열 파싱: "24 s:12 m:8 l:6" → Tailwind CSS 클래스 문자열
    def parse_span_string(span_str)
      classes = []
      prefix_map = { "" => "col-span", "s" => "sm:col-span", "m" => "md:col-span", "l" => "lg:col-span" }

      span_str.to_s.split.each do |token|
        if token.include?(":")
          prefix, value = token.split(":", 2)
          css_prefix = prefix_map[prefix]
          classes << "#{css_prefix}-#{value}" if css_prefix
        else
          classes << "col-span-#{token}"
        end
      end

      classes.join(" ")
    end

    # cols 기반 기본 span 클래스 생성
    def default_span_classes(cols)
      case cols
      when 1
        "col-span-24"
      when 4
        "col-span-24 sm:col-span-12 md:col-span-6"
      when 2
        "col-span-24 sm:col-span-12"
      else # 3 (기본)
        "col-span-24 sm:col-span-12 md:col-span-8"
      end
    end
end
