class AssistanceRequest < ApplicationRecord
  belongs_to :account

  validates :message, presence: true
  validates :status, presence: true, inclusion: { in: %w(Altro Transazioni Corsi Account) }
end
