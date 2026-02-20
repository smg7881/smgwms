Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ]

  root "dashboard#show"

  resources :tabs, only: [ :create, :destroy ] do
    collection do
      delete :close_all
      delete :close_others
    end

    member do
      patch :move_left
      patch :move_right
    end

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
    resources :menu_logs, only: [ :index ]
    resources :login_histories, only: [ :index ]
    resources :code, controller: :code, only: [ :index, :create, :update, :destroy ], param: :id do
      post :batch_save, on: :collection
      resources :details, controller: :code_details, only: [ :index, :create, :update, :destroy ], param: :detail_code do
        post :batch_save, on: :collection
      end
    end
    resources :notice, controller: :notice, only: [ :index, :show, :create, :update, :destroy ] do
      delete :bulk_destroy, on: :collection
    end
    resources :roles, only: [ :index, :create, :update, :destroy ], param: :id do
      post :batch_save, on: :collection
    end
    resources :role_user, controller: :role_user, path: "roleUser", only: [ :index ] do
      collection do
        get :available_users
        get :assigned_users
        post :save_assignments
      end
    end
    resources :user_menu_role, controller: :user_menu_role, path: "userMenuRole", only: [ :index ] do
      collection do
        get :users
        get :roles_by_user
        get :menus_by_user_role
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

  namespace :wm do
    resources :workplace, controller: :workplace, only: [ :index ] do
      post :batch_save, on: :collection
    end
    resources :area, controller: :area, only: [ :index ] do
      post :batch_save, on: :collection
    end
    resources :zone, controller: :zone, only: [ :index ] do
      get :zones, on: :collection
      post :batch_save, on: :collection
    end
    resources :location, controller: :location, only: [ :index ] do
      get :areas, on: :collection
      get :zones, on: :collection
      post :batch_save, on: :collection
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
