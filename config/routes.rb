Rails.application.routes.draw do
  devise_for :users, skip: [:sessions, :registrations]

  devise_scope :user do
    get 'sign-in', to: 'home#index', as: :new_user_session, defaults: { popup_login: true }
    post 'sign-in', to: 'sessions#create', as: :user_session
    delete 'sign-out', to: 'sessions#destroy', as: :destroy_user_session
    post 'sign-up', to: 'registrations#create', as: :user_registration
    put 'my-details', to: 'registrations#update', as: :user_profile
  end

  ActiveAdmin.routes(self)
  namespace :admin do
    resources :countries do
      resources :misspellings
    end
    resources :manufacturers do
      resources :misspellings
    end
    resources :models do
      resources :misspellings
    end
    resources :engine_manufacturers do
      resources :misspellings
    end
    resources :engine_models do
      resources :misspellings
    end
    resources :specifications do
      resources :misspellings
    end
    resources :fuel_types do
      resources :misspellings
    end
    resources :boat_types do
      resources :misspellings
    end
    resources :boat_categories do
      resources :misspellings
    end
    resources :drive_types do
      resources :misspellings
    end
    resources :vat_rates do
      resources :misspellings
    end
  end

  root to: 'home#index'

  controller :search do
    get 'manufacturer-model',
        action: :manufacturer_model,
        constraints: { format: :json }

    get 'suggestion(/:source_type)',
        action: 'suggestion',
        constraints: {
          format: :json,
          source_type: /country|manufacturer|model/
        }
    get 'manufacturer_model'
  end

  put 'session-settings', to: 'session_settings#change', constraints: { format: :json }

  get 'news(/category/:category_id)', to: 'articles#index', as: :articles
  resources :articles, only: [:show], path: :news
  resources :buyer_guides, only: [:index, :show]
  resources :feedbacks, only: [:create]
  resources :mail_subscriptions, only: [:create]
  resources :marine_enquiries, only: [:create]

  get 'search', to: 'search#results'
  post 'boats/:boat_id/request-details', to: 'enquiries#create'
  get 'captcha', to: 'captcha#image'
  get 'captcha/new', to: 'captcha#new'

  get 'contact', to: 'home#contact', as: :contact
  get 'toc', to: 'home#toc', as: :toc
  get 'marine_services', to: 'home#marine_services', as: :marine_services
  get 'privacy_policy', to: 'home#privacy_policy', as: :privacy_policy
  get 'cookies_policy', to: 'home#cookies_policy', as: :cookies_policy

  namespace :api, defaults: {format: :json}, constraints: {format: :json} do
    controller :manufacturers, path: 'manufacturers' do
      get ':id/models', action: :models
    end
  end

  resources :boats, path: 'boats-for-sale', only: [:index, :show] do
    get :pdf
  end
  resources :manufacturers, path: 'manufacturer', only: [:index, :show]
  get 'manufacturers-by-letter/:id', to: 'manufacturers#by_letter', as: :manufacturers_by_letter
  resources :boat_types, path: 'boat-type', only: [:index, :show]
  resources :countries, path: 'location', only: [:index, :show]
  resources :models, only: [:index, :show]

  get 'leads/:id', to: 'enquiries#show', as: :lead
  post 'leads/:id/approve', to: 'enquiries#approve', as: :lead_approve
  post 'leads/:id/quality_check', to: 'enquiries#quality_check', as: :quality_check
  get 'test-email', to: 'testing#test_email'

  resource :broker, controller: :broker, only: [:show]

  namespace :member, path: 'my-rightboat' do
    root to: 'dashboard#index'
    get 'favourites', to: 'favourites#index', as: :favourites
    post 'favourites', to: 'favourites#create', as: :favourite, constraints: { format: :json }
    resource :user_alert, controller: :user_alert, path: 'alerts', only: [:show, :update]
    resources :saved_searches, path: 'saved-searches', only: [:index, :create, :destroy] do
      post :toggle, on: :member
    end
    controller :dashboard do
      get :enquiries
      get :information
      get :search_histories
    end
  end
end
