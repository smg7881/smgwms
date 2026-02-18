module Excel
  class UploadValidator
    ALLOWED_EXTENSIONS = %w[csv xlsx].freeze
    MAX_FILE_SIZE = 10.megabytes

    Result = Struct.new(:valid, :errors, :extension, keyword_init: true)

    def initialize(file)
      @file = file
    end

    def call
      errors = []
      extension = nil

      if file.blank?
        errors << "파일을 선택해 주세요."
      else
        extension = File.extname(file.original_filename.to_s).delete(".").downcase
        if ALLOWED_EXTENSIONS.exclude?(extension)
          errors << "허용되지 않는 파일 형식입니다. (csv, xlsx)"
        end

        if file.size.to_i > MAX_FILE_SIZE
          errors << "파일 크기는 10MB 이하여야 합니다."
        end
      end

      Result.new(valid: errors.empty?, errors: errors, extension: extension)
    end

    private
      attr_reader :file
  end
end
