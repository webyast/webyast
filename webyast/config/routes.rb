Webyast::Application.routes.draw do
  resource :session
  resources :notifier
  resources :onlinehelp
  resources :logs
  resource :permissions
  resource :vendor_settings

  root :to => 'controlpanel#index'
  root :to => 'session#new'

  match 'resources/:id.:format' => 'resources#show', :constraints => { :id => /[-\w]+/ }
  match 'resources.:format' => 'resources#index'
  match '/validate_uri' => 'hosts#validate_uri'
  match '/' => 'main#index'
  match '/login.html' => 'sessions#new', :as => :login
  match '/login.:format' => 'sessions#create', :as => :login
  match '/logout.:format' => 'sessions#destroy', :as => :logout
  match '/restdoc.:format' => 'restdoc#index', :as => :restdoc
  match '/notifiers/status.:format' => 'notifier#status', :as => :notifier
  match '/:controller(/:action(/:id))'
end

