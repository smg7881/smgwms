module Excel
  module Handlers
    class BaseHandler
      def headers
        raise NotImplementedError, "Subclasses must implement headers"
      end

      def filename_prefix
        raise NotImplementedError, "Subclasses must implement filename_prefix"
      end

      def export_rows(_records)
        raise NotImplementedError, "Subclasses must implement export_rows"
      end

      def import_row!(_row_hash)
        raise NotImplementedError, "Subclasses must implement import_row!"
      end

      def acceptable_headers
        [ headers ]
      end

      def sheet_name
        filename_prefix
      end

      protected
        def normalized_string(value)
          value.to_s.strip.presence
        end

        def parse_date(value)
          return nil if value.blank?

          if value.is_a?(Date)
            value
          elsif value.is_a?(Time) || value.is_a?(DateTime)
            value.to_date
          else
            Date.parse(value.to_s)
          end
        rescue ArgumentError
          nil
        end
    end
  end
end
