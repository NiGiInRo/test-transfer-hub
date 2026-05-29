class Transfer < ApplicationRecord
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :user_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :idempotency_key, presence: true, uniqueness: true

  def final?
    completed? || failed?
  end
end
