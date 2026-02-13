Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ]

  root "dashboard#show"

  resources :tabs, only: [:create, :destroy] do
    scope module: :tabs do
      resource :activation, only: [:create]
    end
  end

  resources :posts
  resources :reports, only: [:index]

  get "up" => "rails/health#show", as: :rails_health_check
end
