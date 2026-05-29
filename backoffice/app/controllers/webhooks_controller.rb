class WebhooksController < ApplicationController
  def transfer_result
    transfer = Transfer.find_by(id: params[:transfer_id])
    return render json: { error: "Transfer not found" }, status: :not_found unless transfer

    return render json: transfer_payload(transfer), status: :ok if transfer.final?

    if transfer.update(status: params[:status])
      render json: transfer_payload(transfer), status: :ok
    else
      render json: { errors: transfer.errors.to_hash(true) }, status: :unprocessable_entity
    end
  end

  private

  def transfer_payload(transfer)
    {
      id: transfer.id,
      user_id: transfer.user_id,
      amount: transfer.amount,
      idempotency_key: transfer.idempotency_key,
      status: transfer.status,
      created_at: transfer.created_at,
      updated_at: transfer.updated_at
    }
  end
end
