Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :generations, only: [ :index, :show, :create ]
  resources :accounts, only: [ :index, :show, :create ]
  resources :organizations, only: [ :index ]
  resources :generators, only: [ :index, :show, :create ]
  resources :certificates, only: [ :index, :show ]
  resources :certificate_quantities, only: [ :index, :show ] do
    member do
      put :retire
      put :transfer
      put :cancel_transfer
      put :accept_transfer
      put :split
    end
  end
end
