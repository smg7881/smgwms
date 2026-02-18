class ExcelImportTask < ApplicationRecord
  STATUSES = %w[queued processing completed completed_with_errors failed].freeze

  belongs_to :requested_by, class_name: "User", optional: true

  has_one_attached :source_file
  has_one_attached :error_report

  validates :resource_key, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }
end
