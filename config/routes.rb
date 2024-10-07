require 'sidekiq/web'

Rails.application.routes.draw do
  get 'profile', to: 'users#index', as: :profile
  root 'home#index'
  get 'search', to: 'search#index', as: :search
  ActiveAdmin.routes(self)
  mount Sidekiq::Web => '/sidekiq'

  resources :shows, only: %i[index show] do
    get '/book-now', to: 'screenings#index'
    resources :feedbacks, only: %i[create update destroy edit]
    member do
      get :languages
    end
  end

  resources :screenings, only: [:index] do
    resources :bookings, only: %i[create new] do
      member do
        patch :cancel_booking
      end
    end
  end

  resources :theaters, only: %i[index show] do
    resources :feedbacks, only: %i[create update destroy edit]
  end

  namespace :admin do
    root 'screens#index'
    resources :screens do
      resources :screenings
    end
    post 'switch_theater', to: 'screens#switch_theater', as: :switch_theater
  end

  devise_for :users,
             path: 'auth',
             path_names: {
               sign_in: 'login',
               sign_out: 'logout',
               sign_up: 'signup'
             }

  # OPTIMIZE: add member actions with only: []
  get '/admin_requests', to: 'admin_requests#new'
  post '/admin_requests', to: 'admin_requests#create'
  get 'up' => 'rails/health#show', as: :rails_health_check
  match '*path', via: :all, to: 'application#not_found_method', constraints: lambda { |req|
    req.path.exclude? 'rails/active_storage'
  }
end
