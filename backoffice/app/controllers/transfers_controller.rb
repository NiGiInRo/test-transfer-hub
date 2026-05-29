class TransfersController < ApplicationController
  def create
    existing = Transfer.find_by(idempotency_key: transfer_params[:idempotency_key])
    return render json: transfer_payload(existing), status: :ok if existing

    transfer = Transfer.new(transfer_params)

    if transfer.save
      TransferJob.perform_later(transfer.id)
      render json: transfer_payload(transfer), status: :created
    else
      render json: { errors: transfer.errors.to_hash(true) }, status: :unprocessable_entity
    end
  end

  def show
    transfer = Transfer.find_by(id: params[:id])
    return render json: { error: "Transfer not found" }, status: :not_found unless transfer

    render json: transfer_payload(transfer), status: :ok
  end

  private

  def transfer_params
    params.require(:transfer).permit(:user_id, :amount, :idempotency_key)
  end

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
