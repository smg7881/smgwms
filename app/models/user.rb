class User < ApplicationRecord
  self.table_name = "adm_users"

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one_attached :photo

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :user_id_code, uniqueness: true, allow_blank: true,
            format: { with: /\A[a-zA-Z0-9]{4,16}\z/, message: "영문/숫자 4-16자" }
  validates :user_nm, length: { maximum: 20 }
  validates :work_status, inclusion: { in: %w[ACTIVE RESIGNED] }, allow_blank: true
  validates :phone, format: { with: /\A010-\d{4}-\d{4}\z/ }, allow_blank: true
  validate :resign_date_after_hire_date

  scope :active, -> { where(work_status: "ACTIVE") }
  scope :ordered, -> { order(:user_nm) }

  private
    def resign_date_after_hire_date
      if resign_date.present? && hire_date.present? && resign_date < hire_date
        errors.add(:resign_date, "퇴사일은 입사일 이후여야 합니다.")
      end
    end
end
