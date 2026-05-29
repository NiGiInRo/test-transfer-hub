class TransferJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(transfer_id)
    # HU-05: lógica de llamada al core bancario
  end
end
