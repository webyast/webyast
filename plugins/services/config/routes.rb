ActionController::Routing::Routes.draw do |map|

  map.resource :config, :controller => 'config_ntp', :path_prefix => "/services/ntp"

  map.namespace :services do |service|
      service.resource :dummy
  end

  map.resources :services do |service|
     service.resources :commands
  end

end
