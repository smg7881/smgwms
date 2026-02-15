Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ]

  root "dashboard#show"

  resources :tabs, only: [ :create, :destroy ] do
    scope module: :tabs do
      resource :activation, only: [ :create ]
    end
  end

  resources :posts
  resources :reports, only: [ :index ]
  namespace :system do
    resources :dept, controller: :dept, only: [ :index, :show, :create, :update, :destroy ]
    resources :menus, only: [ :index, :create, :update, :destroy ]
    resources :users do
      get :check_id, on: :collection
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
