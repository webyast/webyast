# route sessions statically, it is a singleton controller
ActionController::Routing::Routes.draw do |map|
  map.resource :session
  map.resources :resources, :requirements => { :id => /[-\w]+/ }
  map.resources :permissions, :requirements => {:id => /.*/}
  map.resources :vendor_settings
  
  # login uses POST for both
  map.login "/login.:format", :controller => 'sessions', :action => 'create'
  map.logout "/logout.:format", :controller => 'sessions', :action => 'destroy'
end
