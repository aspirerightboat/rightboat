Rails.application.routes.draw do
  devise_for :users, skip: [:sessions, :registrations], controllers: { passwords: 'passwords' }

  devise_scope :user do
    get 'sign-in', to: 'home#index', as: :new_user_session, defaults: { popup_login: true }
    post 'sign-in', to: 'sessions#create', as: :user_session
    delete 'sign-out', to: 'sessions#destroy', as: :destroy_user_session
    post 'sign-up', to: 'registrations#create', as: :user_registration
    put 'my-details', to: 'registrations#update', as: :user_profile
    get 'confirm-email', to: 'registrations#confirm_email', as: :confirm_email
    post 'resend-confirmation', to: 'registrations#resend_confirmation', as: :resend_confirmation
  end

  if Rails.env.production?
    match '/admin(*any)', to: redirect { |path_params, req| "http://import.rightboat.com#{req.fullpath}" },
          via: :all, constraints: { subdomain: /\A(?!import)/ }
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

  # put 'session-settings', to: 'session_settings#change', constraints: { format: :json }

  get 'news(/category/:category_id)', to: 'articles#index', as: :articles
  resources :articles, only: [:show], path: :news
  resources :buyer_guides, only: [:index, :show]
  # resources :feedbacks, only: [:create]
  # resources :mail_subscriptions, only: [:create]
  # resources :marine_enquiries, only: [:create]
  resources :berth_enquiries, only: [:create]
  resources :insurances, only: [:create]
  resources :finances, only: [:create]

  get 'search', to: 'search#results'
  post 'boats/:boat_id/request-details', to: 'enquiries#create'
  # get 'captcha', to: 'captcha#image'
  # get 'captcha/new', to: 'captcha#new'

  resource :home, controller: :home, path: '/' do
    collection do
      get :contact
      get :toc
      # get :marine_services
      get :privacy_policy
      get :cookies_policy
      get :sell_my_boats
      get :confirm_email
    end
  end

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

  resource :broker_area, controller: :broker_area, path: 'broker-area', only: [:show] do
    get :getting_started
    get :details
    post :update_details
    post :change_password
    get :preferences
    post :update_preferences
    get :charges
    get :messages
    get :boats_overview
    get :my_boats
    get :boats_manager
    get :my_leads
    get :tc
  end
  resource :register_broker, controller: :register_broker, path: 'register-broker', only: [:show, :create]

  namespace :member, path: 'my-rightboat' do
    root to: 'dashboard#index'
    get :about_me, to: 'dashboard#about_me'
    get 'favourites', to: 'favourites#index', as: :favourites
    post 'favourites', to: 'favourites#create', as: :favourite, constraints: { format: :json }
    resource :user_alert, controller: :user_alert, path: 'alerts', only: [:show, :update]
    resources :saved_searches, path: 'saved-searches', only: [:index, :create, :destroy] do
      post :toggle, on: :member
    end
    resources :boats, except: [:show]
    resources :enquiries, only: [:index, :destroy] do
      post :unhide, on: :collection
    end
    controller :dashboard do
      get :search_histories
    end
  end

  # old site redirects
  get '/all/boats-for-sale/:name', to: redirect('/manufacturer/%{name}')
  get '/about', to: redirect('/#about')
  get '/privacy-policy', to: redirect('/privacy_policy')
  get '/terms-of-use', to: redirect('/toc')
  get '/code-of-conduct', to: redirect('/#about')
  get '/trade-membership', to: redirect('/')
  get '/sell-my-boat', to: redirect('/sell_my_boats')
  get '/marine-directory/*other', to: redirect('/')
  get '/articles/*other', to: redirect('/')
end
