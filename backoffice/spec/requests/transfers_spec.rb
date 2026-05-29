require "rails_helper"

RSpec.describe "Transfers", type: :request do
  describe "POST /transfers" do
    let(:valid_params) do
      {
        transfer: {
          user_id: 1,
          amount: 50_000,
          idempotency_key: "unique-key-123"
        }
      }
    end

    it "crea una transferencia en estado pending" do
      allow(TransferJob).to receive(:perform_later)

      post "/transfers", params: valid_params, as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["status"]).to eq("pending")
    end

    it "encola el job de Sidekiq al crear" do
      expect(TransferJob).to receive(:perform_later)

      post "/transfers", params: valid_params, as: :json
    end

    it "retorna la transferencia existente si el idempotency_key ya existe" do
      existing = create(:transfer, idempotency_key: "unique-key-123")

      post "/transfers", params: valid_params, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(existing.id)
    end

    it "no crea un registro duplicado con el mismo idempotency_key" do
      create(:transfer, idempotency_key: "unique-key-123")

      expect {
        post "/transfers", params: valid_params, as: :json
      }.not_to change(Transfer, :count)
    end

    it "retorna 422 si faltan parámetros requeridos" do
      post "/transfers", params: { transfer: { user_id: 1 } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /transfers/:id" do
    it "retorna la transferencia correcta" do
      transfer = create(:transfer)

      get "/transfers/#{transfer.id}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(transfer.id)
    end

    it "retorna 404 si no existe" do
      get "/transfers/99999"

      expect(response).to have_http_status(:not_found)
    end
  end
end
