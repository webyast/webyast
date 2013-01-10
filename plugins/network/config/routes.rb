WebYaST::NetworkEngine.routes.draw do
  match "/network/iface" => "network#iface", :as => :ajax
  match "/network/partial" => "network#partial", :as => :partial

  namespace :network do
    resources :interfaces, :only => [:index, :show, :update, :create, :destroy]
    resource :hostname, :controller => :hostname, :only => [:create, :show, :update]
    resource :dns, :controller => :dns, :only => [:create, :show, :update]
    resources :routes, :only => [:index, :show, :update]
  end
end
