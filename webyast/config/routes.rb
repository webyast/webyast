Webyast::Application.routes.draw do
  
  devise_for :accounts
  resources :notifier
  resources :onlinehelp
  resources :logs
  resource :permissions
  resource :vendor_settings

  mount WebYaST::UsersEngine => '/'
  mount WebYaST::ServicesEngine => '/'
  mount WebYaST::StatusEngine => '/'
  mount WebYaST::AdministratorEngine => '/'

  root :to => 'controlpanel#index'

  match 'resources/:id.:format' => 'resources#show', :constraints => { :id => /[-\w]+/ }
  match 'resources.:format' => 'resources#index'
  match '/validate_uri' => 'hosts#validate_uri'
  match '/' => 'main#index'
  match '/restdoc.:format' => 'restdoc#index', :as => :restdoc
  match '/notifiers/status.:format' => 'notifier#status', :as => :notifier
  match '/:controller(/:action(/:id))'
end

