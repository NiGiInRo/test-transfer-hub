Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :transfers, only: [ :create, :show ]
  post "/webhooks/transfer_result", to: "webhooks#transfer_result"
end
