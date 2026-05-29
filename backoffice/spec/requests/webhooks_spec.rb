require "rails_helper"

RSpec.describe "POST /webhooks/transfer_result", type: :request do
  let(:transfer) { create(:transfer, status: :processing) }

  describe "idempotencia" do
    it "actualiza a completed cuando está en processing" do
      post "/webhooks/transfer_result", params: {
        transfer_id: transfer.id,
        status: "completed",
        idempotency_key: transfer.idempotency_key
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(transfer.reload.status).to eq("completed")
    end

    it "no modifica el registro si ya está en completed" do
      transfer.completed!

      post "/webhooks/transfer_result", params: {
        transfer_id: transfer.id,
        status: "failed",
        idempotency_key: transfer.idempotency_key
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(transfer.reload.status).to eq("completed")
    end

    it "no modifica el registro si ya está en failed" do
      transfer.failed!

      post "/webhooks/transfer_result", params: {
        transfer_id: transfer.id,
        status: "completed",
        idempotency_key: transfer.idempotency_key
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(transfer.reload.status).to eq("failed")
    end

    it "llamado dos veces con el mismo payload produce el mismo resultado" do
      payload = {
        transfer_id: transfer.id,
        status: "completed",
        idempotency_key: transfer.idempotency_key
      }

      post "/webhooks/transfer_result", params: payload, as: :json
      post "/webhooks/transfer_result", params: payload, as: :json

      expect(response).to have_http_status(:ok)
      expect(transfer.reload.status).to eq("completed")
    end
  end

  it "retorna 404 si la transferencia no existe" do
    post "/webhooks/transfer_result", params: {
      transfer_id: 99999,
      status: "completed",
      idempotency_key: "no-existe"
    }, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
