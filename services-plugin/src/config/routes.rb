ActionController::Routing::Routes.draw do |map|

  map.resource :config, :controller => 'config_ntp', :path_prefix => "/services/ntp"
  map.connect "/services/ntp/config/:id", :controller => 'config_ntp', :action => 'singlevalue'
  map.connect "/services/ntp/config/:id.xml", :controller => 'config_ntp', :action => 'singlevalue', :format =>'xml'
  map.connect "/services/ntp/config/:id.html", :controller => 'config_ntp', :action => 'singlevalue', :format =>'html'
  map.connect "/services/ntp/config/:id.json", :controller => 'config_ntp', :action => 'singlevalue', :format =>'json'

  map.namespace :services do |service|
      service.resource :dummy
  end

  map.resources :services do |service|
     service.resources :commands
  end

end
