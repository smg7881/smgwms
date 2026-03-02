class System::BaseController < ApplicationController
  before_action :require_admin!

  private
    def normalized_code(value)
      value.to_s.strip.upcase
    end

    def normalized_code_param(key)
      normalized_code(params[key])
    end

    def render_success(message:, payload: {})
      render json: { success: true, message: message }.merge(payload)
    end

    def render_failure(errors:, status: :unprocessable_entity)
      normalized_errors = Array(errors).flatten.compact.map(&:to_s).reject(&:blank?)
      render json: { success: false, errors: normalized_errors }, status: status
    end

    def parse_time_param(value)
      return nil if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError, TypeError
      nil
    end
end
