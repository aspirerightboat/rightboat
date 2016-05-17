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

  match '/delayed_job' => DelayedJobWeb, anchor: false, via: [:get, :post]

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
  get 'news/newsletter-2015-12', to: 'home#welcome', as: :newsletter

  resource :search, controller: :search, only: [], constraints: {format: :json} do
    get :manufacturers
    get :models
  end

  # put 'session-settings', to: 'session_settings#change', constraints: { format: :json }

  get 'news(/category/:category_id)', to: 'articles#index', as: :articles
  resources :articles, only: [:show], path: :news
  resources :buyer_guides, only: [:index, :show]
  # resources :feedbacks, only: [:create]
  # resources :mail_subscriptions, only: [:create]
  # resources :marine_enquiries, only: [:create]

  resources :berth_enquiries, only: [:create] do
    collection { get :load_popup }
  end
  resources :insurances, only: [:create] do
    collection { get :load_popup }
  end
  resources :finances, only: [:create] do
    collection { get :load_popup }
  end

  resources :batch_upload_jobs, only: [:show]
  get 'search', to: 'search#results'
  post 'boats/request-batched-details', to: 'enquiries#create_batch', as: :request_batched_details
  post 'boats/:id/request-details', to: 'enquiries#create', as: :request_details
  post 'signup-and-view-pdf', to: 'enquiries#signup_and_view_pdf', as: :signup_and_view_pdf
  get 'enquiries/:id/stream_pdf', to: 'enquiries#stream_enquired_pdf', as: :stream_enquired_pdf

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

  get 'boats-for-sale', to: 'boats#index', as: :boats
  get 'boats-for-sale/:manufacturer', to: 'boats#manufacturer', as: :sale_manufacturer
  get 'boats-for-sale/:manufacturer/filter', to: 'boats#filter' #, as: :sale_filter
  get 'boats-for-sale/:manufacturer/:model', to: 'boats#model', as: :sale_model
  get 'boats-for-sale/:manufacturer/:model/:boat', to: 'boats#show', as: :sale_boat
  get 'boats-for-sale/:manufacturer/:model/:boat/pdf', to: 'boats#pdf', as: :sale_boat_pdf
  get 'manufacturers-by-letter/:letter', to: 'boats#manufacturers_by_letter', as: :manufacturers_by_letter

  get 'manufacturer', to: redirect('/boats-for-sale')
  get 'manufacturer/:manufacturer', to: redirect('/boats-for-sale/%{manufacturer}')
  get 'models-by-letter/:id', to: redirect('/boats-for-sale')
  resources :boat_types, path: 'boat-type', only: [:show]
  get 'boat-type', to: redirect('/boats-for-sale')
  resources :countries, path: 'boats-for-sale-in', only: [:show]
  get 'location', to: redirect('/boats-for-sale')
  get 'location/:id', to: redirect('/boats-for-sale-in/%{id}')

  get 'leads/:id', to: 'enquiries#show', as: :lead
  post 'leads/:id/approve', to: 'enquiries#approve', as: :lead_approve
  post 'leads/:id/quality_check', to: 'enquiries#quality_check', as: :quality_check

  resource :testing, controller: :testing, only: [], path: '' do
    get :test_gmail
    get :test_amazon
    get :test_error
  end

  resource :welcome_broker, controller: :welcome_broker, path: 'welcome-broker', only: [:show]
  resource :register_broker, controller: :register_broker, path: 'register-broker', only: [:create]

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
    get :boats_manager
    get :my_leads
    get :tc
    get :account_history
  end
  namespace :broker_area, path: 'broker-area' do
    resources :my_boats, path: 'my-boats', only: [:index, :new]
  end

  namespace :member, path: 'my-rightboat' do
    root to: 'dashboard#index' # member_root_path
    get :about_me, to: 'dashboard#about_me'
    get :discounts, to: 'dashboard#discounts'
    get 'favourites', to: 'favourites#index', as: :favourites
    post 'favourites', to: 'favourites#create', as: :favourite, constraints: { format: :json }
    resource :user_alert, controller: :user_alert, path: 'alerts', only: [:update]
    resources :user_notifications, only: [:index]
    resources :saved_searches, path: 'saved-searches', only: [:edit, :update, :create, :destroy]
    resources :boats, except: [:show]
    resources :enquiries, only: [:index, :destroy] do
      post :unhide, on: :collection
    end
    controller :dashboard do
      get :search_histories
    end
  end

  resources :email_trackings, only: [] do
    collection do
      get :saved_search_opened
    end
  end

  # old site redirects
  get '/all/boats-for-sale/:name', to: redirect('/manufacturer/%{name}')
  get '/all/boats-for-sale/*other', to: redirect('/')
  get '/about', to: redirect('/#about')
  get '/privacy-policy', to: redirect('/privacy_policy')
  get '/terms-of-use', to: redirect('/toc')
  get '/code-of-conduct', to: redirect('/#about')
  get '/trade-membership', to: redirect('/')
  get '/sell-my-boat', to: redirect('/sell_my_boats')
  get '/marine-directory/*other', to: redirect('/')
  get '/articles/*other', to: redirect('/')
  get '/countries/:other', to: redirect('/location/%{other}')
  get '/countries', to: redirect('/location')
  get '/rightboat-terms-of-use.php', to: redirect('/broker-area/tc')
  get '/boats-for-sale/boat-classes/fishing', to: redirect('/boat-type/Fishing%20Boats')
  get '/boats-for-sale/boat-classes/power-cruiser', to: redirect('/boat-type/Power')
  get '/boats-for-sale/boat-classes/sport', to: redirect('/boat-type/Power')
  get '/boats-for-sale/boat-classes/rib', to: redirect('/boat-type/RIB')
  get '/boats-for-sale/boat-classes/sailing', to: redirect('/boat-type/Sail')
  get '/boats-for-sale/boat-classes/:kind', to: redirect('/boat-type/:kind')
  get '/reduced-boats', to: redirect('/')
  get '/featured', to: redirect('/')
  get '/manufacturers', to: redirect('/manufacturer')
  get '/dealers', to: redirect('/')
  get '/boats-for-sale/countries/:name', to: redirect('/location/:name')
  get '/marine-directory', to: redirect('/')
  get '/find_berths/*other', to: redirect('/')
  get '/marine-directory/*other', to: redirect('/')
  get '/training', to: redirect('/')

end
