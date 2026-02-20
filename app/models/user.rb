class User < ApplicationRecord
  self.table_name = "adm_users"

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :menu_permissions, class_name: "AdmUserMenuPermission", dependent: :destroy
  has_one_attached :photo
  belongs_to :dept, class_name: "AdmDept", optional: true
  belongs_to :role, class_name: "AdmRole", optional: true

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :user_id_code, uniqueness: true, allow_blank: true,
            format: { with: /\A[a-zA-Z0-9]{4,16}\z/, message: "must be alphanumeric 4-16 chars" }
  validates :user_nm, length: { maximum: 20 }
  validates :work_status, inclusion: { in: %w[ACTIVE RESIGNED] }, allow_blank: true
  validates :phone, format: { with: /\A010-\d{4}-\d{4}\z/ }, allow_blank: true
  validate :resign_date_after_hire_date
  before_validation :sync_dept_name_from_dept

  scope :active, -> { where(work_status: "ACTIVE") }
  scope :ordered, -> { order(:user_nm) }

  def role_cd
    role&.role_cd
  end

  def role_cd=(value)
    normalized = value.to_s.strip.upcase
    self.role = if normalized.present?
      AdmRole.find_by(role_cd: normalized)
    else
      nil
    end
  end

  def dept_cd
    dept&.dept_code
  end

  def dept_cd=(value)
    normalized = value.to_s.strip.upcase
    if normalized.present?
      self.dept = AdmDept.find_by(dept_code: normalized)
      self.dept_nm = dept&.dept_nm
    else
      self.dept = nil
    end
  end

  private

  def sync_dept_name_from_dept
    self.dept_nm = dept.dept_nm if dept.present?
  end

  def resign_date_after_hire_date
    if resign_date.present? && hire_date.present? && resign_date < hire_date
      errors.add(:resign_date, "must be on or after hire_date")
    end
  end
end
