Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :generations, only: [:index, :show, :create]
  resources :accounts, only: [:index, :show, :create]
  resources :generators, only: [:index, :show, :create]
  resources :certificate_quantities, only: [:index, :show, :create]

  # Defines the root path route ("/")
  # root "posts#index"
end
