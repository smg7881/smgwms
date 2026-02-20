class AdmNotice < ApplicationRecord
  self.table_name = "adm_notices"

  has_many_attached :attachments

  validates :category_code, presence: true, length: { maximum: 50 }
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :is_top_fixed, inclusion: { in: %w[Y N] }
  validates :is_published, inclusion: { in: %w[Y N] }
  validates :view_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :end_date_after_start_date

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(is_top_fixed: :desc, create_time: :desc, id: :desc) }

  private
    def normalize_fields
      self.category_code = category_code.to_s.strip.upcase
      self.title = title.to_s.strip
      self.content = content.to_s.strip
      self.is_top_fixed = is_top_fixed.to_s.strip.upcase.presence || "N"
      self.is_published = is_published.to_s.strip.upcase.presence || "Y"
      self.view_count = 0 if view_count.nil?
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

    def end_date_after_start_date
      if start_date.present? && end_date.present? && end_date < start_date
        errors.add(:end_date, "must be on or after start_date")
      end
    end
end
