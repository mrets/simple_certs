Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :generations, only: [:index, :show, :create]
  resources :accounts, only: [:index, :show, :create]
  resources :generators, only: [:index, :show, :create]
  resources :certificate_quantities, only: [:index, :show]
  resources :certificates, only: [:index, :show]
end
