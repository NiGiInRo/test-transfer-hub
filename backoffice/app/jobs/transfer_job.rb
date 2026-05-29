class TransferJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  discard_on ActiveRecord::RecordNotFound

  sidekiq_retries_exhausted do |job, _exception|
    transfer = Transfer.find_by(id: job["args"].first)
    transfer&.failed!
  end

  def perform(transfer_id)
    transfer = Transfer.find(transfer_id)
    return if transfer.final?

    transfer.processing!

    response = HTTParty.post(
      "#{ENV.fetch('CORE_BANCARIO_URL', 'http://localhost:8000')}/process_transfer",
      body: {
        transfer_id: transfer.id,
        amount: transfer.amount.to_f,
        idempotency_key: transfer.idempotency_key
      }.to_json,
      headers: { "Content-Type" => "application/json" },
      timeout: 30
    )

    raise "Core bancario respondió #{response.code}" unless response.success?
  end
end
