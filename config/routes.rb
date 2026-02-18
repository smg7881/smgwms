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
    resources :excel_import_tasks, only: [ :index ] do
      member do
        get :error_report
      end
    end

    resources :dept, controller: :dept, only: [ :index, :show, :create, :update, :destroy ] do
      collection do
        get :excel_template
        get :excel_export
        post :excel_import
      end
    end
    resources :menus, only: [ :index, :create, :update, :destroy ]
    resources :code, controller: :code, only: [ :index, :create, :update, :destroy ], param: :id do
      post :batch_save, on: :collection
      resources :details, controller: :code_details, only: [ :index, :create, :update, :destroy ], param: :detail_code do
        post :batch_save, on: :collection
      end
    end
    resources :users do
      get :check_id, on: :collection
      collection do
        get :excel_template
        get :excel_export
        post :excel_import
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
