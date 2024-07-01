class AssistanceRequest < ApplicationRecord
  belongs_to :account
  validates :description, presence: true
  validates :status, inclusion: { in: %w[Pending In\ Progress Resolved] }
end
