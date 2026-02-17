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
  validates :ref_code, length: { maximum: 50 }, allow_blank: true
  validates :sort_order, numericality: { only_integer: true }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:sort_order, :detail_code) }

  private
    def normalize_fields
      self.code = code.to_s.strip.upcase
      self.detail_code = detail_code.to_s.strip.upcase
      self.detail_code_name = detail_code_name.to_s.strip
      self.short_name = short_name.to_s.strip.presence
      self.ref_code = ref_code.to_s.strip.upcase.presence
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
