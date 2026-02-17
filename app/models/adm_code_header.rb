class AdmCodeHeader < ApplicationRecord
  self.table_name = "adm_code_headers"

  has_many :details,
           class_name: "AdmCodeDetail",
           foreign_key: :code,
           primary_key: :code,
           inverse_of: :header,
           dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :code_name, presence: true, length: { maximum: 100 }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:code) }

  private
    def normalize_fields
      self.code = code.to_s.strip.upcase
      self.code_name = code_name.to_s.strip
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
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
