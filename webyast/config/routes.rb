Webyast::Application.routes.draw do

  devise_for :accounts,  :controllers => { :sessions => "sessions" }
  devise_scope :account do
    get "sign_in", :to => "devise/sessions#new"
    get "sign_out", :to => "devise/sessions#destroy"
  end

  devise_for :accounts, :controllers => { :sessions => "sessions" }

  devise_scope :account do
    get "sign_in", :to => "sessions#new"
    get "sign_out", :to => "sessions#destroy"
    match "sign_in" => "sessions#new"
    match "sign_out" => "sessions#destroy"
  end

  resources :notifier
  resources :onlinehelp
  resources :logs
  resource :vendor_settings

  #mounting each plugin
  if defined? WebYaST
    webyast_module = Object.const_get("WebYaST")
    webyast_plugins = webyast_module.constants
    webyast_plugins.each do |plugin|
      mount webyast_module.const_get(plugin) => '/'
    end
  end

  root :to => 'controlpanel#index'

  match 'resources/:id.:format' => 'resources#show', :constraints => { :id => /[-\w]+/ }
  match 'resources.:format' => 'resources#index'
  match '/validate_uri' => 'hosts#validate_uri'
  match '/' => 'main#index'
  match '/restdoc.:format' => 'restdoc#index', :as => :restdoc
  match '/notifiers/status.:format' => 'notifier#status', :as => :notifier
  match '/:controller(/:action(/:id))'
end
