require "lib/resource_registration"
  
# routing is generated from the 'resources' database table
# see config/initializers/resource_registration.rb for populating the database

# Don't route outside full Rails (e.g. when just running db:migrate)
ResourceRegistration.route_all

# route sessions statically, it is a singleton controller
ActionController::Routing::Routes.draw do |map|
  map.resource :session
  map.resource :check_permission
  # login uses POST for both
  map.login "/login.:format", :controller => 'sessions', :action => 'create'
  map.logout "/logout.:format", :controller => 'sessions', :action => 'destroy'
end
