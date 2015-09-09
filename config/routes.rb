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

  resources :manufacturers, only: [] do
    resources :models, only: [] do
      resources :boats, only: [:show]
    end
  end
  resources :feedbacks, only: [:create]
  resources :mail_subscriptions, only: [:create]

  get 'search', to: 'search#results'
  post 'boats/:boat_id/request-details', to: 'enquiries#create'
  get 'captcha', to: 'captcha#image'
  get 'captcha/new', to: 'captcha#new'

  get 'about', to: 'home#about', as: :about
  get 'contact', to: 'home#contact', as: :contact
  get 'toc', to: 'home#toc', as: :toc

  namespace :api, constraints: { format: :json } do
    controller :manufacturers, path: 'manufacturers' do
      get ':id/models', action: :models
    end
  end

  get 'boats-for-sale', to: 'boats_for_sale#index', as: :boats_for_sale
  get 'boats-for-sale/:manufacturer', to: 'boats_for_sale#manufacturer_boats', as: :manufacturer_boats
  get 'boats-for-sale/:manufacturer/:model', to: 'boats_for_sale#show_boat', as: :boat_for_sale
  get 'manufacturer/:manufacturer', to: 'boats_for_sale#manufacturer_boats', as: :manufacturer_boats_explicit
  get 'manufacturers-by-letter/:letter', to: 'boats_for_sale#manufacturers_by_letter', as: :manufacturers_by_letter
  get 'boat-type', to: 'boats_for_sale#boats_by_type_index', as: :boats_by_type_index
  get 'boat-type/:boat_type', to: 'boats_for_sale#boats_by_type', as: :boats_by_type
  get 'location', to: 'boats_for_sale#boats_by_location_index', as: :boats_by_location_index
  get 'location/:country', to: 'boats_for_sale#boats_by_location', as: :boats_by_location

  namespace :member, path: 'my-rightboat' do
    root to: 'dashboard#index'
    get 'favourites', to: 'favourites#index', as: :favourites
    post 'favourites', to: 'favourites#create', as: :favourite, constraints: { format: :json }
    controller :dashboard do
      get :enquiries
      get :subscriptions
      put :subscriptions, action: :update_subscriptions, constraints: { format: :json }
      get :search_histories
    end
  end
end
