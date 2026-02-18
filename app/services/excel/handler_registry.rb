module Excel
  class HandlerRegistry
    def self.fetch(key)
      case key.to_s
      when "users"
        Excel::Handlers::UsersHandler.new
      when "dept"
        Excel::Handlers::DeptHandler.new
      else
        raise ArgumentError, "Unknown excel handler key: #{key}"
      end
    end
  end
end
