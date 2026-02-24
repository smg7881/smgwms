class AdmCodeDetail < ApplicationRecord
  self.table_name = "adm_code_details"

  belongs_to :header,
             class_name: "AdmCodeHeader",
             foreign_key: :code,
             primary_key: :code,
             inverse_of: :details

  validates :code, presence: true, length: { maximum: 50 }
  validates :detail_code, presence: true, length: { maximum: 50 }, uniqueness: { scope: :code }
  validates :detail_code_name, presence: true, length: { maximum: 100 }
  validates :short_name, length: { maximum: 100 }, allow_blank: true
  validates :upper_code, length: { maximum: 50 }, allow_blank: true
  validates :upper_detail_code, length: { maximum: 50 }, allow_blank: true
  validates :rmk, length: { maximum: 500 }, allow_blank: true
  validates :attr1, length: { maximum: 200 }, allow_blank: true
  validates :attr2, length: { maximum: 200 }, allow_blank: true
  validates :attr3, length: { maximum: 200 }, allow_blank: true
  validates :attr4, length: { maximum: 200 }, allow_blank: true
  validates :attr5, length: { maximum: 200 }, allow_blank: true
  validates :sort_order, numericality: { only_integer: true }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:sort_order, :detail_code) }
  scope :active, -> { where(use_yn: "Y") }

  def self.select_options_for(code, include_all: false, all_label: "전체", value_transform: nil)
    normalized_code = code.to_s.strip.upcase
    options = []

    if normalized_code.present?
      options = active.where(code: normalized_code).ordered.pluck(:detail_code_name, :detail_code).map do |name, value|
        {
          label: name,
          value: normalize_option_value(value, value_transform)
        }
      end
    end

    if include_all
      [ { label: all_label, value: "" } ] + options
    else
      options
    end
  end

  def self.select_values_for(code, value_transform: nil)
    select_options_for(code, value_transform: value_transform).map { |option| option[:value] }
  end

  private
    def self.normalize_option_value(value, value_transform)
      converted = value.to_s

      if value_transform.present?
        converted.public_send(value_transform)
      else
        converted
      end
    end
    private_class_method :normalize_option_value

    def normalize_fields
      self.code = code.to_s.strip.upcase
      self.detail_code = detail_code.to_s.strip.upcase
      self.detail_code_name = detail_code_name.to_s.strip
      self.short_name = short_name.to_s.strip.presence
      self.upper_code = upper_code.to_s.strip.upcase.presence
      self.upper_detail_code = upper_detail_code.to_s.strip.upcase.presence
      self.rmk = rmk.to_s.strip.presence
      self.attr1 = attr1.to_s.strip.presence
      self.attr2 = attr2.to_s.strip.presence
      self.attr3 = attr3.to_s.strip.presence
      self.attr4 = attr4.to_s.strip.presence
      self.attr5 = attr5.to_s.strip.presence
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"

      if sort_order.nil?
        self.sort_order = 0
      end
    end

    def assign_audit_fields
      actor = current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_create_fields
      actor = current_actor
      self.create_by = actor
      self.create_time = Time.current
    end

    def current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
